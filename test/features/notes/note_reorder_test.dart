import 'dart:async';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/ordering/manual_order.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:cognicquest/features/notes/domain/note_search.dart';
import 'package:cognicquest/features/notes/providers/note_provider.dart';
import 'package:cognicquest/features/notes/views/notes_page.dart';
import 'package:cognicquest/features/settings/providers/settings_provider.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'note_sync_test.dart' show FakeNotesServer;

/// Ordre manuel des fiches (R1) : glisser-déposer synchronisé.
void main() {
  /// Un appareil : sa base locale et son dépôt, branchés sur [server].
  ({AppDatabase db, LocalFirstNoteRepository repo, SupabaseClient client})
      device(FakeNotesServer server) {
    final db = AppDatabase(NativeDatabase.memory());
    final client = SupabaseClient('http://fake.local', 'anon-key',
        httpClient: server.client,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    return (
      db: db,
      repo: LocalFirstNoteRepository(database: db, client: client, userId: 'u1'),
      client: client,
    );
  }

  Future<void> close(
      ({AppDatabase db, LocalFirstNoteRepository repo, SupabaseClient client})
          d) async {
    await d.repo.sync().catchError((_) {});
    await d.client.dispose();
    await d.db.close();
  }

  /// Liste « Manuel » telle que l'écran l'affiche.
  Future<List<String>> manualTitles(LocalFirstNoteRepository repo) async =>
      [for (final n in NoteSearch.manualOrder(await repo.watchAll().first)) n.title];

  /// Déplace [title] à [newIndex] de la liste « Manuel ».
  Future<void> move(
      LocalFirstNoteRepository repo, String title, int newIndex) async {
    final visible = NoteSearch.manualOrder(await repo.watchAll().first);
    final moved = visible.firstWhere((n) => n.title == title);
    await repo.applyPositions(ManualOrder.planMove(
      [for (final n in visible) OrderedItem(n.id, n.position)],
      moved.id,
      newIndex,
    ));
  }

  Future<List<String>> seed(LocalFirstNoteRepository repo, int count) async {
    final titles = <String>[];
    for (var i = 0; i < count; i++) {
      final note = await repo.create(title: 'F$i');
      titles.add(note.title);
    }
    await repo.sync();
    return titles;
  }

  test('(e) sans position, l\'ordre « Manuel » est l\'ordre actuel', () async {
    final server = FakeNotesServer();
    final a = device(server);
    addTearDown(() => close(a));
    await seed(a.repo, 4);

    final notes = await a.repo.watchAll().first;
    expect(notes.every((n) => n.position == null), isTrue);
    expect(NoteSearch.manualOrder(notes).map((n) => n.id),
        (notes.toList()..sort(NoteSearch.compareRecent)).map((n) => n.id));
  });

  test('(a) une fois les clés posées, un déplacement réécrit une seule '
      'ligne, et seulement sa position', () async {
    final server = FakeNotesServer();
    final a = device(server);
    addTearDown(() => close(a));
    await seed(a.repo, 5);
    await move(a.repo, 'F0', 0); // premier déplacement : initialisation
    await a.repo.sync();
    server.patchBodies.clear();
    server.upsertBodies.clear();

    final before = await manualTitles(a.repo);
    await move(a.repo, before.last, 1);
    await a.repo.sync();

    expect(server.patchBodies, hasLength(1));
    expect(server.patchBodies.single.keys, ['position']);
    expect(server.upsertBodies, isEmpty, reason: 'ni contenu ni blocs renvoyés');
    expect((await manualTitles(a.repo))[1], before.last);
  });

  test('(b) l\'ordre survit à un aller-retour push / pull', () async {
    final server = FakeNotesServer();
    final a = device(server);
    final b = device(server);
    addTearDown(() => close(a));
    addTearDown(() => close(b));
    await seed(a.repo, 5);
    await move(a.repo, 'F1', 0);
    await move(a.repo, 'F4', 2);
    await a.repo.sync();

    server.now = server.now.add(const Duration(hours: 1));
    await b.repo.sync();
    expect(await manualTitles(b.repo), await manualTitles(a.repo));
  });

  test('(c) deux appareils qui déplacent des fiches différentes ne '
      's\'écrasent pas', () async {
    final server = FakeNotesServer();
    final a = device(server);
    final b = device(server);
    addTearDown(() => close(a));
    addTearDown(() => close(b));
    await seed(a.repo, 6);
    await move(a.repo, 'F0', 0); // clés posées, partagées par les deux
    await a.repo.sync();
    server.now = server.now.add(const Duration(hours: 1));
    await b.repo.sync();

    // Chacun déplace une fiche différente, sans voir l'autre.
    final start = await manualTitles(a.repo);
    await move(a.repo, start[5], 0);
    await move(b.repo, start[1], 4);
    await a.repo.sync();
    await b.repo.sync();
    server.now = server.now.add(const Duration(hours: 1));
    await a.repo.sync();
    await b.repo.sync();

    final onA = await manualTitles(a.repo);
    expect(await manualTitles(b.repo), onA);
    expect(onA.first, start[5], reason: 'déplacement de A conservé');
    expect(onA.indexOf(start[1]), greaterThan(onA.indexOf(start[2])),
        reason: 'déplacement de B conservé');
  });

  group('(d) glisser-déposer', () {
    final now = DateTime(2026, 10, 1);
    final notes = [
      for (var i = 0; i < 3; i++)
        Note(
          id: 'n$i',
          userId: 'u1',
          title: 'Fiche $i',
          content: '',
          createdAt: now,
          updatedAt: now.add(Duration(minutes: i)),
        ),
    ];

    Future<ProviderContainer> pump(WidgetTester tester) async {
      final client = SupabaseClient('http://offline.invalid', 'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      addTearDown(() => unawaited(client.dispose()));
      final container = ProviderContainer(overrides: [
        supabaseClientProvider.overrideWithValue(client),
        notesProvider.overrideWith((ref) => Stream.value(notes)),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotesPage()),
      ));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('tri « Récentes » : pas de glisser-déposer', (tester) async {
      await pump(tester);
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('tri « Manuel » : glisser-déposer actif', (tester) async {
      final container = await pump(tester);
      container.read(settingsProvider.notifier).setManualNoteOrder(true);
      await tester.pumpAndSettle();
      expect(find.byType(ReorderableListView), findsOneWidget);
      await tester.pump(const Duration(seconds: 1)); // sauvegarde différée
    });

    testWidgets('tri « Manuel » + recherche ou filtre : désactivé',
        (tester) async {
      final container = await pump(tester);
      container.read(settingsProvider.notifier).setManualNoteOrder(true);
      final filter = container.read(noteFilterProvider.notifier);

      filter.setQuery('Fiche');
      await tester.pumpAndSettle();
      expect(find.byType(ReorderableListView), findsNothing);

      filter.setQuery('');
      filter.toggleFavoritesOnly();
      await tester.pumpAndSettle();
      expect(container.read(canReorderNotesProvider), isFalse);
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
