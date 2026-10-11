import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_queue.dart';
import '../../../core/errors/data_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../../graph/data/note_link_repository.dart';
import '../../habits/data/habit_repository.dart';
import '../../kanban/data/task_repository.dart';
import '../../metacognition/data/metacognition_repository.dart';
import '../../notes/data/note_repository.dart';
import '../../planning/data/planning_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../review/data/review_repository.dart';

/// État de la synchronisation, affiché discrètement par la coquille.
class SyncStatus {
  const SyncStatus({
    this.pendingCount = 0,
    this.isSyncing = false,
    this.isOffline = false,
    this.lastSyncedAt,
    this.lastError,
  });

  /// Écritures locales pas encore envoyées au serveur.
  final int pendingCount;
  final bool isSyncing;

  /// Le dernier essai a échoué faute de réseau.
  final bool isOffline;
  final DateTime? lastSyncedAt;

  /// Dernière erreur autre qu'une coupure réseau (table absente, droits…).
  final String? lastError;

  SyncStatus copyWith({
    int? pendingCount,
    bool? isSyncing,
    bool? isOffline,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncStatus(
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      isOffline: isOffline ?? this.isOffline,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Orchestre la synchronisation de tous les modules local-first.
///
/// Répond au CdC : « Mode offline avec synchronisation automatique dès
/// qu'internet est disponible ». Chaque repository pousse déjà ses écritures
/// au moment où elles ont lieu ; le coordinateur rattrape tout ce qui a
/// échoué faute de réseau, sans que l'utilisateur ait à tirer pour rafraîchir :
///
/// - à la connexion et au lancement ;
/// - au retour de l'app au premier plan ;
/// - après un échec, avec des réessais espacés (15 s → 2 min) ;
/// - toutes les 5 minutes, pour rapatrier les changements des autres appareils.
class SyncCoordinator extends Notifier<SyncStatus> {
  static const Duration periodicInterval = Duration(minutes: 5);
  static const Duration _baseRetryDelay = Duration(seconds: 15);
  static const int _maxBackoffExponent = 3;

  Timer? _retryTimer;
  int _consecutiveFailures = 0;
  bool _disposed = false;

  @override
  SyncStatus build() {
    final userId = ref.watch(currentUserIdProvider);

    _disposed = false;
    _consecutiveFailures = 0;
    ref.onDispose(() {
      _disposed = true;
      _retryTimer?.cancel();
    });

    // Pas de vraie session (y compris en mode DEV_BYPASS_AUTH) : rien à
    // synchroniser, tout reste sur l'appareil.
    if (userId == null || ref.watch(currentUserProvider) == null) {
      return const SyncStatus();
    }

    final periodic = Timer.periodic(periodicInterval, (_) => syncNow());
    final lifecycle = AppLifecycleListener(onResume: syncNow);
    final pendingSubscription = SyncQueue(ref.watch(appDatabaseProvider))
        .watchPendingCount()
        .listen((count) {
      if (!_disposed) state = state.copyWith(pendingCount: count);
    });
    ref.onDispose(() {
      periodic.cancel();
      lifecycle.dispose();
      pendingSubscription.cancel();
    });

    // Après le premier build : `state` n'est pas encore lisible ici.
    Future.microtask(syncNow);
    return const SyncStatus();
  }

  /// Synchronise tous les modules, dans l'ordre des dépendances serveur :
  /// les tâches avant les sessions Pomodoro qui peuvent y renvoyer, les
  /// fiches avant leurs liens et leurs cartes.
  List<Future<void> Function()?> _modules() => [
        ref.read(taskRepositoryProvider)?.sync,
        ref.read(habitRepositoryProvider)?.sync,
        ref.read(pomodoroRepositoryProvider)?.sync,
        ref.read(noteRepositoryProvider)?.sync,
        ref.read(noteLinkRepositoryProvider)?.sync,
        ref.read(reviewRepositoryProvider)?.sync,
        ref.read(metacognitionRepositoryProvider)?.sync,
        ref.read(planningRepositoryProvider)?.sync,
      ];

  Future<void> syncNow() async {
    if (_disposed || state.isSyncing) return;
    if (ref.read(currentUserProvider) == null) return;

    _retryTimer?.cancel();
    state = state.copyWith(isSyncing: true);

    DataFailure? failure;
    for (final sync in _modules()) {
      if (sync == null) continue;
      try {
        await sync();
      } catch (error) {
        final current = DataFailure.from(error);
        // Hors ligne, inutile d'essayer les modules suivants : ils
        // échoueraient de la même façon.
        if (current.isOffline) {
          failure = current;
          break;
        }
        // Une erreur serveur sur un module ne doit pas priver les autres de
        // leur synchronisation.
        failure ??= current;
      }
      if (_disposed) return;
    }
    if (_disposed) return;

    if (failure == null) {
      _consecutiveFailures = 0;
      state = state.copyWith(
        isSyncing: false,
        isOffline: false,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      );
      return;
    }

    _consecutiveFailures++;
    state = state.copyWith(
      isSyncing: false,
      isOffline: failure.isOffline,
      lastError: failure.isOffline ? null : failure.message,
      clearError: failure.isOffline,
    );
    _scheduleRetry();
  }

  void _scheduleRetry() {
    final exponent = min(_consecutiveFailures - 1, _maxBackoffExponent);
    final delay = _baseRetryDelay * pow(2, exponent).toInt();
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, syncNow);
  }
}

final syncCoordinatorProvider =
    NotifierProvider<SyncCoordinator, SyncStatus>(SyncCoordinator.new);
