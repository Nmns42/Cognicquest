import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/habit_provider.dart';
import '../../../shared/models/habit_model.dart';

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes habitudes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabit(context, ref),
        backgroundColor: AppTheme.vert,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.read(habitProvider.notifier).loadHabits(),
        ),
        data: (habits) {
          if (habits.isEmpty) {
            return _EmptyState(onAdd: () => _showAddHabit(context, ref));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: habits.length,
            itemBuilder: (context, i) => _HabitCard(habit: habits[i]),
          );
        },
      ),
    );
  }

  void _showAddHabit(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.beige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nouvelle habitude',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex: Réviser 30 min, Méditer, Lire...',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                ref.read(habitProvider.notifier).addHabit(name);
                Navigator.pop(context);
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  const _HabitCard({required this.habit});

  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.beige,
          title: const Text('Supprimer cette habitude ?'),
          content: Text('"${habit.name}" et tout son historique seront supprimés.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Supprimer',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => ref.read(habitProvider.notifier).deleteHabit(habit.id),
      child: GestureDetector(
        onTap: () => ref.read(habitProvider.notifier).toggleToday(habit),
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Checkbox(checked: habit.completedToday),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                          decoration: habit.completedToday
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    if (habit.streak > 0) _StreakBadge(streak: habit.streak),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(7, (i) {
                    final done = habit.last7Days[i];
                    final isToday = i == 6;
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            _dayLabels[(DateTime.now()
                                        .subtract(Duration(days: 6 - i))
                                        .weekday -
                                    1) %
                                7],
                            style: TextStyle(
                              fontSize: 10,
                              color: isToday
                                  ? AppTheme.vert
                                  : AppTheme.textHint,
                              fontWeight: isToday
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: isToday ? 14 : 10,
                            height: isToday ? 14 : 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done ? AppTheme.vert : AppTheme.beigeDark,
                              border: isToday && !done
                                  ? Border.all(color: AppTheme.vert, width: 1.5)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  const _Checkbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? AppTheme.vert : Colors.transparent,
        border: Border.all(
          color: checked ? AppTheme.vert : AppTheme.beigeDark,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: checked
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : null,
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD85A30).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '$streak',
            style: const TextStyle(
              color: Color(0xFFD85A30),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.beigeDark,
            ),
            const SizedBox(height: 20),
            Text(
              'Pas encore d\'habitudes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Crée ta première habitude pour suivre ta progression au quotidien.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Créer une habitude'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: AppTheme.beigeDark),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger les habitudes',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
