/// Colonnes du tableau Kanban, conformes au CdC : « À faire, en cours,
/// terminé ».
///
/// Remplace les chaînes libres de la version précédente, dans laquelle la page
/// filtrait sur `'in_progress'` alors que rien ne produisait jamais ce statut :
/// la colonne « En cours » était inatteignable.
enum TaskStatus {
  todo('todo', 'À faire'),
  doing('doing', 'En cours'),
  done('done', 'Terminé');

  const TaskStatus(this.value, this.label);

  final String value;
  final String label;

  static TaskStatus fromValue(String? value) => switch (value) {
        'doing' || 'in_progress' => TaskStatus.doing,
        'done' => TaskStatus.done,
        _ => TaskStatus.todo,
      };
}

enum TaskPriority {
  low('low', 'Basse'),
  medium('medium', 'Moyenne'),
  high('high', 'Haute');

  const TaskPriority(this.value, this.label);

  final String value;
  final String label;

  static TaskPriority fromValue(String? value) => switch (value) {
        'low' => TaskPriority.low,
        'high' => TaskPriority.high,
        _ => TaskPriority.medium,
      };
}

/// Quadrants de la matrice d'Eisenhower, explicitement demandée par le CdC
/// (« to-do list ou planificateur dynamique type kanban/matrice d'Eisenhower »).
enum EisenhowerQuadrant {
  doNow('À faire maintenant', 'Urgent et important'),
  schedule('À planifier', 'Important, non urgent'),
  delegate('À déléguer', 'Urgent, peu important'),
  eliminate('À éliminer', 'Ni urgent ni important');

  const EisenhowerQuadrant(this.label, this.description);

  final String label;
  final String description;
}

class Task {
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.isUrgent = false,
    this.isImportant = false,
    this.position = 0,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;

  /// Échéance — « Détails des cartes : description, checklist, tags, échéance,
  /// priorité » (CdC).
  final DateTime? dueDate;

  final bool isUrgent;
  final bool isImportant;

  /// Ordre à l'intérieur d'une colonne, pour que le glisser-déposer soit
  /// persistant et non recalculé à chaque chargement.
  final int position;

  // ── Raccourcis de lecture ───────────────────────────────────────────────

  bool get isTodo => status == TaskStatus.todo;
  bool get isDoing => status == TaskStatus.doing;
  bool get isDone => status == TaskStatus.done;

  EisenhowerQuadrant get quadrant {
    if (isUrgent && isImportant) return EisenhowerQuadrant.doNow;
    if (!isUrgent && isImportant) return EisenhowerQuadrant.schedule;
    if (isUrgent && !isImportant) return EisenhowerQuadrant.delegate;
    return EisenhowerQuadrant.eliminate;
  }

  /// En retard : échéance dépassée et tâche non terminée. La comparaison se
  /// fait au jour près, pas à la milliseconde.
  bool get isOverdue {
    final due = dueDate;
    if (due == null || isDone) return false;
    final today = DateTime.now();
    final dueDay = DateTime(due.year, due.month, due.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return dueDay.isBefore(todayDay);
  }

  bool get isDueToday {
    final due = dueDate;
    if (due == null) return false;
    final today = DateTime.now();
    return due.year == today.year &&
        due.month == today.month &&
        due.day == today.day;
  }

  // ── Sérialisation ───────────────────────────────────────────────────────

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        status: TaskStatus.fromValue(json['status'] as String?),
        priority: TaskPriority.fromValue(json['priority'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
        dueDate: json['due_date'] == null
            ? null
            : DateTime.parse(json['due_date'] as String),
        isUrgent: json['is_urgent'] as bool? ?? false,
        isImportant: json['is_important'] as bool? ?? false,
        position: (json['position'] as num?)?.toInt() ?? 0,
      );

  /// Payload d'écriture. `id` et `created_at` sont générés par Postgres et ne
  /// sont donc jamais envoyés.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'status': status.value,
        'priority': priority.value,
        // `date` côté Postgres : on n'envoie que la partie calendaire pour
        // éviter tout décalage de fuseau horaire.
        'due_date': dueDate == null ? null : _dateOnly(dueDate!),
        'is_urgent': isUrgent,
        'is_important': isImportant,
        'position': position,
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// `clearDueDate` est nécessaire car `dueDate: null` est indiscernable d'un
  /// paramètre omis dans un `copyWith` classique.
  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isUrgent,
    bool? isImportant,
    int? position,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      position: position ?? this.position,
    );
  }

  @override
  bool operator ==(Object other) => other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
