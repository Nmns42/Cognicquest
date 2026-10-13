import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/preferences_repository.dart';
import '../models/dashboard_module.dart';

/// Disposition du Dashboard, gardée sur l'appareil et synchronisée entre
/// appareils.
///
/// L'état est volontairement synchrone ([Notifier] et non [AsyncNotifier]) : le
/// Dashboard s'affiche immédiatement avec la disposition par défaut, puis se
/// réorganise dès que la disposition enregistrée est lue. On évite ainsi un
/// écran de chargement pour un simple ordre d'affichage.
class DashboardLayoutNotifier extends Notifier<DashboardLayout> {
  Timer? _saveDebounce;

  @override
  DashboardLayout build() {
    ref.onDispose(() => _saveDebounce?.cancel());
    // Se relance à la connexion / déconnexion.
    final repository = ref.watch(preferencesRepositoryProvider);
    if (repository != null) {
      final subscription =
          repository.watch(PreferenceKey.dashboardLayout).listen((json) {
        // Un glisser-déposer en cours d'enregistrement l'emporte.
        if (json == null || (_saveDebounce?.isActive ?? false)) return;
        state = DashboardLayout.fromJson(json);
      });
      ref.onDispose(subscription.cancel);
    }
    return DashboardLayout.initial;
  }

  void reorder(int oldIndex, int newIndex) {
    final next = state.reorder(oldIndex, newIndex);
    if (next == state) return;
    state = next;
    _scheduleSave();
  }

  void toggle(DashboardModule module) {
    state = state.toggle(module);
    _scheduleSave();
  }

  void resetToDefault() {
    state = DashboardLayout.initial;
    _scheduleSave();
  }

  /// Un glisser-déposer produit plusieurs mouvements rapprochés : on ne veut
  /// pas une écriture par image.
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_persist(state));
    });
  }

  Future<void> _persist(DashboardLayout layout) async {
    final repository = ref.read(preferencesRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.save(PreferenceKey.dashboardLayout, layout.toJson());
    } catch (_) {
      // La personnalisation reste appliquée pour cette session ; une
      // préférence d'affichage ne justifie pas d'alerter l'utilisateur.
    }
  }
}

final dashboardLayoutProvider =
    NotifierProvider<DashboardLayoutNotifier, DashboardLayout>(
  DashboardLayoutNotifier.new,
);
