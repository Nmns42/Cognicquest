import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/pomodoro_session_model.dart';
import '../data/pomodoro_repository.dart';

enum PomodoroStatus { idle, running, paused }

enum PomodoroPhase {
  work('Session de travail'),
  shortBreak('Pause courte'),
  longBreak('Pause longue');

  const PomodoroPhase(this.label);

  final String label;

  bool get isWork => this == PomodoroPhase.work;
}

class PomodoroState {
  const PomodoroState({
    required this.status,
    required this.phase,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.completedSessions,
    required this.cyclePosition,
    required this.coins,
  });

  factory PomodoroState.initial() {
    const duration = AppConfig.defaultWorkDurationMinutes * 60;
    return const PomodoroState(
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.work,
      remainingSeconds: duration,
      totalSeconds: duration,
      completedSessions: 0,
      cyclePosition: 0,
      coins: 0,
    );
  }

  final PomodoroStatus status;
  final PomodoroPhase phase;
  final int remainingSeconds;
  final int totalSeconds;

  /// Sessions de travail terminées aujourd'hui (réhydraté depuis l'historique
  /// local au lancement, plus remis à zéro à chaque ouverture de l'app).
  final int completedSessions;

  /// Position dans le cycle de 4 sessions avant la pause longue.
  final int cyclePosition;

  final int coins;

  bool get isRunning => status == PomodoroStatus.running;
  bool get isIdle => status == PomodoroStatus.idle;

  /// Décroît de 1.0 vers 0.0 : la jauge se vide avec le temps.
  double get progress =>
      totalSeconds == 0 ? 0 : (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

  String get timeDisplay {
    final safe = remainingSeconds < 0 ? 0 : remainingSeconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final seconds = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Nombre de sessions restantes avant la pause longue.
  int get sessionsUntilLongBreak =>
      AppConfig.sessionsBeforeLongBreak - cyclePosition;

  PomodoroState copyWith({
    PomodoroStatus? status,
    PomodoroPhase? phase,
    int? remainingSeconds,
    int? totalSeconds,
    int? completedSessions,
    int? cyclePosition,
    int? coins,
  }) {
    return PomodoroState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      completedSessions: completedSessions ?? this.completedSessions,
      cyclePosition: cyclePosition ?? this.cyclePosition,
      coins: coins ?? this.coins,
    );
  }
}

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  /// Instant de fin théorique de la phase en cours.
  ///
  /// Le décompte est recalculé à partir de l'horloge murale à chaque tick :
  /// l'ancienne version décrémentait un compteur à chaque `Timer.periodic`,
  /// ce qui dérivait dans le temps et « gelait » dès que l'app passait en
  /// arrière-plan (les timers Flutter y sont suspendus).
  DateTime? _endsAt;

  /// Début réel de la session de travail, pour l'archivage.
  DateTime? _startedAt;

  @override
  PomodoroState build() {
    ref.onDispose(() => _timer?.cancel());
    unawaited(_seedFromHistory());
    return PomodoroState.initial();
  }

  int get _phaseDurationSeconds => switch (state.phase) {
        PomodoroPhase.work => AppConfig.defaultWorkDurationMinutes * 60,
        PomodoroPhase.shortBreak => AppConfig.defaultShortBreakDurationMinutes * 60,
        PomodoroPhase.longBreak => AppConfig.defaultLongBreakDurationMinutes * 60,
      };

  void start() {
    if (state.isRunning) return;

    _endsAt = DateTime.now().add(Duration(seconds: state.remainingSeconds));
    _startedAt ??= DateTime.now();

    state = state.copyWith(status: PomodoroStatus.running);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      status: PomodoroStatus.paused,
      remainingSeconds: _remainingFromClock(),
    );
    _endsAt = null;
  }

  void toggle() => state.isRunning ? pause() : start();

  void reset() {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
    _startedAt = null;

    final duration = _phaseDurationSeconds;
    state = state.copyWith(
      status: PomodoroStatus.idle,
      remainingSeconds: duration,
      totalSeconds: duration,
    );
  }

  /// Passe à la phase suivante sans valider la session en cours : le bouton
  /// « suivant » de la page était jusqu'ici inerte (`onPressed: () {}`).
  void skip() {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
    _startedAt = null;
    _advancePhase(sessionCompleted: false);
  }

  void _tick() {
    final remaining = _remainingFromClock();
    if (remaining <= 0) {
      _completePhase();
      return;
    }
    state = state.copyWith(remainingSeconds: remaining);
  }

  int _remainingFromClock() {
    final endsAt = _endsAt;
    if (endsAt == null) return state.remainingSeconds;
    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _completePhase() async {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;

    final wasWork = state.phase.isWork;
    final startedAt = _startedAt;
    _startedAt = null;

    // Notification de fin de session, exigée par le CdC. On utilise les sons
    // système plutôt qu'un asset : `assets/sounds/` est vide, et une playlist
    // d'ambiance relève du Lot 9.
    unawaited(_notifyPhaseEnd());

    _advancePhase(sessionCompleted: wasWork);

    if (wasWork && startedAt != null) {
      await _archiveSession(startedAt);
    }
  }

  void _advancePhase({required bool sessionCompleted}) {
    final wasWork = state.phase.isWork;

    PomodoroPhase nextPhase;
    var cyclePosition = state.cyclePosition;

    if (wasWork) {
      if (sessionCompleted) cyclePosition += 1;
      // Pause longue tous les N cycles — absente de la version précédente,
      // qui alternait indéfiniment travail / pause courte.
      final dueLongBreak =
          cyclePosition > 0 && cyclePosition % AppConfig.sessionsBeforeLongBreak == 0;
      nextPhase = dueLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      nextPhase = PomodoroPhase.work;
      if (state.phase == PomodoroPhase.longBreak) cyclePosition = 0;
    }

    final duration = switch (nextPhase) {
      PomodoroPhase.work => AppConfig.defaultWorkDurationMinutes * 60,
      PomodoroPhase.shortBreak => AppConfig.defaultShortBreakDurationMinutes * 60,
      PomodoroPhase.longBreak => AppConfig.defaultLongBreakDurationMinutes * 60,
    };

    state = state.copyWith(
      status: PomodoroStatus.idle,
      phase: nextPhase,
      remainingSeconds: duration,
      totalSeconds: duration,
      cyclePosition: cyclePosition,
      completedSessions:
          sessionCompleted ? state.completedSessions + 1 : state.completedSessions,
      coins: sessionCompleted
          ? state.coins + AppConfig.coinsPerWorkSession
          : state.coins,
    );
  }

  Future<void> _notifyPhaseEnd() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Pas de son/vibration disponible (web, émulateur) : sans importance.
    }
  }

  Future<void> _archiveSession(DateTime startedAt) async {
    final repository = ref.read(pomodoroRepositoryProvider);
    if (repository == null) return;

    try {
      // Écriture locale : les statistiques, qui observent la base, se mettent
      // à jour d'elles-mêmes, réseau ou pas.
      await repository.record(
        startedAt: startedAt,
        durationSeconds: AppConfig.defaultWorkDurationMinutes * 60,
      );
    } catch (_) {
      // L'archivage est du confort : une session perdue ne doit jamais
      // interrompre le minuteur de l'utilisateur.
    }
  }

  Future<void> _seedFromHistory() async {
    final repository = ref.read(pomodoroRepositoryProvider);
    if (repository == null) return;

    try {
      final stats = PomodoroStats.fromSessions(await repository.fetchRecent());
      state = state.copyWith(
        completedSessions: stats.sessionsToday,
        cyclePosition: stats.sessionsToday % AppConfig.sessionsBeforeLongBreak,
        coins: stats.coins(AppConfig.coinsPerWorkSession),
      );
    } catch (_) {
      // Base locale indisponible : on démarre simplement à zéro.
    }
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(
  PomodoroNotifier.new,
);

/// Statistiques d'étude — « Temps total d'étude par jour/semaine » (CdC).
final pomodoroStatsProvider = StreamProvider<PomodoroStats>((ref) {
  final repository = ref.watch(pomodoroRepositoryProvider);
  if (repository == null) return Stream.value(const PomodoroStats.empty());
  return repository.watchRecent().map(PomodoroStats.fromSessions);
});

/// Nombre de sessions de travail **menées à leur terme** depuis l'ouverture
/// de l'app : signal de la micro-animation de fin de Pomodoro (n° 7).
///
/// `completedSessions` ne suffit pas : il est aussi recalé sur l'historique
/// au chargement, ce qui déclencherait l'animation à l'ouverture. Ici, seul
/// compte le passage de la phase de travail à une pause avec une session de
/// plus — pas un passage manuel (« Passer »), qui ne compte pas la session.
class PomodoroCompletions extends Notifier<int> {
  @override
  int build() {
    ref.listen(pomodoroProvider, (previous, next) {
      if (previous == null) return;
      final finishedWork = previous.phase == PomodoroPhase.work &&
          next.phase != PomodoroPhase.work &&
          next.completedSessions == previous.completedSessions + 1;
      if (finishedWork) state++;
    });
    return 0;
  }
}

final pomodoroCompletionsProvider =
    NotifierProvider<PomodoroCompletions, int>(PomodoroCompletions.new);

/// Mode concentration : vrai pendant qu'une session tourne. La coquille
/// masque alors toute la navigation sur l'écran du Pomodoro.
final focusModeProvider = Provider<bool>(
  (ref) => ref.watch(pomodoroProvider.select((s) => s.isRunning)),
);
