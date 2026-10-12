import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/data_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/user_settings.dart';

abstract interface class SettingsRepository {
  Future<UserSettings?> fetch();
  Future<void> save(UserSettings settings);
}

/// Persistance dans `user_preferences.settings` (jsonb).
///
/// La table a été créée au Lot 3 en la disant « volontairement générique :
/// le Lot 9 y ajoutera ses colonnes sans nouvelle migration structurelle ».
/// C'est exactement ce qui se passe : une colonne jsonb de plus.
class SupabaseSettingsRepository implements SettingsRepository {
  const SupabaseSettingsRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const String _table = 'user_preferences';

  @override
  Future<UserSettings?> fetch() async {
    try {
      final row = await _client
          .from(_table)
          .select('settings')
          .eq('user_id', _userId)
          .maybeSingle();

      final raw = row?['settings'];
      if (raw is! Map || raw.isEmpty) return null;
      return UserSettings.fromJson(Map<String, dynamic>.from(raw));
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Future<void> save(UserSettings settings) async {
    try {
      await _client.from(_table).upsert(
        {'user_id': _userId, 'settings': settings.toJson()},
        onConflict: 'user_id',
      );
    } catch (error) {
      throw DataFailure.from(error);
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return SupabaseSettingsRepository(ref.watch(supabaseClientProvider), userId);
});

/// Préférences actives.
///
/// Synchrone comme le layout du Dashboard : l'application démarre sur le
/// thème par défaut et bascule dès que les préférences arrivent. Attendre le
/// réseau pour choisir une couleur produirait un écran blanc au lancement.
class SettingsNotifier extends Notifier<UserSettings> {
  Timer? _saveDebounce;

  @override
  UserSettings build() {
    ref.onDispose(() => _saveDebounce?.cancel());
    ref.watch(settingsRepositoryProvider);
    unawaited(_load());
    return UserSettings.defaults;
  }

  Future<void> _load() async {
    final repository = ref.read(settingsRepositoryProvider);
    if (repository == null) return;
    try {
      final stored = await repository.fetch();
      if (stored != null) state = stored;
    } catch (_) {
      // Hors ligne : les valeurs par défaut font l'affaire.
    }
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

  void setMorningRoutine(Routine routine) =>
      _update(state.copyWith(morningRoutine: routine));

  void setEveningRoutine(Routine routine) =>
      _update(state.copyWith(eveningRoutine: routine));

  void resetToDefaults() => _update(UserSettings.defaults);

  void _update(UserSettings settings) {
    state = settings;
    // Faire glisser un curseur de volume ne doit pas produire une écriture
    // réseau par image.
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(_persist(state));
    });
  }

  Future<void> _persist(UserSettings settings) async {
    final repository = ref.read(settingsRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.save(settings);
    } catch (_) {
      // Préférence d'affichage : appliquée localement, pas de quoi alerter.
    }
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);

/// Thème dérivé des préférences.
///
/// `select` : un `ThemeData` complet n'est reconstruit que si le thème change,
/// pas à chaque réglage (volume, routines…).
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
