class Habit {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final List<String> completedDates; // format 'yyyy-MM-dd'

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.completedDates,
  });

  static String toDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get completedToday => completedDates.contains(toDateKey(DateTime.now()));

  int get streak {
    int count = 0;
    var day = DateTime.now();
    while (completedDates.contains(toDateKey(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  List<bool> get last7Days => List.generate(7, (i) {
        final day = DateTime.now().subtract(Duration(days: 6 - i));
        return completedDates.contains(toDateKey(day));
      });

  Habit withToggleToday() {
    final key = toDateKey(DateTime.now());
    final dates = List<String>.from(completedDates);
    if (dates.contains(key)) {
      dates.remove(key);
    } else {
      dates.add(key);
    }
    return Habit(
      id: id,
      userId: userId,
      name: name,
      createdAt: createdAt,
      completedDates: dates,
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json,
    List<String> completions,
  ) =>
      Habit(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        completedDates: completions,
      );
}
