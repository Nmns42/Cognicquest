import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/data_failure.dart';
import '../../../shared/models/task_model.dart';
import '../data/task_repository.dart';

/// Gestion des tâches du Kanban.
///
/// Depuis le Lot 10, l'état suit la base locale : il se met à jour aussi bien
/// après une action de l'utilisateur qu'après une synchronisation en
/// arrière-plan, et reste disponible sans réseau.
class TaskNotifier extends StreamNotifier<List<Task>> {
  TaskRepository? get _repository => ref.read(taskRepositoryProvider);

  @override
  Stream<List<Task>> build() {
    // Se relance automatiquement à la connexion / déconnexion.
    final repository = ref.watch(taskRepositoryProvider);
    if (repository == null) return Stream.value(const []);
    return repository.watchAll();
  }

  /// Tire-pour-rafraîchir : déclenche une synchronisation. Les données
  /// locales restent affichées ; hors ligne, il n'y a simplement rien de neuf.
  Future<void> refresh() async {
    try {
      await _repository?.sync();
    } catch (_) {
      // Hors ligne : la file sera rejouée par le coordinateur.
    }
  }

  Future<void> addTask(
    String title, {
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
    bool isUrgent = false,
    bool isImportant = false,
  }) async {
    final repository = _repository;
    if (repository == null) return;

    final current = state.valueOrNull ?? const <Task>[];
    // Nouvelle carte en tête de sa colonne.
    final draft = Task(
      id: '',
      userId: '',
      title: title.trim(),
      description: description.trim(),
      status: status,
      priority: priority,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      isUrgent: isUrgent,
      isImportant: isImportant,
      position: _nextPosition(current, status),
    );

    try {
      final created = await repository.create(draft);
      state = AsyncValue.data([...current, created]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(DataFailure.from(error), stackTrace);
    }
  }

  /// Recrée une tâche supprimée (bouton « Annuler »), à la même place et
  /// avec les mêmes champs.
  Future<void> restoreTask(Task task) async {
    final repository = _repository;
    if (repository == null) return;
    final current = state.valueOrNull ?? const <Task>[];
    try {
      final created = await repository.create(task);
      state = AsyncValue.data([...current, created]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(DataFailure.from(error), stackTrace);
    }
  }

  Future<void> updateTask(Task task) => _mutate(
        optimistic: (tasks) =>
            [for (final t in tasks) if (t.id == task.id) task else t],
        action: (repository) => repository.update(task),
      );

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    final current = state.valueOrNull ?? const <Task>[];
    final task = current.where((t) => t.id == taskId).firstOrNull;
    if (task == null || task.status == status) return;

    final moved = task.copyWith(
      status: status,
      position: _nextPosition(current, status),
    );
    await updateTask(moved);
  }

  Future<void> toggleDone(String taskId) async {
    final task =
        (state.valueOrNull ?? const <Task>[]).where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;
    await updateStatus(
      taskId,
      task.isDone ? TaskStatus.todo : TaskStatus.done,
    );
  }

  Future<void> deleteTask(String taskId) => _mutate(
        optimistic: (tasks) => tasks.where((t) => t.id != taskId).toList(),
        action: (repository) => repository.delete(taskId),
      );

  /// Déplace une tâche vers [targetStatus] à l'index [targetIndex] de cette
  /// colonne, ou juste avant la tâche [beforeTaskId], puis persiste l'ordre
  /// de la colonne en une seule requête. Sans l'un ni l'autre, la tâche va en
  /// fin de colonne.
  Future<void> moveTask(
    String taskId,
    TaskStatus targetStatus, {
    int? targetIndex,
    String? beforeTaskId,
  }) async {
    final repository = _repository;
    if (repository == null) return;

    final previous = state;
    final current = List<Task>.from(state.valueOrNull ?? const <Task>[]);
    final task = current.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;

    final column = current
        .where((t) => t.status == targetStatus && t.id != taskId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // L'index est compté sans la tâche déplacée : en descendant dans sa
    // propre colonne, la carte visée a déjà remonté d'un cran.
    final before = beforeTaskId == null
        ? -1
        : column.indexWhere((t) => t.id == beforeTaskId);
    final index = (before >= 0 ? before : targetIndex ?? column.length)
        .clamp(0, column.length);
    column.insert(index, task.copyWith(status: targetStatus));

    // Réindexation dense : évite la dérive des positions après N déplacements.
    final reordered = [
      for (var i = 0; i < column.length; i++) column[i].copyWith(position: i),
    ];

    final others =
        current.where((t) => t.status != targetStatus && t.id != taskId).toList();
    state = AsyncValue.data([...others, ...reordered]);

    try {
      await repository.saveOrder(reordered);
    } catch (error, stackTrace) {
      state = previous;
      state = AsyncValue.error(DataFailure.from(error), stackTrace);
    }
  }

  /// Applique une modification en optimiste, puis la persiste en local. En
  /// cas d'échec l'état précédent est restauré.
  Future<void> _mutate({
    required List<Task> Function(List<Task>) optimistic,
    required Future<void> Function(TaskRepository) action,
  }) async {
    final repository = _repository;
    if (repository == null) return;

    final previous = state;
    final current = state.valueOrNull ?? const <Task>[];
    state = AsyncValue.data(optimistic(current));

    try {
      await action(repository);
    } catch (error, stackTrace) {
      state = previous;
      state = AsyncValue.error(DataFailure.from(error), stackTrace);
    }
  }

  static int _nextPosition(List<Task> tasks, TaskStatus status) {
    final positions = tasks.where((t) => t.status == status).map((t) => t.position);
    return positions.isEmpty
        ? 0
        : positions.reduce((a, b) => a > b ? a : b) + 1;
  }
}

final taskProvider = StreamNotifierProvider<TaskNotifier, List<Task>>(
  TaskNotifier.new,
);

/// Tâches d'une colonne donnée, triées. Calculé ici plutôt que dans le `build`
/// des pages pour éviter de refiltrer la liste à chaque frame de drag.
final tasksByStatusProvider =
    Provider.family<List<Task>, TaskStatus>((ref, status) {
  final tasks = ref.watch(taskProvider).valueOrNull ?? const <Task>[];
  return tasks.where((t) => t.status == status).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
});

/// Tâches d'un quadrant d'Eisenhower, hors tâches terminées.
final tasksByQuadrantProvider =
    Provider.family<List<Task>, EisenhowerQuadrant>((ref, quadrant) {
  final tasks = ref.watch(taskProvider).valueOrNull ?? const <Task>[];
  return tasks.where((t) => !t.isDone && t.quadrant == quadrant).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
});
