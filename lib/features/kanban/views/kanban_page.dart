import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/entrance.dart';
import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
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

  /// Suppression en un clic : pas de boîte de dialogue, mais une annulation
  /// possible quelques secondes (plus rapide, et rien n'est perdu par erreur).
  Future<void> _deleteTask(Task task) async {
    await ref.read(taskProvider.notifier).deleteTask(task.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        snackBarAnimationStyle: Motion.style(context),
        SnackBar(
          content: Text('« ${task.title} » supprimée'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () =>
                ref.read(taskProvider.notifier).restoreTask(task),
          ),
        ),
      );
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
      body: tasksAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => Center(
          child: CircularProgressIndicator(color: context.cq.vertDark),
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(taskProvider.notifier).refresh(),
        ),
        data: (tasks) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Une seule vue à la fois, sur les mêmes tâches : le tableau par
            // état d'avancement, ou la matrice par urgence et importance. Deux
            // petites icônes à droite, au-dessus de la colonne « Terminé ».
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width >= kanbanWideMin
                    ? Space.xl
                    : Space.lg,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _ViewToggle(
                  selected: _view,
                  onChanged: (view) => setState(() => _view = view),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: context.cq.vertDark,
                onRefresh: () => ref.read(taskProvider.notifier).refresh(),
                child: AnimatedSwitcher(
                  duration: Motion.duration(context, CqMotion.base),
                  switchInCurve: CqMotion.enter,
                  switchOutCurve: CqMotion.exit,
                  child: _view == _BoardView.kanban
                      ? _KanbanBoard(
                          key: const ValueKey(_BoardView.kanban),
                          onEdit: _editTask,
                          onDelete: _deleteTask,
                          onAdd: _createTask)
                      : _EisenhowerBoard(
                          key: const ValueKey(_BoardView.eisenhower),
                          onEdit: _editTask,
                          onDelete: _deleteTask),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle tâche',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

/// Bascule discrète entre le Kanban et la matrice : deux icônes, sans texte
/// (les infobulles et les lecteurs d'écran portent les noms).
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.selected, required this.onChanged});

  final _BoardView selected;
  final ValueChanged<_BoardView> onChanged;

  static const Map<_BoardView, (IconData, String)> _views = {
    _BoardView.kanban: (Icons.view_week_outlined, 'Vue Kanban'),
    _BoardView.eisenhower: (Icons.grid_view, "Matrice d'Eisenhower"),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final MapEntry(key: view, value: (icon, label)) in _views.entries)
          IconButton(
            tooltip: label,
            isSelected: view == selected,
            onPressed: view == selected ? null : () => onChanged(view),
            style: IconButton.styleFrom(
              backgroundColor:
                  view == selected ? context.cq.vert : Colors.transparent,
              disabledBackgroundColor: context.cq.vert,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
            icon: Icon(
              icon,
              size: Sizes.iconMd,
              color: view == selected ? context.onAccent : context.cq.textMuted,
            ),
          ),
      ],
    );
  }
}

/// Largeur de la carte qui suit le pointeur pendant un glisser.
const double _feedbackWidth = 300;

// ─── Tableau Kanban ─────────────────────────────────────────────────────────

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    super.key,
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

    // Grand écran (web, ordinateur, tablette en paysage) : trois colonnes
    // larges côte à côte, on glisse librement de l'une à l'autre. Mobile :
    // accordéon vertical, sans défilement horizontal.
    final isWide = MediaQuery.sizeOf(context).width >= kanbanWideMin;

    if (!isWide) {
      return _KanbanAccordion(onEdit: onEdit, onDelete: onDelete, onAdd: onAdd);
    }

    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.lg),
            Expanded(
              child: SingleChildScrollView(
                child: PanelSettle(
                  delay: Entrance.delayFor(i),
                  child: columns[i],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Largeur à partir de laquelle les colonnes s'affichent côte à côte.
const double kanbanWideMin = 900;

/// Kanban mobile : un indicateur fixe en haut, puis les colonnes en tiroirs
/// (un seul ouvert). On glisse une tâche du tiroir ouvert vers l'en-tête
/// d'un tiroir fermé, qui sert de zone de dépôt.
class _KanbanAccordion extends StatefulWidget {
  const _KanbanAccordion({
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final void Function({TaskStatus? status}) onAdd;

  @override
  State<_KanbanAccordion> createState() => _KanbanAccordionState();
}

class _KanbanAccordionState extends State<_KanbanAccordion> {
  TaskStatus _open = TaskStatus.todo;

  void _openDrawer(TaskStatus status) => setState(() => _open = status);

  /// Tiroir ouvert (la colonne complète) ou fermé (son en-tête). Le passage
  /// de l'un à l'autre s'anime en hauteur, sauf en animations réduites :
  /// `AnimatedSize` n'accepte pas une durée nulle, il est alors retiré.
  Widget _drawer(BuildContext context, TaskStatus status) {
    final drawer = status == _open
        ? _KanbanColumn(
            status: status,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onAdd: () => widget.onAdd(status: status),
          )
        : _ClosedDrawer(status: status, onOpen: () => _openDrawer(status));
    if (Motion.reduced(context)) return drawer;
    return AnimatedSize(
      duration: CqMotion.base,
      curve: CqMotion.standard,
      alignment: Alignment.topCenter,
      child: drawer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
          child: _StatusSummary(open: _open, onSelect: _openDrawer),
        ),
        Expanded(
          // Pas de liste paresseuse : la carte saisie doit rester montée
          // pendant le défilement automatique.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                Space.lg, Space.sm, Space.lg, Space.xxxl * 2),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, status) in TaskStatus.values.indexed) ...[
                  if (i > 0) const SizedBox(height: Space.md),
                  PanelSettle(
                    delay: Entrance.delayFor(i),
                    child: _drawer(context, status),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicateur fixe : « À FAIRE 4 · EN COURS 2 · TERMINÉ 1 ». Chaque compteur
/// ouvre son tiroir.
class _StatusSummary extends ConsumerWidget {
  const _StatusSummary({required this.open, required this.onSelect});

  final TaskStatus open;
  final ValueChanged<TaskStatus> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final (i, status) in TaskStatus.values.indexed) ...[
          if (i > 0) const SizedBox(width: Space.sm),
          Expanded(
            child: Semantics(
              button: true,
              selected: status == open,
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.sm),
                onTap: () => onSelect(status),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minHeight: Sizes.touchTarget),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        status.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall,
                      ),
                      Text(
                        '${ref.watch(tasksByStatusProvider(status)).length}',
                        style: text.titleLarge?.copyWith(
                          color: status == open
                              ? context.cq.textPrimary
                              : context.cq.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tiroir fermé : en-tête cliquable, et zone de dépôt pendant un glisser.
class _ClosedDrawer extends ConsumerWidget {
  const _ClosedDrawer({required this.status, required this.onOpen});

  final TaskStatus status;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(tasksByStatusProvider(status)).length;
    final text = Theme.of(context).textTheme;
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) =>
          ref.read(taskProvider.notifier).moveTask(details.data.id, status),
      builder: (context, candidate, __) {
        final hovered = candidate.isNotEmpty;
        final ink = hovered ? context.onAccent : context.cq.textMuted;
        return Semantics(
          button: true,
          label: '${status.label}, $count tâche${count > 1 ? "s" : ""}',
          child: AnimatedContainer(
            duration: Motion.duration(context, CqMotion.fast),
            curve: CqMotion.standard,
            decoration: hovered
                ? BoxDecoration(
                    gradient: context.accentGradient,
                    borderRadius: BorderRadius.circular(Radii.md),
                  )
                : context.chrome.decoration(color: context.cq.cardColor),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.md),
                onTap: onOpen,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: Sizes.control),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            hovered
                                ? 'Déposer dans « ${status.label} »'
                                : status.label,
                            style: text.titleMedium?.copyWith(
                                color: hovered ? context.onAccent : null),
                          ),
                        ),
                        Text('$count',
                            style: text.labelLarge?.copyWith(color: ink)),
                        const SizedBox(width: Space.sm),
                        Icon(Icons.expand_more, color: ink),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
        TaskStatus.doing => (Icons.timelapse, context.cq.vertDark),
        TaskStatus.done => (Icons.check_circle, context.cq.textMuted),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksByStatusProvider(status));
    final (icon, color) = _style(context);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) =>
          ref.read(taskProvider.notifier).moveTask(details.data.id, status),
      builder: (context, candidate, __) {
        final isHovered = candidate.isNotEmpty;

        return AnimatedContainer(
          duration: Motion.duration(context, const Duration(milliseconds: 160)),
          padding: const EdgeInsets.all(Space.lg),
          // Chrome des cartes principales ; la zone de dépôt survolée prend
          // un filet d'accent.
          decoration: context.chrome
              .decoration(color: context.cq.cardColor)
              .copyWith(
                border: isHovered
                    ? Border.all(
                        color: context.cq.vertDark, width: Borders.focus)
                    : null,
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
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: TypeScale.caption,
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
                    icon:
                        Icon(Icons.add, size: 20, color: context.cq.textMuted),
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
                    count: tasks.length,
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
///
/// Pendant le glisser, la liste défile d'elle-même quand le doigt approche du
/// bord : sur téléphone, les colonnes empilées hors de l'écran deviennent
/// atteignables. Comme le glisser lui-même, ce défilement reste actif en mode
/// « Animations réduites » (décision D3).
class _DraggableTask extends ConsumerStatefulWidget {
  const _DraggableTask({
    required this.task,
    required this.index,
    required this.count,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final int index;
  final int count;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  ConsumerState<_DraggableTask> createState() => _DraggableTaskState();
}

class _DraggableTaskState extends ConsumerState<_DraggableTask> {
  /// Hauteur de la zone, centrée sur le doigt, qui déclenche le défilement
  /// dès qu'elle dépasse le bord de la liste.
  static const double _edgeZone = 96;

  EdgeDraggingAutoScroller? _autoScroller;
  Offset? _pointer;

  Rect get _dragRect =>
      Rect.fromCenter(center: _pointer!, width: 1, height: _edgeZone);

  void _onDragUpdate(DragUpdateDetails details) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    _pointer = details.globalPosition;
    if (_autoScroller?.scrollable != scrollable) {
      _autoScroller?.stopAutoScroll();
      _autoScroller = EdgeDraggingAutoScroller(
        scrollable,
        velocityScalar: 50,
        // Le doigt reste immobile au bord pendant que la liste défile : on
        // redonne sa position après chaque pas pour que le défilement
        // continue jusqu'au bout.
        onScrollViewScrolled: () {
          if (_pointer != null) {
            _autoScroller?.startAutoScrollIfNecessary(_dragRect);
          }
        },
      );
    }
    _autoScroller!.startAutoScrollIfNecessary(_dragRect);
  }

  void _stopAutoScroll() {
    _autoScroller?.stopAutoScroll();
    _autoScroller = null;
    _pointer = null;
  }

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }

  Widget _swipeToDelete(BuildContext context, Widget child) {
    final task = widget.task;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        widget.onDelete(task);
        // La suppression effective passe par le provider : on ne laisse
        // jamais Dismissible retirer la carte de sa propre autorité, sinon
        // l'UI diverge de l'état réel.
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.lg),
        margin: const EdgeInsets.only(bottom: Space.sm),
        decoration: BoxDecoration(
          color: context.cq.errorColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Icon(Icons.delete_outline, color: context.cq.errorColor),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    TaskCard cardWith({required bool grip}) => TaskCard(
          task: task,
          gripVisible: grip,
          onDelete: () => widget.onDelete(task),
          onTap: () => widget.onEdit(task),
          onToggleDone: () =>
              ref.read(taskProvider.notifier).toggleDone(task.id),
          trailing: _MoveMenu(
            task: task,
            index: widget.index,
            count: widget.count,
          ),
        );
    // Le balayage pour supprimer est un geste tactile : à la souris, il
    // captait le mouvement horizontal et empêchait de glisser la tâche vers
    // une autre colonne. Survolée, la carte n'a donc pas de balayage (la
    // suppression reste dans le menu de la carte et dans l'éditeur).
    final card = HoverBuilder(
      builder: (context, hovered) => hovered
          ? cardWith(grip: true)
          : _swipeToDelete(context, cardWith(grip: false)),
    );

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.id != task.id,
      onAcceptWithDetails: (details) => ref
          .read(taskProvider.notifier)
          .moveTask(details.data.id, task.status, beforeTaskId: task.id),
      builder: (context, candidate, __) {
        return Column(
          children: [
            if (candidate.isNotEmpty)
              Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: context.cq.vert,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
            CqDraggable<Task>(
              data: task,
              onDragUpdate: _onDragUpdate,
              onDragEnd: (_) => _stopAutoScroll(),
              feedbackWidth: _feedbackWidth,
              // Pendant le maintien et le glisser, la poignée est visible.
              feedback: cardWith(grip: true),
              childWhenDragging: TaskCard(
                task: task,
                isDragging: true,
                onTap: () {},
                onToggleDone: () {},
              ),
              child: card,
            ),
          ],
        );
      },
    );
  }
}

/// Alternative au glisser-déposer pour un seul pointeur (WCAG 2.2, critère
/// 2.5.7) : changer de colonne ou de rang sans glisser.
class _MoveMenu extends ConsumerWidget {
  const _MoveMenu({
    required this.task,
    required this.index,
    required this.count,
  });

  final Task task;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskProvider.notifier);

    return PopupMenuButton<VoidCallback>(
      tooltip: 'Déplacer vers…',
      popUpAnimationStyle: Motion.style(context),
      padding: EdgeInsets.zero,
      iconSize: 18,
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(Icons.more_vert, color: context.cq.textMuted),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        for (final status in TaskStatus.values)
          if (status != task.status)
            PopupMenuItem(
              value: () => notifier.moveTask(task.id, status),
              child: Text('Déplacer vers « ${status.label} »'),
            ),
        if (index > 0)
          PopupMenuItem(
            value: () =>
                notifier.moveTask(task.id, task.status, targetIndex: index - 1),
            child: const Text('Monter'),
          ),
        if (index < count - 1)
          PopupMenuItem(
            value: () =>
                notifier.moveTask(task.id, task.status, targetIndex: index + 1),
            child: const Text('Descendre'),
          ),
      ],
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
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Text(
        isHovered ? 'Déposer ici' : 'Aucune tâche',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHovered ? context.cq.vert : context.cq.textMuted,
          fontSize: TypeScale.body,
          fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─── Matrice d'Eisenhower ───────────────────────────────────────────────────

class _EisenhowerBoard extends StatelessWidget {
  const _EisenhowerBoard(
      {super.key, required this.onEdit, required this.onDelete});

  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  static Map<EisenhowerQuadrant, Color> _colorsOf(BuildContext context) => {
        EisenhowerQuadrant.doNow: context.cq.errorColor,
        EisenhowerQuadrant.schedule: context.cq.vertDark,
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
              details.data
                  .copyWith(isUrgent: isUrgent, isImportant: isImportant),
            );
      },
      builder: (context, candidate, __) {
        final isHovered = candidate.isNotEmpty;

        return AnimatedContainer(
          duration: Motion.duration(context, const Duration(milliseconds: 160)),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cq.cardColor,
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
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(quadrant.label,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: TypeScale.caption,
                      fontWeight: FontWeight.w600,
                      color: context.cq.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                quadrant.description,
                style: TextStyle(
                    fontSize: TypeScale.caption, color: context.cq.textMuted),
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                _EmptyColumn(isHovered: isHovered)
              else
                for (final task in tasks)
                  CqDraggable<Task>(
                    data: task,
                    feedbackWidth: _feedbackWidth,
                    feedback: TaskCard(
                      task: task,
                      gripVisible: true,
                      onTap: () {},
                      onToggleDone: () {},
                    ),
                    childWhenDragging: TaskCard(
                      task: task,
                      isDragging: true,
                      onTap: () {},
                      onToggleDone: () {},
                    ),
                    child: HoverBuilder(
                      builder: (context, hovered) => TaskCard(
                        task: task,
                        gripVisible: hovered,
                        onDelete: () => onDelete(task),
                        onTap: () => onEdit(task),
                        onToggleDone: () => ref
                            .read(taskProvider.notifier)
                            .toggleDone(task.id),
                      ),
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
              style: TextStyle(
                  color: context.cq.textMuted, fontSize: TypeScale.body),
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
