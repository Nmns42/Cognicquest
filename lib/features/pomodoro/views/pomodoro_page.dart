import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final dial = PulseOnChange(
      // Micro-animation n° 7 : la jauge bat une fois à la fin d'une session
      // de travail. Le son et la vibration de fin de phase (PomodoroNotifier)
      // restent, animations réduites ou non.
      trigger: ref.watch(pomodoroCompletionsProvider),
      scale: 1.06,
      duration: const Duration(milliseconds: 420),
      child: _FitDial(state: state, color: color),
    );
    final stats = statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => _StatsRow(stats: stats),
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // Écran statique, sans défilement : tout tient dans la place
            // disponible. Les écarts suivent la hauteur (serrés sur un petit
            // téléphone, aérés sur grand écran) et le cadran prend tout
            // l'espace restant.
            final gap = (box.maxHeight * 0.02).clamp(Space.sm, Space.xxl);
            // Bouton principal : 64 sur un petit téléphone, 96 au plus.
            final button =
                (box.maxHeight * 0.1).clamp(Space.xxxl + Space.lg, Space.xxxl * 2);
            final side = (box.maxWidth * 0.05).clamp(Space.lg, Space.xxxl);
            final controls = [
              _Controls(
                state: state,
                color: color,
                size: button,
                onToggle: notifier.toggle,
                onReset: notifier.reset,
                onSkip: notifier.skip,
              ),
              SizedBox(height: gap),
              _CycleIndicator(state: state, color: color),
              SizedBox(height: gap),
              stats,
            ];

            // Grand écran à l'horizontale : cadran à gauche, commandes à
            // droite, chacun à l'échelle de l'écran.
            final wide = box.maxWidth >= 720 && box.maxWidth > box.maxHeight;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: side, vertical: gap),
              child: wide
                  ? Row(
                      children: [
                        Expanded(flex: 7, child: dial),
                        SizedBox(width: side),
                        Expanded(
                          flex: 5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PhaseHeader(state: state, color: color),
                              SizedBox(height: gap * 2),
                              ...controls,
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _PhaseHeader(state: state, color: color),
                        SizedBox(height: gap),
                        Expanded(child: dial),
                        SizedBox(height: gap),
                        ...controls,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// Cadran à la taille de la place que lui laisse la page : le plus grand
/// cercle qui y tient, avec une petite marge pour la pulsation.
class _FitDial extends StatelessWidget {
  const _FitDial({required this.state, required this.color});

  final PomodoroState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, area) => Center(
        child: _TimerDial(
          state: state,
          color: color,
          size: area.biggest.shortestSide * 0.92,
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
          style:
              TextStyle(color: context.cq.textMuted, fontSize: TypeScale.body),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial(
      {required this.state, required this.color, required this.size});

  final PomodoroState state;
  final Color color;

  /// Diamètre, calculé par la page selon la place disponible.
  final double size;

  @override
  Widget build(BuildContext context) {
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
            duration:
                Motion.duration(context, const Duration(milliseconds: 900)),
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
          // À 200 % de texte, minuteur et statut dépassaient du cadran :
          // ils rétrécissent pour rester dans l'anneau.
          Padding(
            padding: EdgeInsets.all(size * 0.12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
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
                    style: TextStyle(
                        color: context.cq.textMuted, fontSize: TypeScale.body),
                  ),
                ],
              ),
            ),
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
    required this.size,
  });

  final PomodoroState state;
  final Color color;

  /// Diamètre du bouton principal, à l'échelle de l'écran.
  final double size;
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
          icon: Icon(Icons.refresh, size: 30, color: context.cq.textMuted),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: size,
          height: size,
          child: FloatingActionButton(
            onPressed: onToggle,
            backgroundColor: color,
            elevation: 0,
            heroTag: 'pomodoro-toggle',
            tooltip: state.isRunning ? 'Mettre en pause' : 'Démarrer',
            child: Icon(
              state.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: context.onAccent,
              size: size * 0.45,
            ),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          // Ce bouton était inerte (`onPressed: () {}`) : il passe désormais
          // réellement à la phase suivante, sans valider la session en cours.
          onPressed: onSkip,
          tooltip: 'Phase suivante',
          icon: Icon(Icons.skip_next, size: 30, color: context.cq.textMuted),
        ),
      ],
    );
  }
}

/// Points de progression dans le cycle de sessions avant la pause longue.
class _CycleIndicator extends StatelessWidget {
  const _CycleIndicator({required this.state, required this.color});

  final PomodoroState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cycle = state.cycleLength;
    final done = state.cyclePosition % cycle;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < cycle; i++)
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
              ? 'Pause longue après $cycle session${cycle > 1 ? 's' : ''}'
              : 'Plus que ${cycle - done} '
                  'session${cycle - done > 1 ? 's' : ''} '
                  'avant la pause longue',
          style: TextStyle(
              color: context.cq.textMuted, fontSize: TypeScale.caption),
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
              style: TextStyle(
                fontSize: TypeScale.title,
                fontWeight: FontWeight.w700,
                color: context.cq.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: TypeScale.caption, color: context.cq.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
