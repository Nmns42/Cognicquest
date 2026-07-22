import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/habit_provider.dart';
import '../../../shared/models/task_model.dart';
import '../../../shared/models/habit_model.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  static String _formatDate(DateTime d) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    const days = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche',
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro   = ref.watch(pomodoroProvider);
    final tasksAsync = ref.watch(taskProvider);
    final habitsAsync = ref.watch(habitProvider);
    final user = Supabase.instance.client.auth.currentUser;

    final tasks  = tasksAsync.valueOrNull  ?? [];
    final habits = habitsAsync.valueOrNull ?? [];

    final doneTasks  = tasks.where((t) => t.status == 'done').length;
    final todoTasks  = tasks.where((t) => t.status == 'todo').take(3).toList();
    final doneHabits = habits.where((h) => h.completedToday).length;

    final firstName = user?.email?.split('@').first ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('CognicQuest'),
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Greeting
                _GreetingCard(
                  greeting: _greeting(),
                  name: firstName,
                  dateStr: _formatDate(DateTime.now()),
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.timer_outlined,
                        label: 'Sessions',
                        value: '${pomodoro.completedSessions}',
                        color: AppTheme.vert,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.task_alt_outlined,
                        label: 'Tâches',
                        value: tasks.isEmpty ? '—' : '$doneTasks/${tasks.length}',
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Habitudes',
                        value: habits.isEmpty ? '—' : '$doneHabits/${habits.length}',
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick start
                _QuickStartCard(onTap: () => context.go('/pomodoro')),
                const SizedBox(height: 28),

                // Tasks section
                _SectionRow(
                  title: 'À faire',
                  onMore: () => context.go('/kanban'),
                ),
                const SizedBox(height: 10),
                if (todoTasks.isEmpty)
                  _EmptySection(
                    icon: tasks.isEmpty
                        ? Icons.add_task
                        : Icons.celebration_outlined,
                    message: tasks.isEmpty
                        ? 'Ajoute tes premières tâches'
                        : 'Tout est fait pour l\'instant !',
                    onAction: tasks.isEmpty ? () => context.go('/kanban') : null,
                    actionLabel: 'Créer une tâche',
                  )
                else
                  ...todoTasks.map((t) => _TaskRow(task: t)),
                const SizedBox(height: 28),

                // Habits section
                _SectionRow(
                  title: 'Habitudes du jour',
                  onMore: () => context.go('/habits'),
                ),
                const SizedBox(height: 10),
                if (habits.isEmpty)
                  _EmptySection(
                    icon: Icons.check_circle_outline,
                    message: 'Crée tes premières habitudes',
                    onAction: () => context.go('/habits'),
                    actionLabel: 'Commencer',
                  )
                else
                  ...habits.take(5).map((h) => _HabitRow(habit: h)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Greeting ────────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  final String greeting;
  final String name;
  final String dateStr;

  const _GreetingCard({
    required this.greeting,
    required this.name,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.vert,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? '$greeting !' : '$greeting, $name !',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Start ─────────────────────────────────────────────────────────────

class _QuickStartCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickStartCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.vert.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.vert.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.vert,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Démarrer une session',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '25 min de focus · Pomodoro',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Row ─────────────────────────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  final String title;
  final VoidCallback onMore;

  const _SectionRow({required this.title, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        GestureDetector(
          onTap: onMore,
          child: const Text(
            'Voir tout',
            style: TextStyle(
              color: AppTheme.vert,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Task Row ─────────────────────────────────────────────────────────────────

class _TaskRow extends ConsumerWidget {
  final Task task;
  const _TaskRow({required this.task});

  Color get _dot {
    switch (task.priority) {
      case 'high':   return AppTheme.errorColor;
      case 'medium': return AppTheme.textMuted;
      default:       return AppTheme.vert;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            ref.read(taskProvider.notifier).updateStatus(task.id, 'done'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.beigeDark, width: 2),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _dot,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Habit Row ────────────────────────────────────────────────────────────────

class _HabitRow extends ConsumerWidget {
  final Habit habit;
  const _HabitRow({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => ref.read(habitProvider.notifier).toggleToday(habit),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: habit.completedToday ? AppTheme.vert : Colors.transparent,
                  border: Border.all(
                    color: habit.completedToday ? AppTheme.vert : AppTheme.beigeDark,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: habit.completedToday
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    decoration: habit.completedToday
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppTheme.textMuted,
                  ),
                ),
              ),
              if (habit.streak > 0)
                Text(
                  '🔥 ${habit.streak}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty Section ────────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _EmptySection({
    required this.icon,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.beigeDark.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textHint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ),
          if (onAction != null && actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: AppTheme.vert,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
