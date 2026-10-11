import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/habit_model.dart';
import '../providers/habit_provider.dart';

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
      backgroundColor: Colors.transparent,
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
        title: const Text('Supprimer cette habitude ?'),
        content: Text(
          '${habit.name}\n\nSon historique (${habit.totalCompletions} '
          'jour${habit.totalCompletions > 1 ? 's' : ''} validé'
          '${habit.totalCompletions > 1 ? 's' : ''}) sera perdu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text(
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
        loading: () =>  Center(
          child: CircularProgressIndicator(color: context.cq.vert),
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
                  style:  TextStyle(
                      color: context.cq.textMuted, fontSize: 14),
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
          color: context.cq.vert,
          onRefresh: () => ref.read(habitProvider.notifier).refresh(),
          child: habits.isEmpty
              ? const _EmptyHabits()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _SummaryHeader(habits: habits),
                    const SizedBox(height: 20),
                    for (final habit in habits)
                      _HabitTile(
                        habit: habit,
                        onToggle: () =>
                            ref.read(habitProvider.notifier).toggleToday(habit),
                        onToggleDay: (day) =>
                            ref.read(habitProvider.notifier).toggleOn(habit, day),
                        onEdit: () => _openEditor(habit: habit),
                        onDelete: () => _delete(habit),
                      ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle habitude',
        child: const Icon(Icons.add, color: Colors.white),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$doneToday / ${habits.length} aujourd\'hui',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            doneToday == habits.length
                ? 'Routine du jour bouclée. Belle constance.'
                : 'Encore ${habits.length - doneToday} à valider.',
            style:  TextStyle(color: context.cq.onVertMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Meilleure série',
                value: '$bestStreak j',
              ),
              const SizedBox(width: 24),
              _MiniStat(
                label: 'Régularité 30 j',
                value: '${(averageConsistency * 100).round()} %',
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style:  TextStyle(color: context.cq.onVertMuted, fontSize: 11),
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

  @override
  Widget build(BuildContext context) {
    final isDone = habit.completedToday;
    final today = DateTime.now();

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
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: AnimatedContainer(
                      duration: Motion.duration(context, const Duration(milliseconds: 200)),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone ? context.cq.vert : Colors.transparent,
                        border: Border.all(
                          color: isDone ? context.cq.vert : context.cq.beigeDark,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
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
                          fontSize: 15,
                          color: context.cq.textPrimary,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          decorationColor: context.cq.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        habit.frequency.label,
                        style:  TextStyle(
                            fontSize: 11, color: context.cq.textMuted),
                      ),
                    ],
                  ),
                ),
                if (habit.streak > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '🔥 ${habit.streak}',
                      style:  TextStyle(
                        fontSize: 13,
                        color: context.cq.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  popUpAnimationStyle: Motion.style(context),
                  tooltip: 'Options',
                  icon:  Icon(Icons.more_vert,
                      size: 18, color: context.cq.textMuted),
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) =>  [
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
            // Grille des 7 derniers jours — CdC : « Tableau visuel de
            // progression (cases cochées par jour) ». Chaque case est
            // cliquable : on peut rattraper un oubli de la veille.
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 6; i >= 0; i--)
                    _DayCell(
                      initial: _dayInitials[
                          today.subtract(Duration(days: i)).weekday - 1],
                      done: habit.isCompletedOn(today.subtract(Duration(days: i))),
                      isToday: i == 0,
                      onTap: () =>
                          onToggleDay(today.subtract(Duration(days: i))),
                    ),
                  const Spacer(),
                  Text(
                    '${(habit.successRateLast30Days * 100).round()} %',
                    style:  TextStyle(
                      fontSize: 12,
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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.initial,
    required this.done,
    required this.isToday,
    required this.onTap,
  });

  final String initial;
  final bool done;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: Motion.duration(context, const Duration(milliseconds: 180)),
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done
                ? context.cq.vert
                : context.cq.beigeDark.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: context.cq.vertDark, width: 1.6)
                : null,
          ),
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: done ? Colors.white : context.cq.textMuted,
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
         Icon(Icons.check_circle_outline,
            size: 48, color: context.cq.textHint),
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration:  BoxDecoration(
          color: context.cq.beige,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    borderRadius: BorderRadius.circular(2),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.cq.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<HabitFrequency>(
                segments: [
                  for (final frequency in HabitFrequency.values)
                    ButtonSegment(value: frequency, label: Text(frequency.label)),
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
