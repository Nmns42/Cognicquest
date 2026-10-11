import 'package:cognicquest/shared/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

Task buildTask({
  String id = 't1',
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
  bool isUrgent = false,
  bool isImportant = false,
}) {
  return Task(
    id: id,
    userId: 'u1',
    title: 'Réviser le chapitre 3',
    description: '',
    status: status,
    priority: priority,
    createdAt: DateTime(2026, 1, 1),
    dueDate: dueDate,
    isUrgent: isUrgent,
    isImportant: isImportant,
  );
}

void main() {
  group('TaskStatus.fromValue', () {
    test('accepte les valeurs canoniques', () {
      expect(TaskStatus.fromValue('todo'), TaskStatus.todo);
      expect(TaskStatus.fromValue('doing'), TaskStatus.doing);
      expect(TaskStatus.fromValue('done'), TaskStatus.done);
    });

    test('traduit l\'ancien statut « in_progress » en « doing »', () {
      // La page filtrait sur 'in_progress' alors que rien ne produisait cette
      // valeur : les données historiques doivent rester lisibles.
      expect(TaskStatus.fromValue('in_progress'), TaskStatus.doing);
    });

    test('retombe sur « todo » pour une valeur inconnue ou nulle', () {
      expect(TaskStatus.fromValue(null), TaskStatus.todo);
      expect(TaskStatus.fromValue('archived'), TaskStatus.todo);
    });
  });

  group('Task.quadrant', () {
    test('classe les quatre combinaisons Eisenhower', () {
      expect(
        buildTask(isUrgent: true, isImportant: true).quadrant,
        EisenhowerQuadrant.doNow,
      );
      expect(
        buildTask(isUrgent: false, isImportant: true).quadrant,
        EisenhowerQuadrant.schedule,
      );
      expect(
        buildTask(isUrgent: true, isImportant: false).quadrant,
        EisenhowerQuadrant.delegate,
      );
      expect(
        buildTask(isUrgent: false, isImportant: false).quadrant,
        EisenhowerQuadrant.eliminate,
      );
    });
  });

  group('Task.isOverdue / isDueToday', () {
    test('une échéance passée sur une tâche non terminée est en retard', () {
      final task = buildTask(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(task.isOverdue, isTrue);
    });

    test('une tâche terminée n\'est jamais en retard', () {
      final task = buildTask(
        status: TaskStatus.done,
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(task.isOverdue, isFalse);
    });

    test('une échéance du jour n\'est pas en retard', () {
      final task = buildTask(dueDate: DateTime.now());
      expect(task.isDueToday, isTrue);
      expect(task.isOverdue, isFalse,
          reason: 'la journée n\'est pas terminée');
    });

    test('sans échéance, ni en retard ni pour aujourd\'hui', () {
      final task = buildTask();
      expect(task.isOverdue, isFalse);
      expect(task.isDueToday, isFalse);
    });
  });

  group('Task.copyWith', () {
    test('conserve l\'échéance quand le paramètre est omis', () {
      final due = DateTime(2026, 6, 1);
      final task = buildTask(dueDate: due).copyWith(title: 'Autre titre');
      expect(task.dueDate, due);
    });

    test('clearDueDate est le seul moyen de retirer l\'échéance', () {
      final task =
          buildTask(dueDate: DateTime(2026, 6, 1)).copyWith(clearDueDate: true);
      expect(task.dueDate, isNull);
    });
  });

  group('Task.toJson', () {
    test('n\'envoie que la partie calendaire de l\'échéance', () {
      final task = buildTask(dueDate: DateTime(2026, 3, 7, 23, 45));
      expect(task.toJson()['due_date'], '2026-03-07');
    });

    test('omet id et created_at, générés par Postgres', () {
      final json = buildTask().toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
    });

    test('sérialise les statuts et priorités en chaînes', () {
      final json = buildTask(
        status: TaskStatus.doing,
        priority: TaskPriority.high,
      ).toJson();
      expect(json['status'], 'doing');
      expect(json['priority'], 'high');
    });
  });

  group('Task.fromJson', () {
    test('lit une ligne Supabase complète', () {
      final task = Task.fromJson({
        'id': 'abc',
        'user_id': 'u1',
        'title': 'Lire',
        'description': 'Chapitre 2',
        'status': 'doing',
        'priority': 'high',
        'created_at': '2026-01-05T10:00:00Z',
        'due_date': '2026-01-09',
        'is_urgent': true,
        'is_important': false,
        'position': 3,
      });

      expect(task.status, TaskStatus.doing);
      expect(task.priority, TaskPriority.high);
      expect(task.dueDate, DateTime(2026, 1, 9));
      expect(task.isUrgent, isTrue);
      expect(task.quadrant, EisenhowerQuadrant.delegate);
      expect(task.position, 3);
    });

    test('tolère les colonnes absentes (base non migrée)', () {
      final task = Task.fromJson({
        'id': 'abc',
        'user_id': 'u1',
        'title': 'Lire',
        'status': 'todo',
        'priority': 'medium',
        'created_at': '2026-01-05T10:00:00Z',
      });

      expect(task.description, '');
      expect(task.dueDate, isNull);
      expect(task.isUrgent, isFalse);
      expect(task.position, 0);
    });
  });
}
