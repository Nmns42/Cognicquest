/// Les cinq critères SMART, pour diagnostiquer un objectif incomplet.
enum SmartCriterion {
  specific('Spécifique', 'Un énoncé précis, pas « travailler les maths »'),
  measurable('Mesurable', 'Une unité et une cible chiffrée'),
  achievable('Atteignable', 'Les moyens concrets d\'y arriver'),
  relevant('Réaliste et pertinent', 'Pourquoi cet objectif compte pour toi'),
  timeBound('Temporel', 'Une échéance datée');

  const SmartCriterion(this.label, this.hint);

  /// Lettre de l'acronyme SMART (le R reste « R » : réaliste et pertinent).
  String get letter => switch (this) {
        SmartCriterion.specific => 'S',
        SmartCriterion.measurable => 'M',
        SmartCriterion.achievable => 'A',
        SmartCriterion.relevant => 'R',
        SmartCriterion.timeBound => 'T',
      };

  final String label;
  final String hint;
}

/// Objectif d'étude formulé selon la méthode SMART.
class StudyGoal {
  const StudyGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.subject,
    this.metricLabel = '',
    this.targetValue = 0,
    this.currentValue = 0,
    this.achievablePlan = '',
    this.relevance = '',
    this.deadline,
    this.completedAt,
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String title;
  final String? subject;
  final String metricLabel;
  final double targetValue;
  final double currentValue;
  final String achievablePlan;
  final String relevance;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isSynced;

  bool get isCompleted => completedAt != null;

  /// Avancement de 0 à 1. Un objectif sans cible mesurable n'a pas
  /// d'avancement calculable : on renvoie 0 plutôt qu'une valeur inventée.
  double get progress {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Critères SMART effectivement remplis.
  Set<SmartCriterion> get satisfiedCriteria => {
        if (title.trim().length >= 8) SmartCriterion.specific,
        if (metricLabel.trim().isNotEmpty && targetValue > 0)
          SmartCriterion.measurable,
        if (achievablePlan.trim().isNotEmpty) SmartCriterion.achievable,
        if (relevance.trim().isNotEmpty) SmartCriterion.relevant,
        if (deadline != null) SmartCriterion.timeBound,
      };

  Set<SmartCriterion> get missingCriteria =>
      SmartCriterion.values.toSet().difference(satisfiedCriteria);

  bool get isFullySmart => missingCriteria.isEmpty;

  /// Jours restants avant l'échéance (négatif si dépassée).
  int? get daysRemaining {
    final due = deadline;
    if (due == null) return null;
    final today = DateTime.now();
    return DateTime(due.year, due.month, due.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  bool get isOverdue {
    final days = daysRemaining;
    return days != null && days < 0 && !isCompleted;
  }

  /// Rythme requis pour tenir l'échéance, dans l'unité de la mesure.
  ///
  /// `null` quand la question n'a pas de sens : pas de cible, pas d'échéance,
  /// ou objectif déjà atteint.
  double? get requiredPacePerDay {
    final days = daysRemaining;
    if (days == null || targetValue <= 0) return null;
    final remaining = targetValue - currentValue;
    if (remaining <= 0) return 0;
    // Échéance aujourd'hui ou dépassée : tout le reste est à faire maintenant.
    if (days <= 0) return remaining;
    return remaining / days;
  }

  StudyGoal copyWith({
    String? title,
    String? subject,
    String? metricLabel,
    double? targetValue,
    double? currentValue,
    String? achievablePlan,
    String? relevance,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? isSynced,
  }) =>
      StudyGoal(
        id: id,
        userId: userId,
        title: title ?? this.title,
        subject: subject ?? this.subject,
        metricLabel: metricLabel ?? this.metricLabel,
        targetValue: targetValue ?? this.targetValue,
        currentValue: currentValue ?? this.currentValue,
        achievablePlan: achievablePlan ?? this.achievablePlan,
        relevance: relevance ?? this.relevance,
        deadline: clearDeadline ? null : (deadline ?? this.deadline),
        createdAt: createdAt,
        completedAt:
            clearCompletedAt ? null : (completedAt ?? this.completedAt),
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  bool operator ==(Object other) => other is StudyGoal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Élément du diagramme de Gantt.
class PlanItem {
  const PlanItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.goalId,
    this.taskId,
    this.subject,
    this.progress = 0,
    this.isMilestone = false,
    this.dependsOnId,
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String? goalId;
  final String? taskId;
  final String title;
  final String? subject;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  final bool isMilestone;
  final String? dependsOnId;
  final DateTime createdAt;
  final bool isSynced;

  /// Durée en jours, jalon compris (un jalon dure 1 jour à l'affichage).
  int get durationDays {
    if (isMilestone) return 1;
    final days = _dayOnly(endDate).difference(_dayOnly(startDate)).inDays;
    return days < 0 ? 1 : days + 1;
  }

  bool get isComplete => progress >= 1;

  bool get isLate {
    if (isComplete) return false;
    return _dayOnly(endDate).isBefore(_dayOnly(DateTime.now()));
  }

  bool get isInProgress {
    final today = _dayOnly(DateTime.now());
    return !_dayOnly(startDate).isAfter(today) &&
        !_dayOnly(endDate).isBefore(today);
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  PlanItem copyWith({
    String? title,
    String? subject,
    DateTime? startDate,
    DateTime? endDate,
    double? progress,
    bool? isMilestone,
    String? dependsOnId,
    bool clearDependsOn = false,
    bool? isSynced,
  }) =>
      PlanItem(
        id: id,
        userId: userId,
        goalId: goalId,
        taskId: taskId,
        title: title ?? this.title,
        subject: subject ?? this.subject,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        progress: progress ?? this.progress,
        isMilestone: isMilestone ?? this.isMilestone,
        dependsOnId: clearDependsOn ? null : (dependsOnId ?? this.dependsOnId),
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  bool operator ==(Object other) => other is PlanItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Activité dont on mesure la vitesse.
enum StudyActivity {
  reading('reading', 'Lecture', 'pages'),
  writing('writing', 'Rédaction', 'mots'),
  memorising('memorising', 'Mémorisation', 'cartes'),
  exercises('exercises', 'Exercices', 'exercices');

  const StudyActivity(this.value, this.label, this.unit);

  final String value;
  final String label;

  /// Unité mesurée par défaut pour cette activité.
  final String unit;

  /// Unités proposées au choix (menu déroulant de la saisie).
  List<String> get units => switch (this) {
        StudyActivity.reading => const ['pages'],
        StudyActivity.writing => const ['pages', 'paragraphes', 'phrases', 'mots'],
        StudyActivity.memorising => const ['cartes', 'fiches', 'quiz', 'questions'],
        StudyActivity.exercises => const ['exercices'],
      };

  /// La lecture se chronomètre à la seconde près (cadran H:M:S), les autres
  /// activités à la minute (cadran H:M).
  bool get timedToTheSecond => this == StudyActivity.reading;

  static StudyActivity fromValue(String? value) {
    for (final activity in values) {
      if (activity.value == value) return activity;
    }
    return StudyActivity.reading;
  }
}

/// Une mesure ponctuelle de vitesse.
class SpeedSample {
  const SpeedSample({
    required this.id,
    required this.userId,
    required this.activity,
    required this.units,
    required this.durationSeconds,
    required this.createdAt,
    this.subject,
    this.unit,
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final StudyActivity activity;
  final String? subject;
  final double units;
  final int durationSeconds;

  /// Unité de la mesure ; `null` (anciennes mesures) : celle de l'activité.
  final String? unit;

  String get effectiveUnit => unit ?? activity.unit;
  final DateTime createdAt;
  final bool isSynced;

  /// Unités traitées par heure.
  double get unitsPerHour =>
      durationSeconds <= 0 ? 0 : units / (durationSeconds / 3600);
}

/// Chapitre candidat à la révision.
class ExamTarget {
  const ExamTarget({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.noteId,
    this.subject,
    this.examWeight = 0,
    this.currentGrade = 0,
    this.reachableGrade = 20,
    this.lengthHours = 1,
    this.lengthPages,
    this.difficulty = 3,
    this.examDate,
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String? noteId;
  final String title;
  final String? subject;

  /// Coefficient de la matière (ou du chapitre) à l'examen, saisi
  /// librement (2, 7, 12, 2,5…) : pas de borne haute, les barèmes varient.
  ///
  /// Le nom de colonne historique reste `exam_weight` ; c'est bien un
  /// coefficient, pas une note ni un nombre de points.
  final double examWeight;

  double get coefficient => examWeight <= 0 ? 0 : examWeight;

  /// « 2 », « 2,5 » : le coefficient tel qu'on l'écrit.
  String get coefficientLabel => formatDecimal(coefficient);

  final double currentGrade;
  final double reachableGrade;
  final double lengthHours;

  /// Longueur en pages, facultative.
  final double? lengthPages;
  final int difficulty;
  final DateTime? examDate;
  final DateTime createdAt;
  final bool isSynced;

  /// Points pondérés récupérables : l'écart entre la note actuelle et la
  /// note atteignable (sur 20), multiplié par le coefficient — exactement
  /// ce que ce chapitre peut ajouter à la moyenne coefficientée.
  double get gainablePoints {
    final gap = (reachableGrade - currentGrade).clamp(0.0, 20.0);
    return coefficient * gap;
  }

  /// Coût estimé en heures, la difficulté alourdissant la longueur.
  double get estimatedCost => costWith();

  /// Difficulté 3 = neutre ; 1 allège de 40 %, 5 alourdit de 40 %.
  double get difficultyFactor => 1 + (difficulty - 3) * 0.2;

  /// Coût en heures selon la vitesse de lecture mesurée : avec une longueur
  /// en pages et une vitesse connue ([pagesPerHour]), le temps vient des
  /// mesures de l'utilisateur ; sinon de la longueur en heures déclarée.
  double costWith({double? pagesPerHour}) {
    final pages = lengthPages;
    final double base;
    if (pages != null && pages > 0 && pagesPerHour != null && pagesPerHour > 0) {
      base = pages / pagesPerHour;
    } else {
      base = lengthHours <= 0 ? 0.5 : lengthHours;
    }
    return base * difficultyFactor;
  }

  int? get daysUntilExam {
    final date = examDate;
    if (date == null) return null;
    final today = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  ExamTarget copyWith({
    String? title,
    String? subject,
    double? examWeight,
    double? currentGrade,
    double? reachableGrade,
    double? lengthHours,
    double? lengthPages,
    int? difficulty,
    DateTime? examDate,
    bool clearExamDate = false,
    bool? isSynced,
  }) =>
      ExamTarget(
        id: id,
        userId: userId,
        noteId: noteId,
        title: title ?? this.title,
        subject: subject ?? this.subject,
        examWeight: examWeight ?? this.examWeight,
        currentGrade: currentGrade ?? this.currentGrade,
        reachableGrade: reachableGrade ?? this.reachableGrade,
        lengthHours: lengthHours ?? this.lengthHours,
        lengthPages: lengthPages ?? this.lengthPages,
        difficulty: difficulty ?? this.difficulty,
        examDate: clearExamDate ? null : (examDate ?? this.examDate),
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  bool operator ==(Object other) => other is ExamTarget && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Nombre décimal à la française, sans zéro inutile : 2 → « 2 »,
/// 2.5 → « 2,5 », 1.25 → « 1,25 ».
String formatDecimal(double value, {int maxDigits = 2}) {
  var text = value.toStringAsFixed(maxDigits);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return text.replaceAll('.', ',');
}

/// Durée en « X h Y min » : 90 min → « 1 h 30 min », 45 min → « 45 min »,
/// 2 h → « 2 h ». Arrondie à la minute (« moins d'1 min » en dessous).
String formatHoursMinutes(Duration duration) {
  final totalMinutes = (duration.inSeconds / 60).round();
  if (totalMinutes <= 0) return 'moins d’1 min';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes min';
  return minutes == 0 ? '$hours h' : '$hours h $minutes min';
}
