import '../../../shared/models/planning_model.dart';
import 'revision_priority.dart';

/// Une séance planifiée sur une journée donnée.
class ScheduledSession {
  const ScheduledSession({
    required this.day,
    required this.target,
    required this.hours,
  });

  final DateTime day;
  final ExamTarget target;
  final double hours;
}

/// Une journée du calendrier, avec sa charge.
class ScheduledDay {
  const ScheduledDay({
    required this.day,
    required this.sessions,
    required this.capacityHours,
  });

  final DateTime day;
  final List<ScheduledSession> sessions;
  final double capacityHours;

  double get plannedHours =>
      sessions.fold<double>(0, (sum, s) => sum + s.hours);

  double get load => capacityHours <= 0 ? 0 : plannedHours / capacityHours;

  bool get isEmpty => sessions.isEmpty;

  /// Journée pleine à plus de 95 % : au-delà, la marge d'imprévu disparaît.
  bool get isSaturated => load >= 0.95;
}

/// Plan de révision généré.
class AdaptivePlan {
  const AdaptivePlan({
    required this.days,
    required this.unscheduled,
    required this.totalPlannedHours,
  });

  const AdaptivePlan.empty()
      : days = const [],
        unscheduled = const [],
        totalPlannedHours = 0;

  final List<ScheduledDay> days;

  /// Chapitres qu'on n'a pas pu caser avant leur examen, avec les heures
  /// manquantes. Les taire donnerait un plan rassurant mais faux.
  final List<(ExamTarget, double)> unscheduled;

  final double totalPlannedHours;

  bool get isEmpty => days.every((d) => d.isEmpty);

  bool get isFeasible => unscheduled.isEmpty;

  String get summary {
    if (isEmpty) {
      return 'Ajoute des chapitres et leurs dates d\'examen pour générer un plan.';
    }
    if (!isFeasible) {
      final missing = unscheduled.fold<double>(0, (sum, e) => sum + e.$2);
      return 'Il manque ~${missing.toStringAsFixed(1)} h pour tout couvrir. '
          'Revois tes objectifs à la baisse ou dégage du temps.';
    }
    return '${totalPlannedHours.toStringAsFixed(1)} h réparties sur '
        '${days.where((d) => !d.isEmpty).length} jours.';
  }
}

/// Calendrier adaptatif : répartit le travail restant sur les jours
/// disponibles, en respectant les dates d'examen et la rentabilité.
///
/// CdC : « permettre la programmation de sessions d'étude selon les priorités »
/// et « ajustement des examens pour chaque calendrier ».
abstract final class AdaptiveSchedule {
  /// Durée minimale d'une séance : en dessous, le temps de mise en route
  /// mange le bénéfice.
  static const double minSessionHours = 0.5;

  /// Génère un plan sur [horizonDays] jours.
  ///
  /// [dailyCapacityHours] est le temps d'étude disponible par jour. On planifie
  /// au plus tard possible **avant** l'examen pour les chapitres urgents, mais
  /// on remplit au plus tôt : réviser trop tôt puis ne plus y revenir est le
  /// meilleur moyen d'oublier.
  static AdaptivePlan generate(
    List<ExamTarget> targets, {
    required double dailyCapacityHours,
    int horizonDays = 21,
    DateTime? from,
  }) {
    if (targets.isEmpty || dailyCapacityHours <= 0) {
      return const AdaptivePlan.empty();
    }

    final today = _dayOnly(from ?? DateTime.now());
    final ranked = RevisionPriority.rank(targets);
    if (ranked.isEmpty) return const AdaptivePlan.empty();

    final days = [
      for (var i = 0; i < horizonDays; i++) today.add(Duration(days: i)),
    ];

    final sessionsByDay = <DateTime, List<ScheduledSession>>{
      for (final day in days) day: [],
    };
    final remainingCapacity = <DateTime, double>{
      for (final day in days) day: dailyCapacityHours,
    };

    final unscheduled = <(ExamTarget, double)>[];
    var totalPlanned = 0.0;

    for (final entry in ranked) {
      var remaining = entry.estimatedCost;

      for (final day in days) {
        if (remaining < 0.01) break;

        // On ne planifie jamais après l'examen : ce serait du travail perdu.
        final deadline = entry.target.examDate;
        if (deadline != null && day.isAfter(_dayOnly(deadline))) break;

        final free = remainingCapacity[day]!;
        if (free < minSessionHours) continue;

        final slot = remaining < free ? remaining : free;
        // On évite les miettes : un reliquat sous le seuil part avec la séance.
        final allocated = (remaining - slot) < minSessionHours
            ? (remaining < free ? remaining : free)
            : slot;

        sessionsByDay[day]!.add(ScheduledSession(
          day: day,
          target: entry.target,
          hours: allocated,
        ));
        remainingCapacity[day] = free - allocated;
        remaining -= allocated;
        totalPlanned += allocated;
      }

      if (remaining >= 0.01) unscheduled.add((entry.target, remaining));
    }

    return AdaptivePlan(
      days: [
        for (final day in days)
          ScheduledDay(
            day: day,
            sessions: sessionsByDay[day]!,
            capacityHours: dailyCapacityHours,
          ),
      ],
      unscheduled: unscheduled,
      totalPlannedHours: totalPlanned,
    );
  }

  /// Convertit un plan en éléments de Gantt, pour visualiser la répartition.
  static List<PlanItem> toPlanItems(
    AdaptivePlan plan, {
    required String userId,
    required String Function() idGenerator,
  }) {
    // Une barre par chapitre, couvrant du premier au dernier jour planifié :
    // une barre par séance saturerait le diagramme.
    final spans = <String, (ExamTarget, DateTime, DateTime)>{};

    for (final day in plan.days) {
      for (final session in day.sessions) {
        final existing = spans[session.target.id];
        if (existing == null) {
          spans[session.target.id] = (session.target, day.day, day.day);
        } else {
          spans[session.target.id] = (
            existing.$1,
            existing.$2,
            day.day.isAfter(existing.$3) ? day.day : existing.$3,
          );
        }
      }
    }

    return [
      for (final span in spans.values)
        PlanItem(
          id: idGenerator(),
          userId: userId,
          title: span.$1.title,
          subject: span.$1.subject,
          startDate: span.$2,
          endDate: span.$3,
          createdAt: DateTime.now(),
          isSynced: false,
        ),
    ];
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
