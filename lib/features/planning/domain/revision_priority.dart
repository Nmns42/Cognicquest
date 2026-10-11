import '../../../shared/models/planning_model.dart';

/// Un chapitre classé, avec le détail de son score.
class RankedTarget {
  const RankedTarget({
    required this.target,
    required this.score,
    required this.gainablePoints,
    required this.estimatedCost,
    required this.urgencyFactor,
  });

  final ExamTarget target;

  /// Points récupérables par heure de travail, pondérés par l'urgence.
  final double score;

  final double gainablePoints;
  final double estimatedCost;

  /// 1 = pas d'échéance connue ou lointaine ; monte à l'approche de l'examen.
  final double urgencyFactor;

  /// Explication lisible du classement, pour que l'utilisateur puisse
  /// contester le calcul plutôt que de le subir.
  String get rationale {
    final points = gainablePoints.toStringAsFixed(1);
    final hours = estimatedCost.toStringAsFixed(1);
    final base = '$points pts récupérables pour ~$hours h';
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

  /// Rentabilité d'un chapitre : points récupérables par heure, ajustés.
  static double scoreFor(ExamTarget target) {
    final cost = target.estimatedCost;
    if (cost <= 0) return 0;
    return target.gainablePoints / cost * urgencyFor(target);
  }

  /// Classe les chapitres du plus rentable au moins rentable.
  ///
  /// Les chapitres sans gain possible (déjà au niveau atteignable) et ceux
  /// dont l'examen est passé sont écartés : les afficher en queue de liste
  /// donnerait l'impression qu'il reste quelque chose à y gagner.
  static List<RankedTarget> rank(List<ExamTarget> targets) {
    final ranked = <RankedTarget>[];

    for (final target in targets) {
      final urgency = urgencyFor(target);
      final score = scoreFor(target);
      if (score <= 0 || urgency <= 0) continue;

      ranked.add(RankedTarget(
        target: target,
        score: score,
        gainablePoints: target.gainablePoints,
        estimatedCost: target.estimatedCost,
        urgencyFactor: urgency,
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
      } else if (target.gainablePoints <= 0) {
        out.add((target, 'Rien de plus à y gagner'));
      } else if (target.examWeight <= 0) {
        out.add((target, 'Aucun point déclaré à l\'examen'));
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
