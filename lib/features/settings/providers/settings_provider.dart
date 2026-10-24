import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/preferences_repository.dart';
import '../domain/user_settings.dart';

/// Préférences actives.
///
/// Synchrone comme le layout du Dashboard : l'application démarre sur le
/// thème par défaut et bascule dès que la valeur enregistrée sur l'appareil
/// est lue (quelques millisecondes, sans réseau). Les choix faits sur un autre
/// appareil arrivent ensuite par la synchronisation.
class SettingsNotifier extends Notifier<UserSettings> {
  Timer? _saveDebounce;

  @override
  UserSettings build() {
    ref.onDispose(() => _saveDebounce?.cancel());
    final repository = ref.watch(preferencesRepositoryProvider);
    if (repository != null) {
      final subscription =
          repository.watch(PreferenceKey.settings).listen((json) {
        // Un choix en cours d'enregistrement l'emporte sur une valeur lue
        // entre-temps (ex. un pull arrivé pendant le glissement du volume).
        if (json == null || (_saveDebounce?.isActive ?? false)) return;
        state = UserSettings.fromJson(json);
      });
      ref.onDispose(subscription.cancel);
    }
    return UserSettings.defaults;
  }

  void setTheme(AppThemeVariant variant) =>
      _update(state.copyWith(themeVariant: variant));

  void setTextScale(TextScalePreset preset) =>
      _update(state.copyWith(textScale: preset));

  void setAmbientSound(AmbientSound sound) =>
      _update(state.copyWith(ambientSound: sound));

  void setAmbientVolume(double volume) =>
      _update(state.copyWith(ambientVolume: volume.clamp(0.0, 1.0)));

  void toggleKeyboardShortcuts() => _update(
      state.copyWith(keyboardShortcutsEnabled: !state.keyboardShortcutsEnabled));

  void toggleReduceMotion() =>
      _update(state.copyWith(reduceMotion: !state.reduceMotion));

  void setManualNoteOrder(bool manual) =>
      _update(state.copyWith(manualNoteOrder: manual));

  void setPomodoro(PomodoroSettings pomodoro) =>
      _update(state.copyWith(pomodoro: pomodoro));

  void setDailyReminder(bool enabled) =>
      _update(state.copyWith(dailyReminder: enabled));

  void setDailyReminderMinutes(int minutes) =>
      _update(state.copyWith(dailyReminderMinutes: minutes % (24 * 60)));

  void setPomodoroNotifications(bool enabled) =>
      _update(state.copyWith(pomodoroNotifications: enabled));

  /// Ferme définitivement l'encadré d'aide [bannerId].
  void dismissBanner(String bannerId) {
    if (state.dismissedBanners.contains(bannerId)) return;
    _update(state.copyWith(
        dismissedBanners: {...state.dismissedBanners, bannerId}));
  }

  void resetToDefaults() => _update(UserSettings.defaults);

  void _update(UserSettings settings) {
    state = settings;
    // Faire glisser un curseur de volume ne doit pas produire une écriture
    // par image.
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(_persist(state));
    });
  }

  Future<void> _persist(UserSettings settings) async {
    final repository = ref.read(preferencesRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.save(PreferenceKey.settings, settings.toJson());
    } catch (_) {
      // Préférence d'affichage : appliquée pour cette session, pas de quoi
      // alerter.
    }
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);

/// Thème dérivé des préférences.
///
/// `select` : un `ThemeData` complet n'est reconstruit que si le thème change,
/// pas à chaque réglage (volume, encadrés fermés…).
final appThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.build(
    ref.watch(settingsProvider.select((s) => s.themeVariant)),
  ),
);

/// Facteur d'échelle du texte, appliqué à la racine de l'application.
final textScaleProvider = Provider<double>(
  (ref) => ref.watch(settingsProvider.select((s) => s.textScale.scale)),
);

/// Animations réduites : les widgets consultent ce drapeau pour raccourcir
/// ou supprimer leurs transitions.
final reduceMotionProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider.select((s) => s.reduceMotion)),
);
