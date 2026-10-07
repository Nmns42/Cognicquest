/// Fréquence d'une habitude — CdC : « Création d'habitudes avec nom, fréquence
/// (quotidienne, hebdo, mensuelle) ».
enum HabitFrequency {
  daily('daily', 'Quotidienne'),
  weekly('weekly', 'Hebdomadaire'),
  monthly('monthly', 'Mensuelle');

  const HabitFrequency(this.value, this.label);

  final String value;
  final String label;

  static HabitFrequency fromValue(String? value) => switch (value) {
        'weekly' => HabitFrequency.weekly,
        'monthly' => HabitFrequency.monthly,
        _ => HabitFrequency.daily,
      };
}

class Habit {
  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.completedDates,
    this.frequency = HabitFrequency.daily,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final HabitFrequency frequency;

  /// Dates cochées, au format 'yyyy-MM-dd' (heure locale).
  final List<String> completedDates;

  static String toDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get completedToday => isCompletedOn(DateTime.now());

  bool isCompletedOn(DateTime day) => completedDates.contains(toDateKey(day));

  /// Série en cours.
  ///
  /// Corrige un bug de la version précédente : la boucle démarrait toujours
  /// à aujourd'hui, donc une habitude tenue pendant 30 jours mais pas encore
  /// cochée *ce matin* affichait une série de 0. On repart de la veille quand
  /// le jour courant n'est pas encore validé — la journée n'est pas finie.
  int get streak {
    final today = _startOfDay(DateTime.now());
    var cursor = isCompletedOn(today)
        ? today
        : today.subtract(const Duration(days: 1));

    var count = 0;
    while (isCompletedOn(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Meilleure série historique — CdC : « Statistiques (taux de réussite,
  /// meilleure série, constance) ».
  int get bestStreak {
    if (completedDates.isEmpty) return 0;

    final days = completedDates.map(_parseKey).nonNulls.toList()..sort();

    var best = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        current++;
        if (current > best) best = current;
      } else if (gap > 1) {
        current = 1;
      }
    }
    return best;
  }

  /// Nombre total de jours validés.
  int get totalCompletions => completedDates.length;

  /// Constance : part des jours validés depuis la création de l'habitude.
  /// Renvoie une valeur entre 0 et 1.
  double get consistency {
    final elapsed =
        _startOfDay(DateTime.now()).difference(_startOfDay(createdAt)).inDays + 1;
    if (elapsed <= 0) return 0;
    return (totalCompletions / elapsed).clamp(0.0, 1.0);
  }

  /// Taux de réussite sur les 30 derniers jours — plus représentatif de l'état
  /// actuel que la constance historique.
  double get successRateLast30Days {
    final today = _startOfDay(DateTime.now());
    final start = _startOfDay(createdAt);

    var window = 0;
    var hits = 0;
    for (var i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(start)) break;
      window++;
      if (isCompletedOn(day)) hits++;
    }
    if (window == 0) return 0;
    return hits / window;
  }

  /// Grille des N derniers jours, du plus ancien au plus récent.
  List<bool> lastDays(int count) => List.generate(count, (i) {
        final day = DateTime.now().subtract(Duration(days: count - 1 - i));
        return isCompletedOn(day);
      });

  List<bool> get last7Days => lastDays(7);

  /// Bascule l'état du jour courant, en local. La persistance est du ressort
  /// du repository ; le modèle reste pur (aucun effet de bord réseau).
  Habit withToggleToday() => withToggleOn(DateTime.now());

  Habit withToggleOn(DateTime day) {
    final key = toDateKey(day);
    final dates = List<String>.from(completedDates);
    if (!dates.remove(key)) dates.add(key);
    return copyWith(completedDates: dates);
  }

  static DateTime? _parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
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
        frequency: HabitFrequency.fromValue(json['frequency'] as String?),
        completedDates: completions,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'frequency': frequency.value,
      };

  Habit copyWith({
    String? name,
    HabitFrequency? frequency,
    List<String>? completedDates,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      createdAt: createdAt,
      frequency: frequency ?? this.frequency,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  @override
  bool operator ==(Object other) => other is Habit && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
