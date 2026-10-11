import 'dart:async';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'note_sync_test.dart' show FakeNotesServer;

/// Chantier 12 (C) : la liste des fiches ne recharge que les blocs des fiches
/// dont la révision a bougé.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  NoteBlock block(String noteId, int position, String content) => NoteBlock(
        id: '$noteId-b$position',
        noteId: noteId,
        type: NoteBlockType.paragraph,
        content: content,
        position: position,
      );

  Future<int> revisionOf(String id) async =>
      (await (db.select(db.localNotes)..where((t) => t.id.equals(id)))
              .getSingle())
          .revision;

  /// Suit la liste émise par `watchAll` et permet d'attendre un état.
  ({List<Note> Function() latest, Future<void> Function(bool Function(List<Note>)) until, StreamSubscription<List<Note>> sub})
      follow(LocalFirstNoteRepository repository) {
    var latest = <Note>[];
    final sub = repository.watchAll().listen((notes) => latest = notes);
    // Un prédicat qui échoue sur un état intermédiaire (liste encore vide…)
    // compte comme « pas encore ».
    bool holds(bool Function(List<Note>) predicate) {
      try {
        return predicate(latest);
      } catch (_) {
        return false;
      }
    }

    Future<void> until(bool Function(List<Note>) predicate) async {
      for (var i = 0; i < 200 && !holds(predicate); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(holds(predicate), isTrue, reason: 'état attendu jamais atteint');
    }

    return (latest: () => latest, until: until, sub: sub);
  }

  group('triggers de révision', () {
    test('toute écriture de bloc fait monter la révision de sa fiche', () async {
      final now = DateTime.now();
      await db.into(db.localNotes).insert(LocalNotesCompanion.insert(
          id: 'n1', userId: 'u1', title: 'A', createdAt: now, updatedAt: now));
      expect(await revisionOf('n1'), 0);

      await db.into(db.localNoteBlocks).insert(LocalNoteBlocksCompanion.insert(
          id: 'b1', noteId: 'n1', type: 'paragraph', position: 0));
      expect(await revisionOf('n1'), 1);

      await (db.update(db.localNoteBlocks)..where((t) => t.id.equals('b1')))
          .write(const LocalNoteBlocksCompanion(content: Value('modifié')));
      expect(await revisionOf('n1'), 2);

      await (db.delete(db.localNoteBlocks)..where((t) => t.id.equals('b1')))
          .go();
      expect(await revisionOf('n1'), 3);
    });

    test('réécrire la fiche (upsert sans revision) ne remet pas le compteur '
        'à zéro', () async {
      final now = DateTime.now();
      final note = LocalNotesCompanion.insert(
          id: 'n1', userId: 'u1', title: 'A', createdAt: now, updatedAt: now);
      await db.into(db.localNotes).insert(note);
      await db.into(db.localNoteBlocks).insert(LocalNoteBlocksCompanion.insert(
          id: 'b1', noteId: 'n1', type: 'paragraph', position: 0));

      await db.into(db.localNotes).insertOnConflictUpdate(
          note.copyWith(title: const Value('B')));

      expect(await revisionOf('n1'), 1);
    });
  });

  group('liste des fiches (hors ligne)', () {
    late SupabaseClient client;
    late LocalFirstNoteRepository repository;

    setUp(() {
      client = SupabaseClient('http://offline.invalid', 'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      repository = LocalFirstNoteRepository(
          database: db, client: client, userId: 'u1');
    });

    tearDown(() async {
      await repository.sync().catchError((_) {});
      await client.dispose();
    });

    Future<Note> seed(String title, int blocks) async {
      final note = await repository.create(title: title);
      await repository.save(note.copyWith(
          blocks: [for (var i = 0; i < blocks; i++) block(note.id, i, '$title $i')]));
      return note;
    }

    test('(a) après une sauvegarde, seuls les blocs de cette fiche sont '
        'rechargés', () async {
      final a = await seed('A', 4);
      final b = await seed('B', 4);
      await seed('C', 4);

      final list = follow(repository);
      addTearDown(list.sub.cancel);
      await list.until((notes) => notes.length == 3);
      final before = repository.blocksLoaded;
      expect(before, 12);

      final current = list.latest().firstWhere((n) => n.id == b.id);
      await repository.save(current.copyWith(blocks: [
        ...current.blocks.take(3),
        block(b.id, 3, 'B modifiée'),
      ]));

      await list.until((notes) => notes
          .firstWhere((n) => n.id == b.id)
          .blocks
          .any((x) => x.content == 'B modifiée'));
      expect(repository.blocksLoaded - before, 4,
          reason: 'seuls les 4 blocs de B doivent être relus');
      expect(
          list.latest().firstWhere((n) => n.id == a.id).blocks.map((x) => x.content),
          ['A 0', 'A 1', 'A 2', 'A 3']);
    });

    test('une écriture de bloc seule (sans toucher la fiche) met la liste à '
        'jour', () async {
      final a = await seed('A', 1);
      final list = follow(repository);
      addTearDown(list.sub.cancel);
      await list.until((notes) => notes.length == 1);

      // Écriture directe : seule la règle de propagation générée par Drift
      // pour le trigger peut réveiller la liste.
      await db.into(db.localNoteBlocks).insert(LocalNoteBlocksCompanion.insert(
          id: 'direct', noteId: a.id, type: 'paragraph',
          content: const Value('ajouté'), position: 1));

      await list.until(
          (notes) => notes.single.blocks.any((x) => x.content == 'ajouté'));
    });

    test('(c) une fiche supprimée sort du cache', () async {
      final a = await seed('A', 2);
      await seed('B', 2);
      final list = follow(repository);
      addTearDown(list.sub.cancel);
      await list.until((notes) => notes.length == 2);
      expect(repository.cachedNoteIds, contains(a.id));

      await repository.delete(a.id);

      await list.until((notes) => notes.length == 1);
      expect(repository.cachedNoteIds, isNot(contains(a.id)));
    });
  });

  group('synchronisation', () {
    late FakeNotesServer server;
    late SupabaseClient client;
    late LocalFirstNoteRepository repository;

    setUp(() {
      server = FakeNotesServer();
      client = SupabaseClient('http://fake.local', 'anon-key',
          httpClient: server.client,
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      repository = LocalFirstNoteRepository(
          database: db, client: client, userId: 'u1');
    });

    tearDown(() async {
      await repository.sync().catchError((_) {});
      await client.dispose();
    });

    test('(b) un pull qui modifie une fiche met la liste à jour', () async {
      final note = await repository.create(title: 'A');
      await repository.save(note.copyWith(blocks: [block(note.id, 0, 'local')]));
      await repository.sync();

      final list = follow(repository);
      addTearDown(list.sub.cancel);
      await list.until((notes) => notes.single.blocks.single.content == 'local');

      // Modifiée depuis un autre appareil : nouveaux blocs, updated_at plus
      // récent (au-delà de la marge du pull incrémental).
      server.now = server.now.add(const Duration(hours: 1));
      server.notes[note.id] = {
        ...server.notes[note.id]!,
        'updated_at': server.now.toIso8601String(),
      };
      server.blocks
        ..removeWhere((x) => x['note_id'] == note.id)
        ..add({
          'id': '${note.id}-distant',
          'note_id': note.id,
          'type': 'paragraph',
          'content': 'distant',
          'is_checked': false,
          'position': 0,
        });
      await repository.sync();

      await list.until(
          (notes) => notes.single.blocks.single.content == 'distant');
    });

    test('(d) revision n\'est jamais envoyé à Supabase', () async {
      final note = await repository.create(title: 'A');
      await repository.save(note.copyWith(blocks: [block(note.id, 0, 'x')]));
      await repository.sync();
      expect(await revisionOf(note.id), greaterThan(0));

      expect(server.upsertBodies, isNotEmpty);
      for (final body in server.upsertBodies) {
        expect(body.containsKey('revision'), isFalse);
      }
      for (final row in server.blocks) {
        expect(row.containsKey('revision'), isFalse);
      }
    });
  });
}
