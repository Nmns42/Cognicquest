/// Fréquence d'une habitude — CdC : « Création d'habitudes avec nom, fréquence
/// (quotidienne, hebdo, mensuelle) ».
enum HabitFrequency {
  daily('daily', 'Quotidienne'),
  weekly('weekly', 'Hebdomadaire'),
  monthly('monthly', 'Mensuelle');

  const HabitFrequency(this.value, this.label);

  final String value;
  final String label;

  /// Unité d'une période, au singulier et au pluriel (« 3 semaines »).
  String unit(int count) => switch (this) {
        HabitFrequency.daily => count > 1 ? 'jours' : 'jour',
        HabitFrequency.weekly => count > 1 ? 'semaines' : 'semaine',
        HabitFrequency.monthly => 'mois',
      };

  /// Unité courte, pour la série (« 🔥 3 sem. »).
  String get shortUnit => switch (this) {
        HabitFrequency.daily => 'j',
        HabitFrequency.weekly => 'sem.',
        HabitFrequency.monthly => 'mois',
      };

  /// Fenêtre de la régularité récente, en périodes : 30 jours, 8 semaines
  /// (deux mois) ou 12 mois.
  int get recentWindow => switch (this) {
        HabitFrequency.daily => 30,
        HabitFrequency.weekly => 8,
        HabitFrequency.monthly => 12,
      };

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
    this.position,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final HabitFrequency frequency;

  /// Dates cochées, au format 'yyyy-MM-dd' (heure locale).
  final List<String> completedDates;

  /// Clé d'ordre manuel (cf. `FractionalKey`), `null` tant que l'habitude
  /// n'a jamais été placée à la main. Écrite uniquement par le
  /// réordonnancement : [copyWith] la conserve.
  final String? position;

  /// Ordre de la liste : habitudes placées à la main (clé, puis id), puis
  /// celles jamais placées — dont toute nouvelle habitude — dans l'ordre de
  /// création (date synchronisée, puis id). Sans aucune clé, c'est l'ordre
  /// de création d'avant l'ordre manuel.
  static List<Habit> manualOrder(Iterable<Habit> habits) {
    final placed = habits.where((h) => h.position != null).toList()
      ..sort((a, b) {
        final byKey = a.position!.compareTo(b.position!);
        return byKey != 0 ? byKey : a.id.compareTo(b.id);
      });
    final unplaced = habits.where((h) => h.position == null).toList()
      ..sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return [...placed, ...unplaced];
  }

  static String toDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  // ── Périodes ───────────────────────────────────────────────────────────
  //
  // Une habitude se juge sur sa période : le jour (quotidienne), la semaine
  // du mois (hebdomadaire) ou le mois (mensuelle). Une période est validée
  // dès qu'au moins un jour y est coché. Chaque période reçoit un numéro
  // entier, consécutif d'une période à la suivante : séries et régularité
  // se calculent alors de la même façon pour les trois fréquences.

  /// Semaine du mois, de 1 à 4 : jours 1–7, 8–14, 15–21, puis 22 à la fin
  /// du mois (les jours 29 à 31 rejoignent la semaine 4).
  static int weekOfMonth(DateTime d) => ((d.day - 1) ~/ 7 + 1).clamp(1, 4);

  /// Premier jour de la semaine [week] (1 à 4) du mois.
  static DateTime startOfWeekOfMonth(int year, int month, int week) =>
      DateTime(year, month, (week - 1) * 7 + 1);

  /// Numéro de la période qui contient [d], selon la fréquence.
  int periodOf(DateTime d) => switch (frequency) {
        // En UTC : pas de jour de 23 ou 25 h au changement d'heure.
        HabitFrequency.daily =>
          DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
              Duration.millisecondsPerDay,
        HabitFrequency.weekly =>
          (d.year * 12 + d.month - 1) * 4 + weekOfMonth(d) - 1,
        HabitFrequency.monthly => d.year * 12 + d.month - 1,
      };

  /// Périodes validées (au moins un jour coché).
  Set<int> get _donePeriods => {
        for (final day in completedDates.map(parseKey).nonNulls) periodOf(day),
      };

  /// La période qui contient [day] est validée.
  bool isDoneInPeriodOf(DateTime day) => _donePeriods.contains(periodOf(day));

  /// Validée pour la période en cours : aujourd'hui, cette semaine du mois ou
  /// ce mois, selon la fréquence.
  bool get completedToday => isDoneInPeriodOf(DateTime.now());

  /// Le jour précis [day] est coché.
  bool isCompletedOn(DateTime day) => completedDates.contains(toDateKey(day));

  /// Semaine [week] (1 à 4) du mois validée.
  bool isWeekDone(int year, int month, int week) =>
      isDoneInPeriodOf(startOfWeekOfMonth(year, month, week));

  /// Mois validé.
  bool isMonthDone(int year, int month) =>
      isDoneInPeriodOf(DateTime(year, month));

  /// Série en cours, en périodes consécutives validées.
  ///
  /// On repart de la période précédente quand la période courante n'est pas
  /// encore validée : la journée (la semaine, le mois) n'est pas finie.
  int get streak {
    final done = _donePeriods;
    var cursor = periodOf(DateTime.now());
    if (!done.contains(cursor)) cursor--;

    var count = 0;
    while (done.contains(cursor)) {
      count++;
      cursor--;
    }
    return count;
  }

  /// Meilleure série historique — CdC : « Statistiques (taux de réussite,
  /// meilleure série, constance) ».
  int get bestStreak {
    final periods = _donePeriods.toList()..sort();
    if (periods.isEmpty) return 0;

    var best = 1;
    var current = 1;
    for (var i = 1; i < periods.length; i++) {
      current = periods[i] == periods[i - 1] + 1 ? current + 1 : 1;
      if (current > best) best = current;
    }
    return best;
  }

  /// Nombre de périodes validées (jours, semaines ou mois).
  int get totalCompletions => _donePeriods.length;

  /// Constance : part des périodes validées depuis la création de
  /// l'habitude. Renvoie une valeur entre 0 et 1.
  double get consistency {
    final elapsed = periodOf(DateTime.now()) - periodOf(createdAt) + 1;
    if (elapsed <= 0) return 0;
    return (totalCompletions / elapsed).clamp(0.0, 1.0);
  }

  /// Régularité récente : part des périodes validées sur la fenêtre de la
  /// fréquence (30 jours, 8 semaines ou 12 mois), bornée à la création —
  /// plus représentative de l'état actuel que la constance historique.
  double get recentSuccessRate {
    final done = _donePeriods;
    final current = periodOf(DateTime.now());
    final start = periodOf(createdAt);

    var window = 0;
    var hits = 0;
    for (var i = 0; i < frequency.recentWindow; i++) {
      final period = current - i;
      if (period < start) break;
      window++;
      if (done.contains(period)) hits++;
    }
    if (window == 0) return 0;
    return hits / window;
  }

  /// Ancien nom de [recentSuccessRate], gardé pour les écrans qui
  /// l'affichent : sur 30 jours pour une habitude quotidienne.
  double get successRateLast30Days => recentSuccessRate;

  /// Grille des N derniers jours, du plus ancien au plus récent.
  List<bool> lastDays(int count) => List.generate(count, (i) {
        final day = DateTime.now().subtract(Duration(days: count - 1 - i));
        return isCompletedOn(day);
      });

  List<bool> get last7Days => lastDays(7);

  /// Jours de la semaine en cours, du lundi au dimanche.
  static List<DateTime> currentWeekDays([DateTime? now]) {
    final today = _startOfDay(now ?? DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return [
      for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i),
    ];
  }

  /// Jours validés dans la semaine en cours (lundi → dimanche), pour le
  /// « 5/7 cette semaine » d'une habitude quotidienne.
  int get doneThisWeek => currentWeekDays().where(isCompletedOn).length;

  /// Bascule la période en cours (jour, semaine ou mois), en local. La
  /// persistance est du ressort du repository ; le modèle reste pur.
  Habit withToggleToday() => withToggleOn(DateTime.now());

  /// Bascule la période qui contient [day].
  ///
  /// Validée : tous ses jours cochés sont retirés. Sinon un jour est coché :
  /// aujourd'hui s'il est dans la période, [day] sinon (rattrapage).
  Habit withToggleOn(DateTime day) {
    final period = periodOf(day);
    final dates = List<String>.from(completedDates);
    if (isDoneInPeriodOf(day)) {
      dates.removeWhere((key) {
        final parsed = parseKey(key);
        return parsed != null && periodOf(parsed) == period;
      });
    } else {
      final now = DateTime.now();
      dates.add(toDateKey(periodOf(now) == period ? now : day));
    }
    return copyWith(completedDates: dates);
  }

  static DateTime? parseKey(String key) {
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
      position: position,
    );
  }

  @override
  bool operator ==(Object other) => other is Habit && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
