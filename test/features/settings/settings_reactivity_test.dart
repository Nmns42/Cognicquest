import 'dart:async';

import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
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

  testWidgets('le curseur de volume applique la valeur au moteur sans délai',
      (tester) async {
    final engine = _FakeAmbientEngine();
    final client = offlineClient();
    // Créé dans le temps simulé : sa fermeture n'est pas attendue.
    addTearDown(() => unawaited(client.dispose()));
    final container = ProviderContainer(overrides: [
      ambientSoundEngineProvider.overrideWithValue(engine),
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);
    container
        .read(settingsProvider.notifier)
        .setAmbientSound(AmbientSound.pinkNoise);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pump();

    // Page en liste paresseuse : le curseur n'est construit qu'une fois
    // amené à l'écran.
    final slider = find.byType(Slider);
    await tester.scrollUntilVisible(slider, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    final before = container.read(settingsProvider).ambientVolume;
    await tester.tapAt(tester.getTopLeft(slider) +
        Offset(tester.getSize(slider).width * 0.9,
            tester.getSize(slider).height / 2));
    await tester.pump();

    final after = container.read(settingsProvider).ambientVolume;
    expect(after, isNot(before));
    expect(engine.volumes, isNotEmpty);
    expect(engine.volumes.last, after);

    // Laisse partir la sauvegarde différée des réglages.
    await tester.pump(const Duration(seconds: 5));
  });
}
