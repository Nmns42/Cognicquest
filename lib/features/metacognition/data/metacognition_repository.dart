import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_queue.dart';
import '../../../shared/models/metacognition_model.dart';
import '../../../shared/models/note_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_repository.dart';
import '../domain/learning_profile.dart';

abstract interface class MetacognitionRepository {
  Stream<List<JournalEntry>> watchJournal();
  Stream<List<Reframe>> watchReframes();
  Stream<List<WhyChain>> watchWhyChains();
  Stream<List<ErrorLog>> watchErrors();
  Stream<LearningProfile> watchProfile();

  Future<void> saveJournalEntry(JournalEntry entry);
  Future<void> saveReframe(Reframe reframe);
  Future<void> saveWhyChain(WhyChain chain);
  Future<void> saveError(ErrorLog error);
  Future<void> saveProfile(LearningProfile profile);

  Future<void> sync();
}

class LocalFirstMetacognitionRepository implements MetacognitionRepository {
  LocalFirstMetacognitionRepository({
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

  late final SyncQueue _queue = SyncQueue(_db);

  static const String _journalTable = 'journal_entries';
  static const String _reframesTable = 'reframes';
  static const String _whyTable = 'why_chains';
  static const String _errorsTable = 'error_logs';
  static const String _profileTable = 'learning_profiles';

  // ── Lecture ──────────────────────────────────────────────────────────────

  @override
  Stream<List<JournalEntry>> watchJournal() {
    final query = _db.select(_db.localJournalEntries)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows
        .map((row) => JournalEntry(
              id: row.id,
              userId: row.userId,
              noteId: row.noteId,
              mood: row.mood,
              energy: row.energy,
              rpe: row.rpe,
              whatLearned: row.whatLearned,
              whatWorked: row.whatWorked,
              whatBlocked: row.whatBlocked,
              nextStep: row.nextStep,
              createdAt: row.createdAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  @override
  Stream<List<Reframe>> watchReframes() {
    final query = _db.select(_db.localReframes)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows
        .map((row) => Reframe(
              id: row.id,
              userId: row.userId,
              limitingThought: row.limitingThought,
              distortion: CognitiveDistortion.fromValue(row.distortion),
              evidenceAgainst: row.evidenceAgainst,
              reframedThought: row.reframedThought,
              growthGoal: row.growthGoal,
              createdAt: row.createdAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  @override
  Stream<List<WhyChain>> watchWhyChains() {
    final query = _db.select(_db.localWhyChains)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows
        .map((row) => WhyChain(
              id: row.id,
              userId: row.userId,
              problem: row.problem,
              answers: Note.decodeTags(row.answers),
              rootCause: row.rootCause,
              blockerType: BlockerType.fromValue(row.blockerType),
              actionPlan: row.actionPlan,
              createdAt: row.createdAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  @override
  Stream<List<ErrorLog>> watchErrors() {
    final query = _db.select(_db.localErrorLogs)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows
        .map((row) => ErrorLog(
              id: row.id,
              userId: row.userId,
              noteId: row.noteId,
              subject: row.subject,
              description: row.description,
              errorType: ErrorType.fromValue(row.errorType),
              correction: row.correction,
              createdAt: row.createdAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  @override
  Stream<LearningProfile> watchProfile() {
    final query = _db.select(_db.localLearningProfiles)
      ..where((t) => t.userId.equals(_userId));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return LearningProfile.empty;

      final decoded = jsonDecode(row.answers);
      final answers = decoded is Map
          ? decoded.map((k, v) => MapEntry(k.toString(), v.toString()))
          : <String, String>{};

      return LearningProfile(
        answers: answers,
        processingStyle: ProcessingStyle.fromValue(row.processingStyle),
        preferredChannel: PreferredChannel.fromValue(row.preferredChannel),
        completedAt: row.completedAt,
      );
    });
  }

  // ── Écriture ─────────────────────────────────────────────────────────────

  @override
  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _db.transaction(() async {
      await _db.into(_db.localJournalEntries).insertOnConflictUpdate(
            LocalJournalEntriesCompanion.insert(
              id: entry.id,
              userId: _userId,
              noteId: Value(entry.noteId),
              mood: Value(entry.mood),
              energy: Value(entry.energy),
              rpe: Value(entry.rpe),
              whatLearned: Value(entry.whatLearned),
              whatWorked: Value(entry.whatWorked),
              whatBlocked: Value(entry.whatBlocked),
              nextStep: Value(entry.nextStep),
              createdAt: entry.createdAt,
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_journalTable, entry.id);
    });
    _syncQuietly();
  }

  @override
  Future<void> saveReframe(Reframe reframe) async {
    await _db.transaction(() async {
      await _db.into(_db.localReframes).insertOnConflictUpdate(
            LocalReframesCompanion.insert(
              id: reframe.id,
              userId: _userId,
              limitingThought: reframe.limitingThought,
              distortion: Value(reframe.distortion?.value),
              evidenceAgainst: Value(reframe.evidenceAgainst),
              reframedThought: Value(reframe.reframedThought),
              growthGoal: Value(reframe.growthGoal),
              createdAt: reframe.createdAt,
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_reframesTable, reframe.id);
    });
    _syncQuietly();
  }

  @override
  Future<void> saveWhyChain(WhyChain chain) async {
    await _db.transaction(() async {
      await _db.into(_db.localWhyChains).insertOnConflictUpdate(
            LocalWhyChainsCompanion.insert(
              id: chain.id,
              userId: _userId,
              problem: chain.problem,
              answers: Value(jsonEncode(chain.answers)),
              rootCause: Value(chain.rootCause),
              blockerType: Value(chain.blockerType?.value),
              actionPlan: Value(chain.actionPlan),
              createdAt: chain.createdAt,
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_whyTable, chain.id);
    });
    _syncQuietly();
  }

  @override
  Future<void> saveError(ErrorLog error) async {
    await _db.transaction(() async {
      await _db.into(_db.localErrorLogs).insertOnConflictUpdate(
            LocalErrorLogsCompanion.insert(
              id: error.id,
              userId: _userId,
              noteId: Value(error.noteId),
              subject: Value(error.subject),
              description: error.description,
              errorType: error.errorType.value,
              correction: Value(error.correction),
              createdAt: error.createdAt,
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_errorsTable, error.id);
    });
    _syncQuietly();
  }

  @override
  Future<void> saveProfile(LearningProfile profile) async {
    await _db.transaction(() async {
      await _db.into(_db.localLearningProfiles).insertOnConflictUpdate(
            LocalLearningProfilesCompanion.insert(
              userId: _userId,
              answers: Value(jsonEncode(profile.answers)),
              processingStyle: Value(profile.processingStyle?.value),
              preferredChannel: Value(profile.preferredChannel?.value),
              completedAt: Value(profile.completedAt),
              updatedAt: DateTime.now(),
              isSynced: const Value(false),
            ),
          );
      // La clé primaire est l'utilisateur : une seule entrée en file.
      await _enqueue(_profileTable, _userId);
    });
    _syncQuietly();
  }

  Future<void> _enqueue(String table, String entityId) async {
    await (_db.delete(_db.syncQueueEntries)
          ..where(
              (t) => t.entityTable.equals(table) & t.entityId.equals(entityId)))
        .go();

    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityTable: table,
            entityId: entityId,
            operation: 'upsert',
            queuedAt: DateTime.now(),
          ),
        );
  }

  void _syncQuietly() {
    sync().catchError((_) {});
  }

  // ── Synchronisation ──────────────────────────────────────────────────────

  @override
  Future<void> sync() async {
    if (!_syncEnabled) return;
    await _pushJournal();
    await _pushReframes();
    await _pushWhyChains();
    await _pushErrors();
    await _pushProfile();
  }

  Future<void> _pushJournal() async {
    await _queue.drain(_journalTable, (entry) async {
      final row = await (_db.select(_db.localJournalEntries)
            ..where((t) => t.id.equals(entry.entityId)))
          .getSingleOrNull();
      if (row != null) {
        await _client.from(_journalTable).upsert({
          'id': row.id,
          'user_id': row.userId,
          'note_id': row.noteId,
          'mood': row.mood,
          'energy': row.energy,
          'rpe': row.rpe,
          'what_learned': row.whatLearned,
          'what_worked': row.whatWorked,
          'what_blocked': row.whatBlocked,
          'next_step': row.nextStep,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });
        await (_db.update(_db.localJournalEntries)
              ..where((t) => t.id.equals(row.id)))
            .write(const LocalJournalEntriesCompanion(isSynced: Value(true)));
      }
    });
  }

  Future<void> _pushReframes() async {
    await _queue.drain(_reframesTable, (entry) async {
      final row = await (_db.select(_db.localReframes)
            ..where((t) => t.id.equals(entry.entityId)))
          .getSingleOrNull();
      if (row != null) {
        await _client.from(_reframesTable).upsert({
          'id': row.id,
          'user_id': row.userId,
          'limiting_thought': row.limitingThought,
          'distortion': row.distortion,
          'evidence_against': row.evidenceAgainst,
          'reframed_thought': row.reframedThought,
          'growth_goal': row.growthGoal,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });
        await (_db.update(_db.localReframes)..where((t) => t.id.equals(row.id)))
            .write(const LocalReframesCompanion(isSynced: Value(true)));
      }
    });
  }

  Future<void> _pushWhyChains() async {
    await _queue.drain(_whyTable, (entry) async {
      final row = await (_db.select(_db.localWhyChains)
            ..where((t) => t.id.equals(entry.entityId)))
          .getSingleOrNull();
      if (row != null) {
        await _client.from(_whyTable).upsert({
          'id': row.id,
          'user_id': row.userId,
          'problem': row.problem,
          'answers': jsonDecode(row.answers),
          'root_cause': row.rootCause,
          'blocker_type': row.blockerType,
          'action_plan': row.actionPlan,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });
        await (_db.update(_db.localWhyChains)
              ..where((t) => t.id.equals(row.id)))
            .write(const LocalWhyChainsCompanion(isSynced: Value(true)));
      }
    });
  }

  Future<void> _pushErrors() async {
    await _queue.drain(_errorsTable, (entry) async {
      final row = await (_db.select(_db.localErrorLogs)
            ..where((t) => t.id.equals(entry.entityId)))
          .getSingleOrNull();
      if (row != null) {
        await _client.from(_errorsTable).upsert({
          'id': row.id,
          'user_id': row.userId,
          'note_id': row.noteId,
          'subject': row.subject,
          'description': row.description,
          'error_type': row.errorType,
          'correction': row.correction,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });
        await (_db.update(_db.localErrorLogs)
              ..where((t) => t.id.equals(row.id)))
            .write(const LocalErrorLogsCompanion(isSynced: Value(true)));
      }
    });
  }

  Future<void> _pushProfile() async {
    await _queue.drain(_profileTable, (entry) async {
      final row = await (_db.select(_db.localLearningProfiles)
            ..where((t) => t.userId.equals(entry.entityId)))
          .getSingleOrNull();
      if (row != null) {
        await _client.from(_profileTable).upsert({
          'user_id': row.userId,
          'answers': jsonDecode(row.answers),
          'processing_style': row.processingStyle,
          'preferred_channel': row.preferredChannel,
          'completed_at': row.completedAt?.toUtc().toIso8601String(),
        }, onConflict: 'user_id');
        await (_db.update(_db.localLearningProfiles)
              ..where((t) => t.userId.equals(row.userId)))
            .write(const LocalLearningProfilesCompanion(isSynced: Value(true)));
      }
    });
  }


}

final metacognitionRepositoryProvider =
    Provider<MetacognitionRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  return LocalFirstMetacognitionRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
    syncEnabled: ref.watch(currentUserProvider) != null,
  );
});

/// Identifiant client, réutilisé depuis le Lot 4.
String newMetacognitionId() => LocalFirstNoteRepository.newId();
