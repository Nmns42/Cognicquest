import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/micro_animations.dart';
import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  Future<void> _openEditor({Habit? habit}) async {
    final result = await showModalBottomSheet<_HabitDraft>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      builder: (_) => _HabitEditorSheet(habit: habit),
    );
    if (result == null) return;

    final notifier = ref.read(habitProvider.notifier);
    if (habit == null) {
      await notifier.addHabit(result.name, frequency: result.frequency);
    } else {
      await notifier.renameHabit(habit, result.name, result.frequency);
    }
  }

  Future<void> _delete(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: Motion.style(context),
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Supprimer cette habitude ?'),
        content: Text(
          '${habit.name}\n\nSon historique (${habit.totalCompletions} '
          '${habit.frequency.unit(habit.totalCompletions)} validé'
          '${habit.frequency == HabitFrequency.weekly ? 'e' : ''}'
          '${habit.totalCompletions > 1 ? 's' : ''}) sera perdu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: TextStyle(color: context.cq.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(habitProvider.notifier).deleteHabit(habit.id);
    }
  }

  /// Largeur à partir de laquelle les habitudes passent en grille, avec le
  /// panneau « Arbre de détente » à droite.
  static const double _wideLayoutMin = 900;
  static const double _panelWidth = 300;

  Widget _tile(List<Habit> habits, int index, {required bool grid}) {
    final habit = habits[index];
    final notifier = ref.read(habitProvider.notifier);
    return _HabitTile(
      habit: habit,
      grid: grid,
      onToggle: () => notifier.toggleToday(habit),
      onToggleDay: (day) => notifier.toggleOn(habit, day),
      onEdit: () => _openEditor(habit: habit),
      onDelete: () => _delete(habit),
      // En grille, pas de glisser-déposer : on déplace par le menu.
      onMoveBefore: grid && index > 0
          ? () => notifier.move(habit.id, index - 1)
          : null,
      onMoveAfter: grid && index < habits.length - 1
          ? () => notifier.move(habit.id, index + 1)
          : null,
    );
  }

  /// Téléphone et écran moyen : liste réordonnable par glisser-déposer (R2).
  Widget _narrowLayout(List<Habit> habits) {
    return ReorderableListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      header: Column(
        children: [
          _HeroBanner(habits: habits),
          const SizedBox(height: 20),
        ],
      ),
      buildDefaultDragHandles: false,
      onReorderItem: (from, to) =>
          ref.read(habitProvider.notifier).move(habits[from].id, to),
      children: [
        for (final (index, habit) in habits.indexed)
          CqReorderableItem(
            key: ValueKey(habit.id),
            index: index,
            child: _tile(habits, index, grid: false),
          ),
      ],
    );
  }

  /// Grand écran : bannière et grille de cartes, panneau de détente à
  /// droite.
  Widget _wideLayout(List<Habit> habits) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                Space.xl, Space.xl, Space.lg, Space.xxxl * 2),
            children: [
              _HeroBanner(habits: habits),
              const SizedBox(height: Space.xl),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 3 : 2;
                final width = (constraints.maxWidth -
                        Space.lg * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: Space.lg,
                  runSpacing: Space.lg,
                  children: [
                    for (final (index, habit) in habits.indexed)
                      SizedBox(
                        key: ValueKey(habit.id),
                        width: width,
                        child: _tile(habits, index, grid: true),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
        SizedBox(width: _panelWidth, child: _MindfulPanel(habits: habits)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitProvider);

    ref.listen(habitProvider, (previous, next) {
      final error = next.error;
      if (error != null && next.hasValue) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(error.toString())),
            snackBarAnimationStyle: Motion.style(context),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Tracker d'habitudes")),
      body: habitsAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => Center(
          child: CircularProgressIndicator(color: context.cq.vertDark),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 44, color: context.cq.textHint),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: context.cq.textMuted, fontSize: TypeScale.body),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => ref.read(habitProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (habits) => RefreshIndicator(
          color: context.cq.vertDark,
          onRefresh: () => ref.read(habitProvider.notifier).refresh(),
          child: habits.isEmpty
              ? const _EmptyHabits()
              : LayoutBuilder(
                  builder: (context, constraints) =>
                      constraints.maxWidth >= _wideLayoutMin
                          ? _wideLayout(habits)
                          : _narrowLayout(habits),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle habitude',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

// ─── Bannière ───────────────────────────────────────────────────────────────

/// Bannière bi-ton : le bilan sur le vert forêt, un bouquet de feuillage à
/// droite, et une bande plus sombre de trois chiffres séparés par des
/// filets.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.habits});

  final List<Habit> habits;

  /// En dessous, le feuillage gênerait la lecture du titre : il disparaît.
  static const double _foliageMin = 520;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final doneToday = habits.where((h) => h.completedToday).length;
    final allDone = doneToday == habits.length;
    final bestStreak =
        habits.fold<int>(0, (best, h) => h.streak > best ? h.streak : best);
    final averageConsistency = _averageConsistency(habits);
    final radius = BorderRadius.circular(Radii.card);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [context.chrome.shadow],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: cq.vert,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final foliage = constraints.maxWidth >= _foliageMin;
                final foliageWidth = math.min(constraints.maxWidth * 0.4, 300.0);
                return ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: foliage ? Space.xxxl * 3.5 : 0),
                  child: Stack(
                    children: [
                      if (foliage)
                        Positioned(
                          right: Space.lg,
                          top: Space.md,
                          bottom: 0,
                          width: foliageWidth,
                          child: const HeroFoliageOverlay(),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(Space.xl, Space.xl,
                            foliage ? foliageWidth + Space.xl : Space.xl,
                            Space.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$doneToday / ${habits.length} à jour —\n'
                              '${allDone ? 'Belle constance !' : 'Continue sur ta lancée !'}',
                              style: TextStyle(
                                color: context.onAccent,
                                fontSize: TypeScale.headline,
                                fontWeight: FontWeight.w700,
                                height: TypeScale.titleHeight,
                                letterSpacing: TypeScale.tracking(
                                    TypeScale.headline, TypeScale.titleEm),
                              ),
                            ),
                            const SizedBox(height: Space.sm),
                            Text(
                              allDone
                                  ? 'Tout est validé pour la période en cours.'
                                  : 'Encore ${habits.length - doneToday} à '
                                      "valider (jour, semaine ou mois selon "
                                      "l'habitude).",
                              style: TextStyle(
                                  color: cq.onVertMuted,
                                  fontSize: TypeScale.body),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              ColoredBox(
                color: cq.vertLip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.xl, vertical: Space.lg),
                  child: _HeroStats(
                    stats: [
                      _HeroStat(
                        leading: const LaurelStreakBadge(),
                        // Séries en jours, semaines ou mois : pas d'unité
                        // commune.
                        value: '$bestStreak',
                        label: 'Meilleure série en cours',
                      ),
                      _HeroStat(
                        value: '${(averageConsistency * 100).round()} %',
                        label: 'Régularité récente',
                      ),
                      _HeroStat(
                        value: '${habits.length}',
                        label: 'Habitudes suivies',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _averageConsistency(List<Habit> habits) => habits.isEmpty
    ? 0.0
    : habits.map((h) => h.successRateLast30Days).reduce((a, b) => a + b) /
        habits.length;

/// Chiffres de la bande sombre : en colonnes séparées de filets verticaux,
/// ou empilés sur un écran étroit (et à 200 % de texte).
class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.stats});

  final List<_HeroStat> stats;

  static const double _columnsMin = 560;

  @override
  Widget build(BuildContext context) {
    final rule = context.cq.onVertMuted.withValues(alpha: 0.3);
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < _columnsMin) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, stat) in stats.indexed) ...[
              if (i > 0)
                Divider(
                    height: Space.lg, thickness: Borders.thin, color: rule),
              stat,
            ],
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, stat) in stats.indexed) ...[
              if (i > 0)
                VerticalDivider(
                    width: Space.xl, thickness: Borders.thin, color: rule),
              Expanded(child: stat),
            ],
          ],
        ),
      );
    });
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label, this.leading});

  final String value;
  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: Space.md)],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: context.onAccent,
                  fontSize: TypeScale.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                    color: context.cq.onVertMuted,
                    fontSize: TypeScale.caption),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Panneau « Arbre de détente » ───────────────────────────────────────────

/// Panneau latéral (grand écran) : l'arbre compagnon, qui grandit avec la
/// régularité, et des rappels métacognitifs.
class _MindfulPanel extends StatelessWidget {
  const _MindfulPanel({required this.habits});

  final List<Habit> habits;

  static const List<(IconData, String)> _reminders = [
    (Icons.self_improvement_outlined,
        'Avant de commencer, pose une intention claire pour la séance.'),
    (Icons.psychology_alt_outlined,
        "Qu'est-ce qui t'a aidé hier ? Refais-le aujourd'hui."),
    (Icons.spa_outlined,
        "Une pause de 5 minutes consolide ce que tu viens d'apprendre."),
  ];

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final growth = _averageConsistency(habits);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, Space.xl, Space.xl, Space.xl),
      child: DecoratedBox(
        decoration:
            context.chrome.decoration(color: cq.cardColor, radius: Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Arbre de détente',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Space.sm),
              AspectRatio(
                aspectRatio: 1,
                child: MindfulTreeIllustration(growth: growth),
              ),
              Text(
                'Il grandit avec ta régularité : '
                '${(growth * 100).round()} % sur 30 jours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: TypeScale.caption, color: cq.textMuted),
              ),
              const SizedBox(height: Space.lg),
              for (final (icon, text) in _reminders)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cq.sauge,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Space.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: Sizes.iconMd, color: cq.vertSauge),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                  fontSize: TypeScale.caption,
                                  color: cq.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tuile d'habitude ───────────────────────────────────────────────────────

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.onToggle,
    required this.onToggleDay,
    required this.onEdit,
    required this.onDelete,
    this.grid = false,
    this.onMoveBefore,
    this.onMoveAfter,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final ValueChanged<DateTime> onToggleDay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Carte d'une grille : pas de marge basse (la grille espace les cartes).
  final bool grid;

  /// Déplacement par le menu (grille, sans glisser-déposer).
  final VoidCallback? onMoveBefore;
  final VoidCallback? onMoveAfter;

  static const List<String> _dayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const List<String> _dayNames = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche',
  ];
  static const List<String> _monthInitials = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
  ];
  static const List<String> _monthNames = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
    'septembre', 'octobre', 'novembre', 'décembre',
  ];

  /// Cases de la période, selon la fréquence, et leur total.
  ///
  /// - Quotidienne : les 7 jours de la semaine en cours (L → D), « 5/7 cette
  ///   semaine ».
  /// - Hebdomadaire : les 4 semaines du mois, chacune validée dès qu'un jour
  ///   y est coché, « 2/4 ce mois ».
  /// - Mensuelle : les 12 mois de l'année (J → D), « 3/12 cette année ».
  ///
  /// Chaque case passée ou en cours se coche et se décoche (rattrapage d'un
  /// oubli) ; les cases à venir sont grisées.
  (List<Widget>, String) _periodCells(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (habit.frequency) {
      case HabitFrequency.daily:
        final days = Habit.currentWeekDays(now);
        return (
          [
            for (final (i, day) in days.indexed)
              _PeriodCell(
                label: _dayInitials[i],
                semanticLabel: _dayNames[i],
                index: i,
                checkWhenDone: true,
                done: habit.isCompletedOn(day),
                isCurrent: day == today,
                onTap: day.isAfter(today) ? null : () => onToggleDay(day),
              ),
          ],
          '${habit.doneThisWeek}/7 cette semaine',
        );
      case HabitFrequency.weekly:
        final current = Habit.weekOfMonth(now);
        final done = [
          for (var week = 1; week <= 4; week++)
            habit.isWeekDone(now.year, now.month, week),
        ];
        return (
          [
            for (var week = 1; week <= 4; week++)
              _PeriodCell(
                index: week - 1,
                label: 'Sem. $week',
                semanticLabel: 'Semaine $week du mois',
                done: done[week - 1],
                isCurrent: week == current,
                onTap: week > current
                    ? null
                    : () => onToggleDay(
                        Habit.startOfWeekOfMonth(now.year, now.month, week)),
              ),
          ],
          '${done.where((d) => d).length}/4 ce mois',
        );
      case HabitFrequency.monthly:
        final done = [
          for (var month = 1; month <= 12; month++)
            habit.isMonthDone(now.year, month),
        ];
        return (
          [
            for (var month = 1; month <= 12; month++)
              _PeriodCell(
                index: month - 1,
                label: _monthInitials[month - 1],
                semanticLabel: _monthNames[month - 1],
                done: done[month - 1],
                isCurrent: month == now.month,
                onTap: month > now.month
                    ? null
                    : () => onToggleDay(DateTime(now.year, month)),
              ),
          ],
          '${done.where((d) => d).length}/12 cette année',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = habit.completedToday;
    final (cells, total) = _periodCells(DateTime.now());

    // Carte crème au relief feutré : ombre portée douce sous la `Card`.
    final card = Card(
      margin: EdgeInsets.zero,
      shape: context.cardShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    // Micro-animation n° 1 : la coche rebondit quand
                    // l'habitude devient faite (pas quand on la décoche).
                    child: PulseOnChange(
                      trigger: isDone,
                      enabled: isDone,
                      scale: 1.2,
                      child: AnimatedContainer(
                        duration: Motion.duration(
                            context, const Duration(milliseconds: 200)),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone ? context.cq.vert : Colors.transparent,
                          border: Border.all(
                            color:
                                isDone ? context.cq.vert : context.cq.textHint,
                            width: 2,
                          ),
                          // Case ronde, comme la maquette.
                          shape: BoxShape.circle,
                        ),
                        child: isDone
                            ? Icon(Icons.check,
                                size: 16, color: context.onAccent)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: TypeScale.bodyLarge,
                          color: context.cq.textPrimary,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          decorationColor: context.cq.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        habit.frequency.label,
                        // Métadonnée chaleureuse : la terre répond au vert.
                        style: TextStyle(
                            fontSize: TypeScale.caption,
                            color: context.cq.terre),
                      ),
                    ],
                  ),
                ),
                // Pastille de série, en haut à droite : sauge si l'habitude
                // est à jour, écorce sinon. Le chiffre monte d'un cran.
                RollingNumber(
                  value: habit.streak,
                  builder: (context, streak) => _ScoreBadge(
                    value: streak,
                    unit: habit.frequency.shortUnit,
                    upToDate: isDone,
                  ),
                ),
                PopupMenuButton<String>(
                  popUpAnimationStyle: Motion.style(context),
                  tooltip: 'Options',
                  icon: Icon(Icons.more_vert,
                      size: 18, color: context.cq.textMuted),
                  onSelected: (value) => switch (value) {
                    'edit' => onEdit(),
                    'before' => onMoveBefore?.call(),
                    'after' => onMoveAfter?.call(),
                    _ => onDelete(),
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    if (onMoveBefore != null)
                      const PopupMenuItem(
                          value: 'before', child: Text('Déplacer avant')),
                    if (onMoveAfter != null)
                      const PopupMenuItem(
                          value: 'after', child: Text('Déplacer après')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer',
                          style: TextStyle(color: context.cq.errorColor)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tableau de progression — CdC : « cases cochées par jour » —
            // adapté à la fréquence (jours, semaines du mois ou mois).
            // Cases sur toute la largeur, total dessous : les cases gardent
            // leur taille sur un téléphone et dans une carte de grille.
            Padding(
              padding: EdgeInsets.only(left: grid ? Space.xs : 36, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // À 200 % de texte ou sur un écran très étroit, les cases
                  // rétrécissent au lieu de déborder.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(children: cells),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    total,
                    style: TextStyle(
                      fontSize: TypeScale.caption,
                      color: context.cq.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: grid ? 0 : Space.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.card),
          boxShadow: [context.chrome.shadow],
        ),
        child: card,
      ),
    );
  }
}

/// Pastille circulaire de la série en cours.
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.value,
    required this.unit,
    required this.upToDate,
  });

  final int value;
  final String unit;
  final bool upToDate;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Semantics(
      label: 'Série : $value $unit',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(
            minWidth: Sizes.iconXl + Space.xs, minHeight: Sizes.iconXl + Space.xs),
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: upToDate ? cq.vertSauge : cq.terre,
          // Cercle pour un ou deux chiffres, pastille au-delà.
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
              color: cq.beige.withValues(alpha: 0.5), width: Borders.focus),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: TypeScale.body,
            fontWeight: FontWeight.w700,
            // Le fond de l'app tient ≥ 4,5:1 sur la sauge et l'écorce.
            color: cq.beige,
          ),
        ),
      ),
    );
  }
}

/// Case d'une période (jour, semaine ou mois) : pleine si validée, cerclée
/// si c'est la période en cours, grisée et inactive si elle est à venir.
class _PeriodCell extends StatelessWidget {
  const _PeriodCell({
    required this.label,
    required this.semanticLabel,
    required this.done,
    required this.isCurrent,
    required this.onTap,
    required this.index,
    this.checkWhenDone = false,
  });

  final String label;
  final String semanticLabel;
  final bool done;
  final bool isCurrent;

  /// Rang dans la rangée : les cases faites alternent sauge et écorce.
  final int index;

  /// Case faite : une coche au lieu du libellé (jours).
  final bool checkWhenDone;

  /// `null` pour une période à venir.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final upcoming = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        label: semanticLabel,
        checked: done,
        enabled: !upcoming,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: AnimatedContainer(
            duration:
                Motion.duration(context, const Duration(milliseconds: 180)),
            constraints: const BoxConstraints(minWidth: 26),
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            // Pastille (semaines, mois) ou cercle (jours) : fait en vert
            // profond, à faire en sable, période en cours en kaki cerclé.
            decoration: BoxDecoration(
              color: done
                  ? (index.isOdd ? context.cq.terre : context.cq.vertSauge)
                  : (isCurrent
                      ? context.cq.textHint.withValues(alpha: 0.3)
                      : context.cq.beigeDark
                          .withValues(alpha: upcoming ? 0.5 : 1)),
              borderRadius: BorderRadius.circular(Radii.card),
              border: isCurrent
                  ? Border.all(color: context.cq.vertLip, width: Borders.focus)
                  : null,
            ),
            child: done && checkWhenDone
                ? Icon(Icons.check, size: Sizes.iconSm, color: context.cq.beige)
                : Text(
              label,
              style: TextStyle(
                fontSize: TypeScale.caption,
                fontWeight: FontWeight.w600,
                color: done
                    ? context.cq.beige
                    : (isCurrent
                        ? context.cq.textPrimary
                        : (upcoming
                            ? context.cq.textHint
                            : context.cq.textMuted)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Icon(Icons.check_circle_outline, size: 48, color: context.cq.textHint),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Aucune habitude pour l\'instant.\n'
            'Commence par une seule routine non négociable.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.cq.textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ─── Éditeur ────────────────────────────────────────────────────────────────

class _HabitDraft {
  const _HabitDraft(this.name, this.frequency);

  final String name;
  final HabitFrequency frequency;
}

class _HabitEditorSheet extends StatefulWidget {
  const _HabitEditorSheet({this.habit});

  final Habit? habit;

  @override
  State<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<_HabitEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
      TextEditingController(text: widget.habit?.name ?? '');
  late HabitFrequency _frequency =
      widget.habit?.frequency ?? HabitFrequency.daily;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _HabitDraft(_controller.text.trim(), _frequency),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(Radii.md)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.cq.beigeDark,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.habit == null
                    ? 'Nouvelle habitude'
                    : 'Modifier l\'habitude',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _controller,
                autofocus: widget.habit == null,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Ex : Méditation (10 min)',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Donne un nom à ton habitude.'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 18),
              Text(
                'Fréquence',
                style: TextStyle(
                  fontSize: TypeScale.body,
                  fontWeight: FontWeight.w600,
                  color: context.cq.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<HabitFrequency>(
                segments: [
                  for (final frequency in HabitFrequency.values)
                    ButtonSegment(
                        value: frequency, label: Text(frequency.label)),
                ],
                selected: {_frequency},
                showSelectedIcon: false,
                onSelectionChanged: (values) =>
                    setState(() => _frequency = values.first),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.habit == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
