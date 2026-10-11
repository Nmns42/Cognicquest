import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_editor_sheet.dart';

enum _BoardView { kanban, eisenhower }

class KanbanPage extends ConsumerStatefulWidget {
  const KanbanPage({super.key});

  @override
  ConsumerState<KanbanPage> createState() => _KanbanPageState();
}

class _KanbanPageState extends ConsumerState<KanbanPage> {
  _BoardView _view = _BoardView.kanban;

  Future<void> _createTask({TaskStatus? status}) async {
    final draft = await TaskEditorSheet.show(context, initialStatus: status);
    if (draft == null) return;

    await ref.read(taskProvider.notifier).addTask(
          draft.title,
          description: draft.description,
          priority: draft.priority,
          status: draft.status,
          dueDate: draft.dueDate,
          isUrgent: draft.isUrgent,
          isImportant: draft.isImportant,
        );
  }

  Future<void> _editTask(Task task) async {
    final draft = await TaskEditorSheet.show(context, task: task);
    if (draft == null) return;

    await ref.read(taskProvider.notifier).updateTask(
          task.copyWith(
            title: draft.title,
            description: draft.description,
            priority: draft.priority,
            status: draft.status,
            dueDate: draft.dueDate,
            clearDueDate: draft.dueDate == null,
            isUrgent: draft.isUrgent,
            isImportant: draft.isImportant,
          ),
        );
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: Motion.style(context),
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette tâche ?'),
        content: Text(task.title),
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
      await ref.read(taskProvider.notifier).deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskProvider);

    // Une erreur d'écriture ne doit pas effacer le tableau : on la signale en
    // SnackBar et on continue d'afficher les données précédentes.
    ref.listen(taskProvider, (previous, next) {
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
      appBar: AppBar(
        title: const Text('Mes tâches'),
        actions: [
          IconButton(
            tooltip: _view == _BoardView.kanban
                ? 'Voir la matrice d\'Eisenhower'
                : 'Voir le tableau Kanban',
            icon: Icon(
              _view == _BoardView.kanban
                  ? Icons.grid_view_outlined
                  : Icons.view_kanban_outlined,
            ),
            onPressed: () => setState(
              () => _view = _view == _BoardView.kanban
                  ? _BoardView.eisenhower
                  : _BoardView.kanban,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: tasksAsync.when(
        skipLoadingOnRefresh: true,
        loading: () =>  Center(
          child: CircularProgressIndicator(color: context.cq.vert),
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(taskProvider.notifier).refresh(),
        ),
        data: (tasks) => RefreshIndicator(
          color: context.cq.vert,
          onRefresh: () => ref.read(taskProvider.notifier).refresh(),
          child: _view == _BoardView.kanban
              ? _KanbanBoard(onEdit: _editTask, onDelete: _deleteTask, onAdd: _createTask)
              : _EisenhowerBoard(onEdit: _editTask, onDelete: _deleteTask),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle tâche',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Tableau Kanban ─────────────────────────────────────────────────────────

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final void Function({TaskStatus? status}) onAdd;

  @override
  Widget build(BuildContext context) {
    final columns = [
      for (final status in TaskStatus.values)
        _KanbanColumn(
          status: status,
          onEdit: onEdit,
          onDelete: onDelete,
          onAdd: () => onAdd(status: status),
        ),
    ];

    // Sur écran large (web, tablette, desktop — la cible principale du CdC),
    // les trois colonnes sont côte à côte comme dans Trello ; sur mobile elles
    // s'empilent.
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: SingleChildScrollView(child: columns[i])),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: columns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) => columns[index],
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  const _KanbanColumn({
    required this.status,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final TaskStatus status;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final VoidCallback onAdd;

  (IconData, Color) _style(BuildContext context) => switch (status) {
        TaskStatus.todo => (Icons.circle_outlined, context.cq.textHint),
        TaskStatus.doing => (Icons.timelapse, context.cq.vert),
        TaskStatus.done => (Icons.check_circle, context.cq.textMuted),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksByStatusProvider(status));
    final (icon, color) = _style(context);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) => ref
          .read(taskProvider.notifier)
          .moveTask(details.data.id, status),
      builder: (context, candidate, __) {
        final isHovered = candidate.isNotEmpty;

        return AnimatedContainer(
          duration: Motion.duration(context, const Duration(milliseconds: 160)),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: isHovered ? context.cq.vert : context.cq.beigeDark,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(status.label,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.cq.beigeDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style:  TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.cq.textMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Ajouter dans « ${status.label} »',
                    visualDensity: VisualDensity.compact,
                    onPressed: onAdd,
                    icon:  Icon(Icons.add, size: 20,
                        color: context.cq.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                _EmptyColumn(isHovered: isHovered)
              else
                for (var i = 0; i < tasks.length; i++)
                  _DraggableTask(
                    task: tasks[i],
                    index: i,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Carte déplaçable, avec une zone de dépôt au-dessus d'elle pour permettre le
/// réordonnancement fin à l'intérieur d'une colonne.
class _DraggableTask extends ConsumerWidget {
  const _DraggableTask({
    required this.task,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final int index;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = TaskCard(
      task: task,
      onTap: () => onEdit(task),
      onToggleDone: () => ref.read(taskProvider.notifier).toggleDone(task.id),
    );

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.id != task.id,
      onAcceptWithDetails: (details) => ref
          .read(taskProvider.notifier)
          .moveTask(details.data.id, task.status, targetIndex: index),
      builder: (context, candidate, __) {
        return Column(
          children: [
            if (candidate.isNotEmpty)
              Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: context.cq.vert,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            LongPressDraggable<Task>(
              data: task,
              delay: const Duration(milliseconds: 180),
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 300,
                  child: Opacity(opacity: 0.9, child: card),
                ),
              ),
              childWhenDragging: TaskCard(
                task: task,
                isDragging: true,
                onTap: () {},
                onToggleDone: () {},
              ),
              child: Dismissible(
                key: ValueKey(task.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  onDelete(task);
                  // La suppression effective passe par le provider : on ne
                  // laisse jamais Dismissible retirer la carte de sa propre
                  // autorité, sinon l'UI diverge de l'état réel.
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: context.cq.errorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child:  Icon(Icons.delete_outline,
                      color: context.cq.errorColor),
                ),
                child: card,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.isHovered});

  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: context.cq.beigeDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isHovered ? 'Déposer ici' : 'Aucune tâche',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHovered ? context.cq.vert : context.cq.textMuted,
          fontSize: 13,
          fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─── Matrice d'Eisenhower ───────────────────────────────────────────────────

class _EisenhowerBoard extends StatelessWidget {
  const _EisenhowerBoard({required this.onEdit, required this.onDelete});

  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  static Map<EisenhowerQuadrant, Color> _colorsOf(BuildContext context) => {
        EisenhowerQuadrant.doNow: context.cq.errorColor,
        EisenhowerQuadrant.schedule: context.cq.vert,
        EisenhowerQuadrant.delegate: context.cq.warning,
        EisenhowerQuadrant.eliminate: context.cq.textHint,
      };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    const quadrants = EisenhowerQuadrant.values;

    final tiles = [
      for (final quadrant in quadrants)
        _QuadrantTile(
          quadrant: quadrant,
          color: _colorsOf(context)[quadrant]!,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
    ];

    if (!isWide) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, index) => tiles[index],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[row * 2]),
                  const SizedBox(width: 14),
                  Expanded(child: tiles[row * 2 + 1]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuadrantTile extends ConsumerWidget {
  const _QuadrantTile({
    required this.quadrant,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final EisenhowerQuadrant quadrant;
  final Color color;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksByQuadrantProvider(quadrant));

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.quadrant != quadrant,
      onAcceptWithDetails: (details) {
        // Déposer une carte dans un quadrant réécrit ses drapeaux urgent /
        // important : la matrice est éditable, pas seulement consultable.
        final isUrgent = quadrant == EisenhowerQuadrant.doNow ||
            quadrant == EisenhowerQuadrant.delegate;
        final isImportant = quadrant == EisenhowerQuadrant.doNow ||
            quadrant == EisenhowerQuadrant.schedule;
        ref.read(taskProvider.notifier).updateTask(
              details.data.copyWith(isUrgent: isUrgent, isImportant: isImportant),
            );
      },
      builder: (context, candidate, __) {
        final isHovered = candidate.isNotEmpty;

        return AnimatedContainer(
          duration: Motion.duration(context, const Duration(milliseconds: 160)),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: isHovered ? color : context.cq.beigeDark,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(quadrant.label,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(
                    '${tasks.length}',
                    style:  TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.cq.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                quadrant.description,
                style:  TextStyle(fontSize: 12, color: context.cq.textMuted),
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                _EmptyColumn(isHovered: isHovered)
              else
                for (final task in tasks)
                  LongPressDraggable<Task>(
                    data: task,
                    delay: const Duration(milliseconds: 180),
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 300,
                        child: Opacity(
                          opacity: 0.9,
                          child: TaskCard(
                            task: task,
                            onTap: () {},
                            onToggleDone: () {},
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: TaskCard(
                      task: task,
                      isDragging: true,
                      onTap: () {},
                      onToggleDone: () {},
                    ),
                    child: TaskCard(
                      task: task,
                      onTap: () => onEdit(task),
                      onToggleDone: () =>
                          ref.read(taskProvider.notifier).toggleDone(task.id),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

// ─── États ──────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.cloud_off_outlined,
                size: 44, color: context.cq.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:  TextStyle(color: context.cq.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
