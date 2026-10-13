import 'dart:async';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/dev/demo_seed.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bouton « Charger les données de démo » : un compte réel (ici simulé)
/// reçoit un jeu complet, une seule fois.
void main() {
  late AppDatabase db;
  late SupabaseClient client;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    client = SupabaseClient(
      'http://offline.invalid',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseClientProvider.overrideWithValue(client),
      // Un compte connecté (sans réseau : rien ne part au serveur).
      currentUserIdProvider.overrideWithValue('compte-reel'),
    ]);
  });

  tearDown(() async {
    container.dispose();
    unawaited(client.dispose());
    await db.close();
  });

  test('charge un jeu complet dans le compte connecté, une seule fois',
      () async {
    expect(await loadDemoData(container.read), DemoLoadResult.loaded);

    final notes = await (db.select(db.localNotes)
          ..where((t) => t.userId.equals('compte-reel')))
        .get();
    expect(notes.length, greaterThanOrEqualTo(8));
    expect(notes.any((n) => n.title == demoMarkerTitle), isTrue);

    // Fiches rangées en dossiers, et cartes rangées avec leur fiche.
    final folders = await db.select(db.localFolders).get();
    expect(folders.map((f) => f.name),
        containsAll(['Mathématiques', 'Analyse', 'Physique']));
    expect(notes.where((n) => n.folderId != null), hasLength(8));
    final cards = await db.select(db.localFlashcards).get();
    expect(cards, isNotEmpty);
    expect(cards.every((c) => c.folderId != null), isTrue);

    // Graphe peuplé, tâches dans les trois colonnes, habitudes cochées.
    expect(await db.select(db.localNoteLinks).get(), hasLength(greaterThan(5)));
    final tasks = await db.select(db.localTasks).get();
    expect(tasks.map((t) => t.status).toSet(), {'todo', 'doing', 'done'});
    expect(await db.select(db.localHabitLogs).get(), isNotEmpty);

    // Un second clic ne duplique rien.
    expect(await loadDemoData(container.read), DemoLoadResult.alreadyLoaded);
    expect(
      await (db.select(db.localNotes)
            ..where((t) => t.title.equals(demoMarkerTitle)))
          .get(),
      hasLength(1),
    );
  });
}
