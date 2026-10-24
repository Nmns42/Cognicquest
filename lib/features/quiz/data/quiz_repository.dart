import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/incremental_pull.dart';
import '../../../core/database/sync_queue.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_repository.dart';
import '../domain/quiz_generator.dart';
import '../domain/quiz_loops.dart';

/// Historique des réponses aux quiz, local-first et synchronisé (journal en
/// ajout seul, même patron que `review_logs`).
class QuizRepository {
  QuizRepository({
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
  final bool _syncEnabled;

  static const String table = 'quiz_attempts';

  late final SyncQueue _queue = SyncQueue(_db);
  late final PullCursors _cursors = PullCursors(_db, _userId);
  late final SerialSync _serialSync = SerialSync(_syncOnce);

  Stream<List<QuizAttempt>> watchAll() {
    final query = _db.select(_db.localQuizAttempts)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.desc(t.answeredAt)]);
    return query.watch().map((rows) => [for (final r in rows) _toAttempt(r)]);
  }

  /// Enregistre une réponse.
  Future<void> record(QuizQuestion question, {required bool correct}) async {
    final id = LocalFirstNoteRepository.newId();
    await _db.transaction(() async {
      await _db.into(_db.localQuizAttempts).insert(
            LocalQuizAttemptsCompanion.insert(
              id: id,
              userId: _userId,
              questionId: question.id,
              kind: question.kind.name,
              correct: correct,
              answeredAt: DateTime.now(),
              noteId: Value(question.noteId),
              cardId: Value(question.cardId),
              heading: Value(question.heading),
            ),
          );
      await _queue.enqueue(table, id, 'upsert');
    });
    sync().catchError((_) {});
  }

  Future<void> sync() async {
    if (!_syncEnabled) return;
    await _serialSync();
  }

  Future<void> _syncOnce() async {
    await _queue.drain(table, (entry) async {
      final row = await (_db.select(_db.localQuizAttempts)
            ..where((t) => t.id.equals(entry.entityId)))
          .getSingleOrNull();
      if (row == null) return;
      if (row.userId != _userId) throw const SkipEntry();
      await _client.from(table).upsert({
        'id': row.id,
        'user_id': row.userId,
        'question_id': row.questionId,
        'kind': row.kind,
        'correct': row.correct,
        'answered_at': row.answeredAt.toUtc().toIso8601String(),
        'note_id': row.noteId,
        'card_id': row.cardId,
        'heading': row.heading,
      });
    });

    final delta = await fetchDelta(
      rows: () => _client.from(table).select().eq('user_id', _userId),
      since: await _cursors.read(table),
    );
    await _db.transaction(() async {
      for (final row in delta.changed) {
        await _db.into(_db.localQuizAttempts).insert(
              LocalQuizAttemptsCompanion.insert(
                id: row['id'] as String,
                userId: _userId,
                questionId: row['question_id'] as String,
                kind: row['kind'] as String,
                correct: row['correct'] as bool,
                answeredAt: DateTime.parse(row['answered_at'] as String),
                noteId: Value(row['note_id'] as String?),
                cardId: Value(row['card_id'] as String?),
                heading: Value(row['heading'] as String?),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      await _cursors.write(table, delta.cursor);
    });
  }

  static QuizAttempt _toAttempt(LocalQuizAttempt row) => QuizAttempt(
        id: row.id,
        questionId: row.questionId,
        kind: QuizKind.values.firstWhere((k) => k.name == row.kind,
            orElse: () => QuizKind.card),
        correct: row.correct,
        answeredAt: row.answeredAt,
        noteId: row.noteId,
        cardId: row.cardId,
        heading: row.heading,
      );
}

final quizRepositoryProvider = Provider<QuizRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return QuizRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
    syncEnabled: ref.watch(currentUserProvider) != null,
  );
});
