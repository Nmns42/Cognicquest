import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/pomodoro_session_model.dart';
import '../../settings/domain/user_settings.dart';
import '../../settings/providers/settings_provider.dart';
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
    this.cycleLength = 4,
  });

  factory PomodoroState.initial(
      [PomodoroSettings config = PomodoroSettings.defaults]) {
    final duration = config.workMinutes * 60;
    return PomodoroState(
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.work,
      remainingSeconds: duration,
      totalSeconds: duration,
      completedSessions: 0,
      cyclePosition: 0,
      cycleLength: config.sessionsBeforeLongBreak,
    );
  }

  final PomodoroStatus status;
  final PomodoroPhase phase;
  final int remainingSeconds;
  final int totalSeconds;

  /// Sessions de travail terminées aujourd'hui (réhydraté depuis l'historique
  /// local au lancement, plus remis à zéro à chaque ouverture de l'app).
  final int completedSessions;

  /// Position dans le cycle de sessions avant la pause longue.
  final int cyclePosition;

  /// Sessions de travail avant la pause longue (réglage).
  final int cycleLength;

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
  int get sessionsUntilLongBreak => cycleLength - cyclePosition;

  PomodoroState copyWith({
    PomodoroStatus? status,
    PomodoroPhase? phase,
    int? remainingSeconds,
    int? totalSeconds,
    int? completedSessions,
    int? cyclePosition,
    int? cycleLength,
  }) {
    return PomodoroState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      completedSessions: completedSessions ?? this.completedSessions,
      cyclePosition: cyclePosition ?? this.cyclePosition,
      cycleLength: cycleLength ?? this.cycleLength,
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
    // Les réglages arrivent de la base locale après le premier build : un
    // minuteur qui n'a pas commencé sa phase prend la nouvelle durée.
    ref.listen(settingsProvider.select((s) => s.pomodoro), (_, next) {
      final untouched = !state.isRunning &&
          state.remainingSeconds == state.totalSeconds;
      final duration = _durationOf(state.phase, next);
      state = state.copyWith(
        cycleLength: next.sessionsBeforeLongBreak,
        remainingSeconds: untouched ? duration : null,
        totalSeconds: untouched ? duration : null,
      );
    });
    unawaited(_seedFromHistory());
    return PomodoroState.initial(_config);
  }

  PomodoroSettings get _config => ref.read(settingsProvider).pomodoro;

  static int _durationOf(PomodoroPhase phase, PomodoroSettings config) =>
      switch (phase) {
        PomodoroPhase.work => config.workMinutes * 60,
        PomodoroPhase.shortBreak => config.shortBreakMinutes * 60,
        PomodoroPhase.longBreak => config.longBreakMinutes * 60,
      };

  int get _phaseDurationSeconds => _durationOf(state.phase, _config);

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

  /// Termine la phase en cours comme si son décompte arrivait à zéro.
  @visibleForTesting
  Future<void> finishPhase() => _completePhase();

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

    // Sonnerie choisie dans les réglages, à la fin de chaque session de
    // travail comme de chaque pause.
    unawaited(_notifyPhaseEnd());

    // Fin de phase réelle : la suivante démarre seule, sauf après la pause
    // longue, qui clôt le cycle de sessions configuré.
    final cycleDone = state.phase == PomodoroPhase.longBreak;
    _advancePhase(sessionCompleted: wasWork, autoStart: !cycleDone);

    if (wasWork && startedAt != null) {
      await _archiveSession(startedAt);
    }
  }

  /// Passe à la phase suivante. [autoStart] relance aussitôt le décompte
  /// (enchaînement automatique travail ↔ pauses) ; sinon le minuteur attend.
  void _advancePhase({required bool sessionCompleted, bool autoStart = false}) {
    final wasWork = state.phase.isWork;

    PomodoroPhase nextPhase;
    var cyclePosition = state.cyclePosition;

    if (wasWork) {
      if (sessionCompleted) cyclePosition += 1;
      // Pause longue tous les N cycles — absente de la version précédente,
      // qui alternait indéfiniment travail / pause courte.
      final dueLongBreak = cyclePosition > 0 &&
          cyclePosition % _config.sessionsBeforeLongBreak == 0;
      nextPhase = dueLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      nextPhase = PomodoroPhase.work;
      if (state.phase == PomodoroPhase.longBreak) cyclePosition = 0;
    }

    final duration = _durationOf(nextPhase, _config);

    state = state.copyWith(
      status: PomodoroStatus.idle,
      phase: nextPhase,
      remainingSeconds: duration,
      totalSeconds: duration,
      cyclePosition: cyclePosition,
      cycleLength: _config.sessionsBeforeLongBreak,
      completedSessions:
          sessionCompleted ? state.completedSessions + 1 : state.completedSessions,
    );

    if (autoStart) start();
  }

  Future<void> _notifyPhaseEnd() async {
    await ref.read(pomodoroChimeProvider).play(_config.ringtone);
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Pas de vibration disponible (web, bureau) : sans importance.
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
        durationSeconds: _config.workMinutes * 60,
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
        cyclePosition: stats.sessionsToday % _config.sessionsBeforeLongBreak,
      );
    } catch (_) {
      // Base locale indisponible : on démarre simplement à zéro.
    }
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(
  PomodoroNotifier.new,
);

/// Joue la sonnerie de fin de phase.
///
/// Le fichier de `assets/sounds/` est lu par audioplayers ; s'il manque ou
/// si aucun lecteur n'est disponible (plateforme, tests), le bip d'alerte du
/// système prend le relais : la fin de phase n'est jamais silencieuse.
class PomodoroChime {
  AudioPlayer? _player;

  Future<void> play(PomodoroRingtone ringtone) async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource(ringtone.assetPath));
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        // Aucun son disponible : la vibration et l'écran signalent la fin.
      }
    }
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {
      // Lecteur jamais créé correctement : rien à libérer.
    }
  }
}

final pomodoroChimeProvider = Provider<PomodoroChime>((ref) {
  final chime = PomodoroChime();
  ref.onDispose(() => unawaited(chime.dispose()));
  return chime;
});

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
