class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id:          json['id'] as String,
    userId:      json['user_id'] as String,
    title:       json['title'] as String,
    description: json['description'] as String? ?? '',
    status:      json['status'] as String,
    priority:    json['priority'] as String,
    createdAt:   DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'user_id':     userId,
    'title':       title,
    'description': description,
    'status':      status,
    'priority':    priority,
  };

  Task copyWith({
    String? title,
    String? description,
    String? status,
    String? priority,
  }) {
    return Task(
      id:          id,
      userId:      userId,
      title:       title       ?? this.title,
      description: description ?? this.description,
      status:      status      ?? this.status,
      priority:    priority    ?? this.priority,
      createdAt:   createdAt,
    );
  }
}