import 'dart:async';

import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/ui/cq_dismissible_banner.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:cognicquest/features/settings/data/ambient_sound_engine.dart';
import 'package:cognicquest/features/settings/domain/user_settings.dart';
import 'package:cognicquest/features/settings/providers/settings_provider.dart';
import 'package:cognicquest/features/settings/views/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Moteur d'ambiance factice : enregistre les ordres reçus, sans lecteur
/// audio réel.
class _FakeAmbientEngine implements AmbientSoundEngine {
  final volumes = <double>[];
  final played = <AmbientSound>[];

  @override
  Future<void> play(AmbientSound sound, {required double volume}) async {
    played.add(sound);
    volumes.add(volume);
  }

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Chantier 12 (B), contrôle positif : réduire les reconstructions ne doit
/// pas retarder ni empêcher l'effet d'un réglage sur ceux qui en dépendent.
void main() {
  // Client hors ligne : sans session, les réglages restent locaux.
  SupabaseClient offlineClient() => SupabaseClient(
        'http://offline.invalid',
        'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

  test('les providers dérivés réagissent immédiatement', () async {
    final client = offlineClient();
    addTearDown(client.dispose);
    final container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(settingsProvider.notifier);

    final reduceMotion = <bool>[];
    container.listen(reduceMotionProvider, (_, next) => reduceMotion.add(next),
        fireImmediately: true);
    final themes = <ThemeData>[];
    container.listen(appThemeProvider, (_, next) => themes.add(next),
        fireImmediately: true);

    // Riverpod notifie les providers dérivés au prochain vidage de sa file,
    // avant la frame suivante : c'est ce « tout de suite » que voit un widget.
    notifier.toggleReduceMotion();
    await container.pump();
    expect(reduceMotion, [false, true]);

    final other = AppThemeVariant.values.firstWhere(
      (v) => v != container.read(settingsProvider).themeVariant,
    );
    notifier.setTheme(other);
    await container.pump();
    expect(themes, hasLength(2));
    // Deux ThemeData construits séparément ne sont jamais égaux : on compare
    // ce qui distingue les thèmes.
    final expected = AppTheme.build(other);
    expect(themes.last.colorScheme, expected.colorScheme);
    expect(themes.last.scaffoldBackgroundColor,
        expected.scaffoldBackgroundColor);

    // Un réglage sans rapport ne produit aucune notification parasite.
    notifier.setAmbientVolume(0.2);
    await container.pump();
    expect(reduceMotion, hasLength(2));
    expect(themes, hasLength(2));
  });

  testWidgets(
      'réglages Pomodoro : « + » allonge la session, et le minuteur au repos '
      'prend la nouvelle durée', (tester) async {
    final client = offlineClient();
    addTearDown(() => unawaited(client.dispose()));
    final container = ProviderContainer(overrides: [
      ambientSoundEngineProvider.overrideWithValue(_FakeAmbientEngine()),
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);
    // Le minuteur existe déjà, au repos (25 min par défaut).
    expect(container.read(pomodoroProvider).totalSeconds, 25 * 60);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pump();

    final plus = find.byTooltip('Augmenter : Session de travail');
    await tester.scrollUntilVisible(plus, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(plus);
    await tester.pump();
    await tester.tap(plus);
    await tester.pump();

    expect(container.read(settingsProvider).pomodoro.workMinutes, 30);
    expect(container.read(pomodoroProvider).totalSeconds, 30 * 60);
    expect(container.read(pomodoroProvider).remainingSeconds, 30 * 60);

    // Plus de section « Ambiance sonore » dans les réglages.
    expect(find.text('Ambiance sonore'), findsNothing);

    // Laisse partir la sauvegarde différée des réglages.
    await tester.pump(const Duration(seconds: 5));
  });

  test('sessions avant la pause longue : bornées, plus figées à 4', () {
    const config = PomodoroSettings.defaults;
    expect(config.copyWith(sessionsBeforeLongBreak: 7).sessionsBeforeLongBreak,
        7);
    expect(config.copyWith(sessionsBeforeLongBreak: 99).sessionsBeforeLongBreak,
        PomodoroSettings.sessionsRange.$2);
    final restored = UserSettings.fromJson(
        const UserSettings(pomodoro: PomodoroSettings(workMinutes: 50))
            .toJson());
    expect(restored.pomodoro.workMinutes, 50);
  });

  testWidgets("encadré d'aide : la croix le ferme et il ne revient pas",
      (tester) async {
    final client = offlineClient();
    addTearDown(() => unawaited(client.dispose()));
    final container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);

    Widget banner() => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: CqDismissibleBanner(
                bannerId: 'test.aide',
                message: "Explication de l'outil",
              ),
            ),
          ),
        );

    await tester.pumpWidget(banner());
    expect(find.text("Explication de l'outil"), findsOneWidget);

    await tester.tap(find.byTooltip("Fermer l'aide"));
    await tester.pumpAndSettle();

    expect(find.text("Explication de l'outil"), findsNothing);
    expect(container.read(settingsProvider).dismissedBanners, {'test.aide'});

    // Remonté plus tard (autre écran, autre session) : toujours fermé.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(banner());
    expect(find.text("Explication de l'outil"), findsNothing);

    // Laisse passer l'enregistrement différé des préférences.
    await tester.pump(const Duration(seconds: 1));
  });
}
