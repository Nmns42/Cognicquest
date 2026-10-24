import '../../../shared/models/planning_model.dart';

/// Un chapitre classé, avec le détail de son score.
class RankedTarget {
  const RankedTarget({
    required this.target,
    required this.score,
    required this.gainablePoints,
    required this.estimatedCost,
    required this.urgencyFactor,
    this.fromMeasuredSpeed = false,
  });

  final ExamTarget target;

  /// Temps tiré de la vitesse de lecture mesurée (longueur en pages), et
  /// non de la longueur en heures déclarée.
  final bool fromMeasuredSpeed;

  /// Points pondérés (écart de note × coefficient) récupérables par heure de
  /// travail, ajustés par l'urgence.
  final double score;

  final double gainablePoints;
  final double estimatedCost;

  /// 1 = pas d'échéance connue ou lointaine ; monte à l'approche de l'examen.
  final double urgencyFactor;

  /// Explication lisible du classement, pour que l'utilisateur puisse
  /// contester le calcul plutôt que de le subir.
  String get rationale {
    final gap = (target.reachableGrade - target.currentGrade)
        .clamp(0.0, 20.0)
        .toStringAsFixed(0);
    final time =
        formatHoursMinutes(Duration(seconds: (estimatedCost * 3600).round()));
    final base = '+$gap pts × coeff. ${target.coefficientLabel} pour ~$time'
        '${fromMeasuredSpeed ? ' (ta vitesse)' : ''}';
    if (urgencyFactor > 1.05) {
      final days = target.daysUntilExam;
      return '$base · examen dans $days j';
    }
    return base;
  }
}

/// Ordre de révision par rentabilité — « viser là où il y a le plus de points
/// en examen, comparaison note actuelle → note atteignable, longueur du cours,
/// difficulté ⇒ ordre de révision » (CdC).
abstract final class RevisionPriority {
  /// Au-delà de cet horizon, l'échéance ne change plus le classement.
  static const int urgencyHorizonDays = 21;

  /// Facteur d'urgence : 1 loin de l'examen, jusqu'à 2 la veille.
  ///
  /// Un chapitre rentable mais dont l'examen est dans trois mois ne doit pas
  /// passer devant un chapitre moyen dont l'examen est demain.
  static double urgencyFor(ExamTarget target) {
    final days = target.daysUntilExam;
    if (days == null) return 1;
    // Examen passé : le chapitre ne rapporte plus rien, il sort du classement
    // via un facteur nul.
    if (days < 0) return 0;
    if (days >= urgencyHorizonDays) return 1;
    return 1 + (urgencyHorizonDays - days) / urgencyHorizonDays;
  }

  /// Rentabilité estimée d'un chapitre : points pondérés récupérables par
  /// heure de travail, ajustés par l'urgence. Le temps vient de la vitesse
  /// de lecture mesurée ([pagesPerHour]) quand le chapitre a une longueur en
  /// pages.
  static double scoreFor(ExamTarget target, {double? pagesPerHour}) {
    final cost = target.costWith(pagesPerHour: pagesPerHour);
    if (cost <= 0) return 0;
    return target.gainablePoints / cost * urgencyFor(target);
  }

  /// Classe les chapitres du plus rentable au moins rentable.
  ///
  /// Les chapitres sans gain possible (déjà au niveau atteignable) et ceux
  /// dont l'examen est passé sont écartés : les afficher en queue de liste
  /// donnerait l'impression qu'il reste quelque chose à y gagner.
  static List<RankedTarget> rank(
    List<ExamTarget> targets, {
    double? pagesPerHour,
  }) {
    final ranked = <RankedTarget>[];

    for (final target in targets) {
      final urgency = urgencyFor(target);
      final score = scoreFor(target, pagesPerHour: pagesPerHour);
      if (score <= 0 || urgency <= 0) continue;

      final measured = (target.lengthPages ?? 0) > 0 &&
          pagesPerHour != null &&
          pagesPerHour > 0;
      ranked.add(RankedTarget(
        target: target,
        score: score,
        gainablePoints: target.gainablePoints,
        estimatedCost: target.costWith(pagesPerHour: pagesPerHour),
        urgencyFactor: urgency,
        fromMeasuredSpeed: measured,
      ));
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // À rentabilité égale, le plus urgent d'abord, puis le plus court.
      final byUrgency = b.urgencyFactor.compareTo(a.urgencyFactor);
      if (byUrgency != 0) return byUrgency;
      return a.estimatedCost.compareTo(b.estimatedCost);
    });

    return ranked;
  }

  /// Chapitres écartés du classement, avec la raison.
  ///
  /// Les montrer à part évite que l'utilisateur croie à un oubli.
  static List<(ExamTarget, String)> excluded(List<ExamTarget> targets) {
    final out = <(ExamTarget, String)>[];
    for (final target in targets) {
      final days = target.daysUntilExam;
      if (days != null && days < 0) {
        out.add((target, 'Examen passé'));
      } else if (target.coefficient <= 0) {
        out.add((target, 'Aucun coefficient déclaré'));
      } else if (target.gainablePoints <= 0) {
        out.add((target, 'Rien de plus à y gagner'));
      }
    }
    return out;
  }

  /// Total des heures à prévoir pour traiter les [count] premiers chapitres.
  static double effortFor(List<RankedTarget> ranked, {int count = 3}) {
    var total = 0.0;
    for (final entry in ranked.take(count)) {
      total += entry.estimatedCost;
    }
    return total;
  }
}
