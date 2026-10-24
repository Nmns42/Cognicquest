import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/habits/data/habit_repository.dart';
import 'package:cognicquest/features/habits/views/habits_page.dart';
import 'package:cognicquest/shared/models/habit_model.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Habitudes sur téléphone : ligne entière cliquable → fiche récapitulative,
/// sélecteur de fréquence lisible.
void main() {
  late AppDatabase db;
  late SupabaseClient client;
  late LocalFirstHabitRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    client = SupabaseClient('http://fake.local', 'anon-key',
        httpClient: MockClient((r) async => http.Response('', 500)),
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    repository = LocalFirstHabitRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [habitRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(theme: AppTheme.light, home: const HabitsPage()),
    ));
    await tester.pumpAndSettle();
  }

  /// Démontage explicite en fin de test : les flux Drift posent un
  /// minuteur à leur fermeture, qui doit s'écouler avant la vérification
  /// des minuteurs en attente.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('toucher la ligne ouvre la fiche, qui valide le jour',
      (tester) async {
    await tester.runAsync(() => repository.create(
        name: 'Méditation', frequency: HabitFrequency.daily));
    await pump(tester);

    await tester.tap(find.text('Méditation'));
    await tester.pumpAndSettle();

    expect(find.text('Série actuelle'), findsOneWidget);
    expect(find.text('Meilleure série'), findsOneWidget);
    expect(find.text('Semaine'), findsOneWidget);

    final validate = find.text('Valider aujourd’hui');
    await tester.ensureVisible(validate);
    await tester.tap(validate);
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final habit = (await tester.runAsync(
        () => repository.watchAll().first))!.single;
    expect(habit.completedToday, isTrue);
    expect(find.textContaining('Annuler la validation'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('fréquences en options pleine largeur, lisibles', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Nouvelle habitude'));
    await tester.pumpAndSettle();

    for (final frequency in HabitFrequency.values) {
      expect(find.text(frequency.label), findsOneWidget);
    }
    await tester.tap(find.text(HabitFrequency.weekly.label));
    await tester.pump();
    expect(find.text('Une case par semaine, 4 par mois'), findsOneWidget);
    await unmount(tester);
  });
}
