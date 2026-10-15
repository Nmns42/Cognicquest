import 'dart:async';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/database/sync_queue.dart';
import 'package:cognicquest/core/ordering/manual_order.dart';
import 'package:cognicquest/features/notes/data/folder_repository.dart';
import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Explorateur : dossiers et rangement des fiches et des cartes.
void main() {
  late AppDatabase db;
  late SupabaseClient client;
  late LocalFirstFolderRepository folders;
  late LocalFirstNoteRepository notes;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    client = SupabaseClient(
      'http://offline.invalid',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    folders = LocalFirstFolderRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);
    notes = LocalFirstNoteRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);
  });

  tearDown(() async {
    unawaited(client.dispose());
    await db.close();
  });

  Future<String?> folderOf(String noteId) async =>
      (await (db.select(db.localNotes)..where((t) => t.id.equals(noteId)))
              .getSingle())
          .folderId;

  test('crée des dossiers et des sous-dossiers, triés par nom', () async {
    final cours = await folders.create('  Cours  ');
    await folders.create('Annales');
    await folders.create('Cardio', parentId: cours.id);

    final all = await folders.watchAll().first;
    expect(all.map((f) => f.name), ['Annales', 'Cardio', 'Cours']);
    expect(all.firstWhere((f) => f.name == 'Cardio').parentId, cours.id);
  });

  test('ranger une fiche : enregistré et mis en file pour le serveur',
      () async {
    final dossier = await folders.create('Cours');
    final note = await notes.create(title: 'Insuffisance cardiaque');

    await folders.moveNote(note.id, dossier.id);

    expect(await folderOf(note.id), dossier.id);
    expect(await SyncQueue(db).pendingIds('notes'), contains(note.id));
    final reread = (await notes.watchAll().first)
        .firstWhere((n) => n.id == note.id);
    expect(reread.folderId, dossier.id);
  });

  test('supprimer un dossier : ses sous-dossiers partent, ses fiches '
      'reviennent à la racine', () async {
    final cours = await folders.create('Cours');
    final cardio = await folders.create('Cardio', parentId: cours.id);
    final note = await notes.create(title: 'ECG');
    await folders.moveNote(note.id, cardio.id);

    await folders.delete(cours.id);

    expect(await folders.watchAll().first, isEmpty);
    expect(await folderOf(note.id), isNull);
    // Une seule suppression envoyée : le serveur supprime les
    // sous-dossiers en cascade.
    final pending = await SyncQueue(db).pendingIds('folders');
    expect(pending, {cours.id});
  });

  test('un dossier ne peut pas aller sous son propre descendant', () async {
    final cours = await folders.create('Cours');
    final cardio = await folders.create('Cardio', parentId: cours.id);

    expect(await folders.move(cours.id, cardio.id), isFalse);
    expect(await folders.move(cardio.id, null), isTrue);
    final all = await folders.watchAll().first;
    expect(all.firstWhere((f) => f.id == cardio.id).parentId, isNull);
  });

  test('mode démo : aucune synchronisation', () async {
    await folders.create('Cours');
    await folders.sync(); // ne doit rien tenter (client hors ligne)
    expect(await SyncQueue(db).pendingCount(), 1);
  });

  test('ordre manuel des dossiers : la clé d’ordre passe avant le nom, '
      'et part au serveur', () async {
    final a = await folders.create('Annales');
    final b = await folders.create('Biologie');
    final c = await folders.create('Chimie');

    // « Chimie » glissé en tête, devant « Annales ».
    final updates = ManualOrder.planMove(
      [
        OrderedItem(a.id, null),
        OrderedItem(b.id, null),
        OrderedItem(c.id, null),
      ],
      c.id,
      0,
    );
    await folders.applyPositions(updates);

    final all = await folders.watchAll().first;
    expect(all.first.name, 'Chimie');
    expect(await SyncQueue(db).pendingIds('folders'), contains(c.id));
  });

  test('sous-arbre d’un dossier : lui et tous ses descendants', () async {
    final cours = await folders.create('Cours');
    final cardio = await folders.create('Cardio', parentId: cours.id);
    final ecg = await folders.create('ECG', parentId: cardio.id);
    await folders.create('Annales');

    expect(await folders.subtreeOf(cours.id), {cours.id, cardio.id, ecg.id});
  });
}
