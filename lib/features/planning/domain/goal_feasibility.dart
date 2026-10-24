import '../../../shared/models/planning_model.dart';
import 'study_speed.dart';

/// Faisabilité d'un objectif SMART d'après la vitesse de travail mesurée :
/// combien de temps demande ce qui reste à faire, et combien par jour
/// jusqu'à l'échéance.
class GoalFeasibility {
  const GoalFeasibility({
    required this.speed,
    required this.remainingUnits,
    required this.totalTime,
    this.perDay,
  });

  /// Vitesse utilisée (même unité que l'objectif).
  final SpeedEstimate speed;
  final double remainingUnits;
  final Duration totalTime;

  /// `null` sans échéance (ou échéance passée : tout est « pour aujourd'hui »).
  final Duration? perDay;

  /// Plus de 4 h par jour : l'objectif n'est pas atteignable tel quel.
  bool get isStretched => (perDay ?? Duration.zero) > const Duration(hours: 4);

  /// Unité de l'objectif ramenée à une forme comparable : minuscules,
  /// sans « s » final ni article (« Pages » → « page », « cartes
  /// maîtrisées » → « carte »).
  static String normalizeUnit(String raw) {
    var unit = raw.trim().toLowerCase();
    unit = unit.split(RegExp(r'\s+')).first;
    if (unit.endsWith('s') && unit.length > 3) {
      unit = unit.substring(0, unit.length - 1);
    }
    return unit;
  }

  /// Estimation dont l'unité correspond à celle de l'objectif, la plus
  /// fiable d'abord ; `null` si aucune (ex. « % de réussite »).
  static SpeedEstimate? speedFor(String metricLabel, List<SpeedEstimate> all) {
    final wanted = normalizeUnit(metricLabel);
    if (wanted.isEmpty) return null;
    final matches = all.where((e) => normalizeUnit(e.unit) == wanted).toList()
      ..sort((a, b) => b.sampleCount.compareTo(a.sampleCount));
    return matches.firstOrNull;
  }

  static GoalFeasibility? of(StudyGoal goal, List<SpeedEstimate> estimates) {
    if (goal.targetValue <= 0) return null;
    final speed = speedFor(goal.metricLabel, estimates);
    if (speed == null || speed.unitsPerHour <= 0) return null;
    final remaining = (goal.targetValue - goal.currentValue).clamp(0.0, double.infinity);
    final total = speed.forecast(remaining) ?? Duration.zero;
    final days = goal.daysRemaining;
    Duration? perDay;
    if (days != null) {
      perDay = days <= 0
          ? total
          : Duration(seconds: (total.inSeconds / days).round());
    }
    return GoalFeasibility(
      speed: speed,
      remainingUnits: remaining.toDouble(),
      totalTime: total,
      perDay: perDay,
    );
  }
}
