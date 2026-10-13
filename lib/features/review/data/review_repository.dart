import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/incremental_pull.dart';
import '../../../core/database/sync_queue.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/note_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_repository.dart';
import '../domain/spaced_repetition.dart';

abstract interface class ReviewRepository {
  Stream<List<Flashcard>> watchCards();
  Stream<List<Explanation>> watchExplanations();

  Future<Flashcard> createCard({
    required String front,
    required String back,
    String? noteId,
    String? deck,
  });

  Future<void> saveCard(Flashcard card);
  Future<void> deleteCard(String id);

  /// Enregistre un jugement et replanifie la carte.
  Future<Flashcard> grade(Flashcard card, ReviewGrade grade);

  /// Nombre de cartes jugées aujourd'hui, toutes cartes confondues.
  Future<int> reviewedTodayCount();

  Future<void> saveExplanation(Explanation explanation);

  Future<Sq3rSession> sessionForNote(String noteId);
  Future<void> saveSession(Sq3rSession session);

  Future<void> sync();
}

/// Même patron local-first que les Lots 4 et 5.
class LocalFirstReviewRepository implements ReviewRepository {
  LocalFirstReviewRepository({
    required AppDatabase database,
    required SupabaseClient client,
    required String userId,
    bool syncEnabled = true,
  })  : _db = database,
        _client = client,
        _userId = userId,
        _syncEnabled = syncEnabled;

  final AppDatabase _db;
  final SupabaseClient _client;
  final String _userId;

  /// `false` sans vraie session (mode `DEV_BYPASS_AUTH`) : tout reste local,
  /// aucune requête ne part avec l'utilisateur fictif.
  final bool _syncEnabled;

  static const String _cardsTable = 'flashcards';
  static const String _explanationsTable = 'explanations';
  static const String _sessionsTable = 'sq3r_sessions';

  // ── Lecture ──────────────────────────────────────────────────────────────

  @override
  Stream<List<Flashcard>> watchCards() {
    final query = _db.select(_db.localFlashcards)
      ..where((t) => t.userId.equals(_userId) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]);

    return query.watch().map((rows) => rows.map(_toCard).toList());
  }

  @override
  Stream<List<Explanation>> watchExplanations() {
    final query = _db.select(_db.localExplanations)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows
        .map((row) => Explanation(
              id: row.id,
              userId: row.userId,
              noteId: row.noteId,
              content: row.content,
              confidence: row.confidence,
              createdAt: row.createdAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  // ── Cartes ───────────────────────────────────────────────────────────────

  @override
  Future<Flashcard> createCard({
    required String front,
    required String back,
    String? noteId,
    String? deck,
  }) async {
    final card = Flashcard(
      id: LocalFirstNoteRepository.newId(),
      userId: _userId,
      noteId: noteId,
      front: front.trim(),
      back: back.trim(),
      deck: deck,
      createdAt: DateTime.now(),
      schedule: SpacedRepetition.initial(),
      isSynced: false,
    );

    await saveCard(card);
    return card;
  }

  @override
  Future<void> saveCard(Flashcard card) async {
    await _db.transaction(() async {
      await _db.into(_db.localFlashcards).insertOnConflictUpdate(
            LocalFlashcardsCompanion.insert(
              id: card.id,
              userId: _userId,
              noteId: Value(card.noteId),
              front: card.front,
              back: card.back,
              deck: Value(card.deck),
              step: Value(card.schedule.step),
              easeFactor: Value(card.schedule.easeFactor),
              dueAt: card.schedule.dueAt,
              lastReviewedAt:
                  Value(card.schedule.repetitions == 0 ? null : DateTime.now()),
              repetitions: Value(card.schedule.repetitions),
              lapses: Value(card.schedule.lapses),
              createdAt: card.createdAt,
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_cardsTable, card.id, 'upsert');
    });

    _syncQuietly();
  }

  @override
  Future<void> deleteCard(String id) async {
    await _db.transaction(() async {
      await (_db.update(_db.localFlashcards)..where((t) => t.id.equals(id)))
          .write(const LocalFlashcardsCompanion(
        isDeleted: Value(true),
        isSynced: Value(false),
      ));
      await _enqueue(_cardsTable, id, 'delete');
    });

    _syncQuietly();
  }

  @override
  Future<Flashcard> grade(Flashcard card, ReviewGrade grade) async {
    final schedule = SpacedRepetition.next(card.schedule, grade);
    final updated = card.copyWith(schedule: schedule, isSynced: false);

    await _db.transaction(() async {
      await (_db.update(_db.localFlashcards)
            ..where((t) => t.id.equals(card.id)))
          .write(LocalFlashcardsCompanion(
        step: Value(schedule.step),
        easeFactor: Value(schedule.easeFactor),
        dueAt: Value(schedule.dueAt),
        lastReviewedAt: Value(DateTime.now()),
        repetitions: Value(schedule.repetitions),
        lapses: Value(schedule.lapses),
        isSynced: const Value(false),
      ));

      // L'historique alimente les statistiques de progression ; il reste local
      // (non synchronisé) pour ne pas gonfler le trafic à chaque carte jugée.
      await _db.into(_db.localReviewLogs).insert(
            LocalReviewLogsCompanion.insert(
              id: LocalFirstNoteRepository.newId(),
              userId: _userId,
              cardId: card.id,
              grade: grade.value,
              intervalDays: schedule.intervalDays,
              reviewedAt: DateTime.now(),
            ),
          );

      await _enqueue(_cardsTable, card.id, 'upsert');
    });

    _syncQuietly();
    return updated;
  }

  @override
  Future<int> reviewedTodayCount() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final rows = await (_db.select(_db.localReviewLogs)
          ..where((t) =>
              t.userId.equals(_userId) &
              t.reviewedAt.isBiggerOrEqualValue(startOfToday)))
        .get();

    // Une carte vue trois fois dans la session ne compte qu'une fois : le
    // chiffre annoncé est « combien de cartes travaillées », pas « combien de
    // clics ».
    return rows.map((r) => r.cardId).toSet().length;
  }

  // ── Auto-explications ────────────────────────────────────────────────────

  @override
  Future<void> saveExplanation(Explanation explanation) async {
    await _db.transaction(() async {
      await _db.into(_db.localExplanations).insertOnConflictUpdate(
            LocalExplanationsCompanion.insert(
              id: explanation.id,
              userId: _userId,
              noteId: explanation.noteId,
              content: explanation.content,
              confidence: Value(explanation.confidence),
              createdAt: explanation.createdAt,
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_explanationsTable, explanation.id, 'upsert');
    });

    _syncQuietly();
  }

  // ── SQ3R ─────────────────────────────────────────────────────────────────

  @override
  Future<Sq3rSession> sessionForNote(String noteId) async {
    final existing = await (_db.select(_db.localSq3rSessions)
          ..where((t) => t.noteId.equals(noteId)))
        .getSingleOrNull();

    if (existing != null) return _toSession(existing);

    final now = DateTime.now();
    final session = Sq3rSession(
      id: LocalFirstNoteRepository.newId(),
      userId: _userId,
      noteId: noteId,
      currentStep: Sq3rStep.survey,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    await saveSession(session);
    return session;
  }

  @override
  Future<void> saveSession(Sq3rSession session) async {
    await _db.transaction(() async {
      await _db.into(_db.localSq3rSessions).insertOnConflictUpdate(
            LocalSq3rSessionsCompanion.insert(
              id: session.id,
              userId: _userId,
              noteId: session.noteId,
              currentStep: Value(session.currentStep.index),
              surveyNotes: Value(session.surveyNotes),
              questions: Value(jsonEncode(session.questions)),
              reciteNotes: Value(session.reciteNotes),
              reviewNotes: Value(session.reviewNotes),
              createdAt: session.createdAt,
              updatedAt: DateTime.now(),
              completedAt: Value(session.completedAt),
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_sessionsTable, session.id, 'upsert');
    });

    _syncQuietly();
  }

  // ── Synchronisation ──────────────────────────────────────────────────────

  Future<void> _enqueue(String table, String entityId, String operation) async {
    await (_db.delete(_db.syncQueueEntries)
          ..where(
              (t) => t.entityTable.equals(table) & t.entityId.equals(entityId)))
        .go();

    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityTable: table,
            entityId: entityId,
            operation: operation,
            queuedAt: DateTime.now(),
          ),
        );
  }

  void _syncQuietly() {
    sync().catchError((_) {});
  }

  @override
  Future<void> sync() async {
    if (!_syncEnabled) return;
    await _pushCards();
    await _pushExplanations();
    await _pushSessions();
    await _pullRemote();
  }

  Future<void> _pushCards() async {
    for (final entry in await _pending(_cardsTable)) {
      if (entry.operation == 'delete') {
        await _client.from(_cardsTable).delete().eq('id', entry.entityId);
        await (_db.delete(_db.localFlashcards)
              ..where((t) => t.id.equals(entry.entityId)))
            .go();
      } else {
        final row = await (_db.select(_db.localFlashcards)
              ..where((t) => t.id.equals(entry.entityId)))
            .getSingleOrNull();
        if (row != null) {
          await _client.from(_cardsTable).upsert(_toCard(row).toJson());
          await (_db.update(_db.localFlashcards)
                ..where((t) => t.id.equals(row.id)))
              .write(const LocalFlashcardsCompanion(isSynced: Value(true)));
        }
      }
      await _dequeue(entry.id);
    }
  }

  Future<void> _pushExplanations() async {
    for (final entry in await _pending(_explanationsTable)) {
      final row = await (_db.select(_db.localExplanations)
            ..where((t) => t.id.equals(entry.entityId)))
          .getSingleOrNull();
      if (row != null) {
        await _client.from(_explanationsTable).upsert({
          'id': row.id,
          'user_id': row.userId,
          'note_id': row.noteId,
          'content': row.content,
          'confidence': row.confidence,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });
        await (_db.update(_db.localExplanations)
              ..where((t) => t.id.equals(row.id)))
            .write(const LocalExplanationsCompanion(isSynced: Value(true)));
      }
      await _dequeue(entry.id);
    }
  }

  Future<void> _pushSessions() async {
    for (final entry in await _pending(_sessionsTable)) {
      final row = await (_db.select(_db.localSq3rSessions)
            ..where((t) => t.id.equals(entry.entityId)))
          .getSingleOrNull();
      if (row != null) {
        await _client.from(_sessionsTable).upsert({
          'id': row.id,
          'user_id': row.userId,
          'note_id': row.noteId,
          'current_step': row.currentStep,
          'survey_notes': row.surveyNotes,
          'questions': jsonDecode(row.questions),
          'recite_notes': row.reciteNotes,
          'review_notes': row.reviewNotes,
          'created_at': row.createdAt.toUtc().toIso8601String(),
          'completed_at': row.completedAt?.toUtc().toIso8601String(),
        });
        await (_db.update(_db.localSq3rSessions)
              ..where((t) => t.id.equals(row.id)))
            .write(const LocalSq3rSessionsCompanion(isSynced: Value(true)));
      }
      await _dequeue(entry.id);
    }
  }

  Future<List<SyncQueueEntry>> _pending(String table) =>
      (_db.select(_db.syncQueueEntries)
            ..where((t) => t.entityTable.equals(table))
            ..orderBy([(t) => OrderingTerm.asc(t.queuedAt)]))
          .get();

  Future<void> _dequeue(int id) =>
      (_db.delete(_db.syncQueueEntries)..where((t) => t.id.equals(id))).go();

  late final PullCursors _cursors = PullCursors(_db, _userId);

  Future<void> _pullRemote() async {
    final delta = await fetchDelta(
      rows: () => _client.from(_cardsTable).select().eq('user_id', _userId),
      ids: () => _client.from(_cardsTable).select('id').eq('user_id', _userId),
      since: await _cursors.read(_cardsTable),
    );
    // Pas de retour anticipé sur une liste vide : la purge plus bas doit
    // avoir lieu même si toutes les cartes ont été supprimées ailleurs.

    // Les cartes rattachées à une fiche absente localement gardent leur
    // contenu mais perdent le lien : la contrainte de clé étrangère les
    // rejetterait sinon.
    final knownNotes = (await (_db.select(_db.localNotes)
              ..where((t) => t.userId.equals(_userId)))
            .get())
        .map((n) => n.id)
        .toSet();

    await _db.transaction(() async {
      final pending = await SyncQueue(_db).pendingIds(_cardsTable);
      var detachedFromUnknownNote = false;

      for (final row in delta.changed) {
        final card = Flashcard.fromJson(row);
        if (pending.contains(card.id)) continue;
        final noteId = card.noteId != null && knownNotes.contains(card.noteId)
            ? card.noteId
            : null;
        if (card.noteId != null && noteId == null) {
          detachedFromUnknownNote = true;
        }

        final local = await (_db.select(_db.localFlashcards)
              ..where((t) => t.id.equals(card.id)))
            .getSingleOrNull();

        // Une carte modifiée localement et pas encore poussée n'est jamais
        // écrasée par la version distante.
        if (local != null && !local.isSynced) continue;

        await _db.into(_db.localFlashcards).insertOnConflictUpdate(
              LocalFlashcardsCompanion.insert(
                id: card.id,
                userId: _userId,
                noteId: Value(noteId),
                front: card.front,
                back: card.back,
                deck: Value(card.deck),
                step: Value(card.schedule.step),
                easeFactor: Value(card.schedule.easeFactor),
                dueAt: card.schedule.dueAt,
                repetitions: Value(card.schedule.repetitions),
                lapses: Value(card.schedule.lapses),
                createdAt: card.createdAt,
                isSynced: const Value(true),
              ),
            );
      }

      // Carte synchronisée absente du serveur : supprimée depuis un autre
      // appareil. Son historique local de révision part avec (cascade).
      await (_db.delete(_db.localFlashcards)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.isSynced.equals(true) &
                t.id.isNotIn(delta.remoteIds!) &
                t.id.isNotIn(pending)))
          .go();

      // Une carte détachée faute de fiche locale sera rattachée au prochain
      // pull, une fois la fiche arrivée : on n'avance pas le curseur.
      if (!detachedFromUnknownNote) {
        await _cursors.write(_cardsTable, delta.cursor);
      }
    });
  }

  // ── Conversions ──────────────────────────────────────────────────────────

  static Flashcard _toCard(LocalFlashcard row) => Flashcard(
        id: row.id,
        userId: row.userId,
        noteId: row.noteId,
        front: row.front,
        back: row.back,
        deck: row.deck,
        createdAt: row.createdAt,
        isSynced: row.isSynced,
        schedule: ScheduleState(
          step: row.step,
          easeFactor: row.easeFactor,
          dueAt: row.dueAt,
          repetitions: row.repetitions,
          lapses: row.lapses,
          intervalDays: 0,
        ),
      );

  static Sq3rSession _toSession(LocalSq3rSession row) => Sq3rSession(
        id: row.id,
        userId: row.userId,
        noteId: row.noteId,
        currentStep: Sq3rStep.fromIndex(row.currentStep),
        surveyNotes: row.surveyNotes,
        questions: Note.decodeTags(row.questions),
        reciteNotes: row.reciteNotes,
        reviewNotes: row.reviewNotes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        completedAt: row.completedAt,
        isSynced: row.isSynced,
      );
}

final reviewRepositoryProvider = Provider<ReviewRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  return LocalFirstReviewRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
    syncEnabled: ref.watch(currentUserProvider) != null,
  );
});
