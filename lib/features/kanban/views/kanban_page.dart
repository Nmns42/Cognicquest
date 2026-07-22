import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/task_provider.dart';
import '../../../shared/models/task_model.dart';

class KanbanPage extends ConsumerWidget {
  const KanbanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes tâches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTask(context, ref),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erreur : $e')),
        data:    (tasks) => _KanbanBoard(tasks: tasks),
      ),
    );
  }

  void _showAddTask(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String priority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F0E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nouvelle tâche',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Titre de la tâche'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Priorité',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PriorityChip(
                        label: 'Basse',
                        value: 'low',
                        selected: priority == 'low',
                        color: const Color(0xFF7A9E7E),
                        onTap: () => setState(() => priority = 'low'),
                      ),
                      const SizedBox(width: 8),
                      _PriorityChip(
                        label: 'Moyenne',
                        value: 'medium',
                        selected: priority == 'medium',
                        color: const Color(0xFFBA7517),
                        onTap: () => setState(() => priority = 'medium'),
                      ),
                      const SizedBox(width: 8),
                      _PriorityChip(
                        label: 'Haute',
                        value: 'high',
                        selected: priority == 'high',
                        color: const Color(0xFFD85A30),
                        onTap: () => setState(() => priority = 'high'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      ref.read(taskProvider.notifier).addTask(
                        title:    titleController.text.trim(),
                        priority: priority,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _KanbanBoard extends ConsumerWidget {
  final List<Task> tasks;
  const _KanbanBoard({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = [
      ('todo',    'À faire',   Icons.radio_button_unchecked),
      ('doing',   'En cours',  Icons.timelapse_rounded),
      ('done',    'Terminé',   Icons.check_circle_outline),
    ];

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      children: columns.map((col) {
        final colTasks = tasks.where((t) => t.status == col.$1).toList();
        return _KanbanColumn(
          status:   col.$1,
          title:    col.$2,
          icon:     col.$3,
          tasks:    colTasks,
          allTasks: tasks,
        );
      }).toList(),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final String     status;
  final String     title;
  final IconData   icon;
  final List<Task> tasks;
  final List<Task> allTasks;

  const _KanbanColumn({
    required this.status,
    required this.title,
    required this.icon,
    required this.tasks,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header colonne
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF6B6B68)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF2C2C2A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8CFC2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B6B68),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tâches
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, i) => _TaskCard(
                task: tasks[i],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final Task task;
  const _TaskCard({required this.task});

  Color get _priorityColor {
    switch (task.priority) {
      case 'high':   return const Color(0xFFD85A30);
      case 'medium': return const Color(0xFFBA7517);
      default:       return const Color(0xFF7A9E7E);
    }
  }

  String get _priorityLabel {
    switch (task.priority) {
      case 'high':   return 'Haute';
      case 'medium': return 'Moyenne';
      default:       return 'Basse';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF2C2C2A),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 18),
                  onSelected: (value) {
                    if (value == 'delete') {
                      ref.read(taskProvider.notifier).deleteTask(task.id);
                    } else {
                      ref.read(taskProvider.notifier).updateStatus(task.id, value);
                    }
                  },
                  itemBuilder: (_) => [
                    if (task.status != 'todo')
                      const PopupMenuItem(value: 'todo',  child: Text('À faire')),
                    if (task.status != 'doing')
                      const PopupMenuItem(value: 'doing', child: Text('En cours')),
                    if (task.status != 'done')
                      const PopupMenuItem(value: 'done',  child: Text('Terminé')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _priorityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _priorityLabel,
                style: TextStyle(
                  color: _priorityColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String   label;
  final String   value;
  final bool     selected;
  final Color    color;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: selected ? color : const Color(0xFFD8CFC2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : const Color(0xFF6B6B68),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
