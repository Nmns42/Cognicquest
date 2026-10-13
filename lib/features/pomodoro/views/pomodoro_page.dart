import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/motion/micro_animations.dart';
import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/pomodoro_session_model.dart';
import '../providers/pomodoro_provider.dart';
import '../../../core/theme/tokens.dart';

class PomodoroPage extends ConsumerWidget {
  const PomodoroPage({super.key});

  static const Color _breakColor = Color(0xFF6B8FA8);

  Color _phaseColor(BuildContext context, PomodoroPhase phase) =>
      phase.isWork ? context.cq.vert : _breakColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final statsAsync = ref.watch(pomodoroStatsProvider);

    final color = _phaseColor(context, state.phase);

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            children: [
              _PhaseHeader(state: state, color: color),
              const SizedBox(height: 32),
              // Micro-animation n° 7 : la jauge bat une fois à la fin d'une
              // session de travail. Le son et la vibration de fin de phase
              // (PomodoroNotifier) restent, animations réduites ou non.
              PulseOnChange(
                trigger: ref.watch(pomodoroCompletionsProvider),
                scale: 1.06,
                duration: const Duration(milliseconds: 420),
                child: _TimerDial(state: state, color: color),
              ),
              const SizedBox(height: 36),
              _Controls(
                state: state,
                color: color,
                onToggle: notifier.toggle,
                onReset: notifier.reset,
                onSkip: notifier.skip,
              ),
              const SizedBox(height: 32),
              _CycleIndicator(state: state, color: color),
              const SizedBox(height: 24),
              statsAsync.when(
                loading: () => const SizedBox(height: 74),
                error: (_, __) => const SizedBox(height: 74),
                data: (stats) => _StatsRow(stats: stats),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({required this.state, required this.color});

  final PomodoroState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Text(
            state.phase.label,
            style: TextStyle(
              color: color,
              fontSize: TypeScale.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          switch (state.phase) {
            PomodoroPhase.work => 'Une seule tâche, rien d\'autre.',
            PomodoroPhase.shortBreak => 'Lève-toi, respire, bouge un peu.',
            PomodoroPhase.longBreak => 'Pause longue : coupe vraiment.',
          },
          style:  TextStyle(color: context.cq.textMuted, fontSize: TypeScale.body),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial({required this.state, required this.color});

  final PomodoroState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width.clamp(280.0, 420.0) * 0.68;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // `TweenAnimationBuilder` lisse le saut d'une seconde à l'autre :
          // la jauge descend en continu au lieu de tressauter.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: state.progress, end: state.progress),
            duration: Motion.duration(context, const Duration(milliseconds: 900)),
            builder: (context, value, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor: context.cq.beigeDark,
                color: color,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.timeDisplay,
                style: TextStyle(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.bold,
                  color: context.cq.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                switch (state.status) {
                  PomodoroStatus.running => 'En cours',
                  PomodoroStatus.paused => 'En pause',
                  PomodoroStatus.idle => 'Prêt',
                },
                style:  TextStyle(color: context.cq.textMuted, fontSize: TypeScale.body),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.color,
    required this.onToggle,
    required this.onReset,
    required this.onSkip,
  });

  final PomodoroState state;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onReset,
          tooltip: 'Réinitialiser',
          icon:  Icon(Icons.refresh, size: 30, color: context.cq.textMuted),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 88,
          height: 88,
          child: FloatingActionButton(
            onPressed: onToggle,
            backgroundColor: color,
            elevation: 0,
            heroTag: 'pomodoro-toggle',
            tooltip: state.isRunning ? 'Mettre en pause' : 'Démarrer',
            child: Icon(
              state.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: context.onAccent,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          // Ce bouton était inerte (`onPressed: () {}`) : il passe désormais
          // réellement à la phase suivante, sans valider la session en cours.
          onPressed: onSkip,
          tooltip: 'Phase suivante',
          icon:  Icon(Icons.skip_next, size: 30, color: context.cq.textMuted),
        ),
      ],
    );
  }
}

/// Points de progression dans le cycle de 4 sessions avant la pause longue.
class _CycleIndicator extends StatelessWidget {
  const _CycleIndicator({required this.state, required this.color});

  final PomodoroState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final done = state.cyclePosition % AppConfig.sessionsBeforeLongBreak;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < AppConfig.sessionsBeforeLongBreak; i++)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: i < done ? color : context.cq.beigeDark,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          done == 0
              ? 'Pause longue après ${AppConfig.sessionsBeforeLongBreak} sessions'
              : 'Plus que ${AppConfig.sessionsBeforeLongBreak - done} '
                  'session${AppConfig.sessionsBeforeLongBreak - done > 1 ? 's' : ''} '
                  'avant la pause longue',
          style:  TextStyle(color: context.cq.textMuted, fontSize: TypeScale.caption),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final PomodoroStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_outlined,
            value: '${stats.sessionsToday}',
            label: "Sessions aujourd'hui",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_outlined,
            value: formatFocusDuration(stats.focusThisWeek),
            label: 'Focus cette semaine',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.monetization_on_outlined,
            value: '${stats.coins(AppConfig.coinsPerWorkSession)}',
            label: 'Pièces',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: context.cq.textMuted),
            const SizedBox(height: 8),
            Text(
              value,
              style:  TextStyle(
                fontSize: TypeScale.title,
                fontWeight: FontWeight.w700,
                color: context.cq.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:  TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
