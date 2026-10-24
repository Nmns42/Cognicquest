import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/micro_animations.dart';
import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/pomodoro_session_model.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../widgets/pomodoro_settings_form.dart';
import '../../../core/theme/tokens.dart';

class PomodoroPage extends ConsumerWidget {
  const PomodoroPage({super.key});

  static const Color _breakColor = Color(0xFF6B8FA8);

  Color _phaseColor(BuildContext context, PomodoroPhase phase) =>
      phase.isWork ? context.cq.vertSauge : _breakColor;

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
        child: Stack(
          children: [
            Positioned.fill(child: LayoutBuilder(
              builder: (context, box) {
                // Écran statique, sans défilement : tout tient dans la place
                // disponible. Les écarts suivent la hauteur (serrés sur un petit
                // téléphone, aérés sur grand écran) et le cadran prend tout
                // l'espace restant.
                final gap = (box.maxHeight * 0.02).clamp(Space.sm, Space.xxl);
                // Bouton principal, rond et compact : 56 sur un petit téléphone,
                // 80 au plus.
                final button = (box.maxHeight * 0.085)
                    .clamp(Space.xxxl + Space.sm, Space.xxxl + Space.xxl);
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
                final wide =
                    box.maxWidth >= 720 && box.maxWidth > box.maxHeight;

                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: side, vertical: gap),
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
                            _shrinkToFit(
                              maxHeight: box.maxHeight * 0.2,
                              width: box.maxWidth - 2 * side,
                              child: _PhaseHeader(state: state, color: color),
                            ),
                            SizedBox(height: gap),
                            Expanded(child: dial),
                            SizedBox(height: gap),
                            // Petit écran ou texte très agrandi : les commandes
                            // rétrécissent au lieu de déborder (pas de
                            // défilement sur cet écran).
                            _shrinkToFit(
                              maxHeight: box.maxHeight * 0.55,
                              width: box.maxWidth - 2 * side,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: controls,
                              ),
                            ),
                          ],
                        ),
                );
              },
            )),
            // Réglage rapide des durées, sans quitter le minuteur.
            Positioned(
              top: Space.xs,
              right: Space.xs,
              child: IconButton(
                tooltip: 'Régler le Pomodoro',
                icon: Icon(Icons.tune,
                    size: Sizes.iconMd, color: context.cq.textMuted),
                onPressed: () => _showDurations(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showDurations(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        sheetAnimationStyle: Motion.style(context),
        builder: (context) => Consumer(
          builder: (context, ref, _) => SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + Space.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: Text('Réglages du Pomodoro',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: Space.sm),
                  PomodoroDurationsForm(
                    config: ref.watch(settingsProvider).pomodoro,
                    onChanged: ref.read(settingsProvider.notifier).setPomodoro,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Contenu à sa taille naturelle, réduit d'un bloc s'il dépasse
/// [maxHeight] : jamais de débordement, même à 200 % de texte.
Widget _shrinkToFit({
  required double maxHeight,
  required double width,
  required Widget child,
}) =>
    ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: width, child: child),
      ),
    );

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
        Semantics(
          header: true,
          child: Text(
            state.phase.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: Space.sm),
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
                // Anneau fin, proportionné au cadran.
                strokeWidth: (size * 0.018).clamp(Space.xs, Space.sm),
                strokeCap: StrokeCap.round,
                backgroundColor: context.cq.sauge,
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
                  // Minuteur en serif éditoriale, fin : présent sans crier.
                  Text(
                    state.timeDisplay,
                    style: TextStyle(
                      fontFamily: appSerifFamily,
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: TypeScale.displayTracking,
                      color: context.cq.textPrimary,
                      fontFeatures: TypeScale.tabular,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    switch (state.status) {
                      PomodoroStatus.running => 'En cours',
                      PomodoroStatus.paused => 'En pause',
                      PomodoroStatus.idle => 'Prêt',
                    },
                    style: TextStyle(
                        color: context.cq.terre, fontSize: TypeScale.body),
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
          icon: Icon(Icons.refresh,
              size: Sizes.iconLg, color: context.cq.textMuted),
        ),
        const SizedBox(width: Space.xl),
        SizedBox(
          width: size,
          height: size,
          child: FloatingActionButton(
            onPressed: onToggle,
            // Action principale : vert forêt en travail.
            backgroundColor: state.phase.isWork ? context.cq.vert : color,
            elevation: 0,
            shape: const CircleBorder(),
            heroTag: 'pomodoro-toggle',
            tooltip: state.isRunning ? 'Mettre en pause' : 'Démarrer',
            child: Icon(
              state.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: context.onAccent,
              size: size * 0.45,
            ),
          ),
        ),
        const SizedBox(width: Space.xl),
        IconButton(
          // Ce bouton était inerte (`onPressed: () {}`) : il passe désormais
          // réellement à la phase suivante, sans valider la session en cours.
          onPressed: onSkip,
          tooltip: 'Phase suivante',
          icon: Icon(Icons.skip_next,
              size: Sizes.iconLg, color: context.cq.textMuted),
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
    // Progression exacte : « 2 / 3 » pendant la 2e session ; pendant une
    // pause, le nombre de sessions déjà faites ; la pause longue clôt le
    // cycle (3 / 3).
    final (current, label) = switch (state.phase) {
      PomodoroPhase.work => (done + 1, 'Session'),
      PomodoroPhase.shortBreak => (done, 'Pause courte · sessions faites'),
      PomodoroPhase.longBreak => (cycle, 'Pause longue · cycle terminé'),
    };

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < cycle; i++)
              Container(
                width: Space.sm,
                height: Space.sm,
                margin: const EdgeInsets.symmetric(horizontal: Space.xs),
                decoration: BoxDecoration(
                  color: i < done ? color : context.cq.beigeDark,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Semantics(
          label: '$label : $current sur $cycle',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '$current / $cycle',
                style: TextStyle(
                  fontSize: TypeScale.bodyLarge,
                  fontWeight: FontWeight.w700,
                  color: context.cq.textPrimary,
                  fontFeatures: TypeScale.tabular,
                ),
              ),
              TextSpan(
                text: '   $label',
                style: TextStyle(
                    color: context.cq.textMuted, fontSize: TypeScale.caption),
              ),
            ]),
          ),
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
    final sessions = stats.sessionsToday;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              label: "Aujourd'hui",
              value: '$sessions session${sessions > 1 ? 's' : ''}',
              raised: true,
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: _StatTile(
              label: 'Cette semaine',
              value: '${formatFocusDuration(stats.focusThisWeek)} de focus',
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile compacte : libellé coloré (écorce sur la carte blanche, sauge sur
/// la tuile pierre), puis la valeur en gras.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.raised = false,
  });

  final String label;
  final String value;

  /// Carte blanche à filet plutôt que tuile pierre.
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: raised ? cq.cardColor : cq.sauge,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.lg, vertical: Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: TypeScale.caption,
                color: raised ? cq.terre : cq.vertSauge,
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              value,
              style: TextStyle(
                fontSize: TypeScale.bodyLarge,
                fontWeight: FontWeight.w700,
                color: cq.textPrimary,
                fontFeatures: TypeScale.tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
