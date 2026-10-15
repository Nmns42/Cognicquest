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
              // Glisser-déposer pour réordonner (R2), synchronisé.
              : ReorderableListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  physics: const AlwaysScrollableScrollPhysics(),
                  header: Column(
                    children: [
                      _SummaryHeader(habits: habits),
                      const SizedBox(height: 20),
                    ],
                  ),
                  buildDefaultDragHandles: false,
                  onReorderItem: (from, to) => ref
                      .read(habitProvider.notifier)
                      .move(habits[from].id, to),
                  children: [
                    for (final (index, habit) in habits.indexed)
                      CqReorderableItem(
                        key: ValueKey(habit.id),
                        index: index,
                        child: _HabitTile(
                          habit: habit,
                          onToggle: () => ref
                              .read(habitProvider.notifier)
                              .toggleToday(habit),
                          onToggleDay: (day) => ref
                              .read(habitProvider.notifier)
                              .toggleOn(habit, day),
                          onEdit: () => _openEditor(habit: habit),
                          onDelete: () => _delete(habit),
                        ),
                      ),
                  ],
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

// ─── En-tête de synthèse ────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final doneToday = habits.where((h) => h.completedToday).length;
    final bestStreak =
        habits.fold<int>(0, (best, h) => h.streak > best ? h.streak : best);
    final averageConsistency = habits.isEmpty
        ? 0.0
        : habits.map((h) => h.successRateLast30Days).reduce((a, b) => a + b) /
            habits.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cq.vert,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$doneToday / ${habits.length} à jour',
            style: TextStyle(
              color: context.onAccent,
              fontSize: TypeScale.headline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            doneToday == habits.length
                ? 'Tout est validé pour la période en cours. Belle constance.'
                : 'Encore ${habits.length - doneToday} à valider '
                    '(jour, semaine ou mois selon l\'habitude).',
            style: TextStyle(
                color: context.cq.onVertMuted, fontSize: TypeScale.body),
          ),
          const SizedBox(height: 16),
          Row(
            // Flexible : à 200 % de texte, les deux stats passent à la ligne
            // au lieu de déborder.
            children: [
              Flexible(
                child: _MiniStat(
                  // Séries en jours, semaines ou mois : pas d'unité commune.
                  label: 'Meilleure série en cours',
                  value: '$bestStreak',
                ),
              ),
              const SizedBox(width: 24),
              Flexible(
                child: _MiniStat(
                  label: 'Régularité récente',
                  value: '${(averageConsistency * 100).round()} %',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
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
              color: context.cq.onVertMuted, fontSize: TypeScale.caption),
        ),
      ],
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
  });

  final Habit habit;
  final VoidCallback onToggle;
  final ValueChanged<DateTime> onToggleDay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                                isDone ? context.cq.vert : context.cq.beigeDark,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(Radii.md),
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
                        style: TextStyle(
                            fontSize: TypeScale.caption,
                            color: context.cq.textMuted),
                      ),
                    ],
                  ),
                ),
                // La série monte d'un cran. Toujours dans l'arbre (vide à
                // zéro) pour que le passage de 0 à 1 soit animé aussi.
                RollingNumber(
                  value: habit.streak,
                  builder: (context, streak) => streak == 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '🔥 $streak ${habit.frequency.shortUnit}',
                            style: TextStyle(
                              fontSize: TypeScale.body,
                              color: context.cq.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                PopupMenuButton<String>(
                  popUpAnimationStyle: Motion.style(context),
                  tooltip: 'Options',
                  icon: Icon(Icons.more_vert,
                      size: 18, color: context.cq.textMuted),
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
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
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 8),
              child: Row(
                children: [
                  // Sur un écran étroit (≤ 390 px) ou à 200 % de texte, les
                  // cases rétrécissent au lieu de déborder.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(children: cells),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
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
  });

  final String label;
  final String semanticLabel;
  final bool done;
  final bool isCurrent;

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
            decoration: BoxDecoration(
              color: done
                  ? context.cq.vert
                  : context.cq.beigeDark
                      .withValues(alpha: upcoming ? 0.25 : 0.6),
              borderRadius: BorderRadius.circular(Radii.md),
              border: isCurrent
                  ? Border.all(color: context.cq.vertDark, width: 1.6)
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: TypeScale.caption,
                fontWeight: FontWeight.w600,
                color: done
                    ? context.onAccent
                    : (upcoming ? context.cq.textHint : context.cq.textMuted),
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
