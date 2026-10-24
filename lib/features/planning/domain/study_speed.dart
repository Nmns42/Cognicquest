import '../../../shared/models/planning_model.dart';

/// Vitesse moyenne mesurée pour une activité.
class SpeedEstimate {
  const SpeedEstimate({
    required this.activity,
    required this.unitsPerHour,
    required this.sampleCount,
    required this.spread,
    String? unit,
  }) : _unit = unit;

  final StudyActivity activity;
  final String? _unit;

  /// Unité de l'estimation (pages, mots, cartes…).
  String get unit => _unit ?? activity.unit;

  /// Unités traitées par heure.
  final double unitsPerHour;

  final int sampleCount;

  /// Écart relatif entre la mesure la plus lente et la plus rapide.
  /// Sert à dire si l'estimation est fiable ou encore instable.
  final double spread;

  /// Une estimation sur une seule mesure, ou très dispersée, ne doit pas être
  /// présentée comme un pronostic solide.
  bool get isReliable => sampleCount >= 3 && spread <= 0.6;

  String get confidenceLabel {
    if (sampleCount < 3) {
      return 'À confirmer ($sampleCount mesure${sampleCount > 1 ? 's' : ''})';
    }
    if (spread > 0.6) return 'Variable selon les séances';
    return 'Estimation fiable';
  }

  /// Temps nécessaire pour traiter [units] unités.
  Duration? forecast(double units) {
    if (unitsPerHour <= 0 || units <= 0) return null;
    return Duration(seconds: (units / unitsPerHour * 3600).round());
  }
}

/// Estimation de la vitesse de travail — « estimation/pronostic de la vitesse
/// de lecture/rédaction/rétention/compréhension » (CdC).
abstract final class StudySpeed {
  /// Ne conserve que les mesures récentes : une vitesse de lecture d'il y a
  /// six mois ne dit plus rien de la vitesse actuelle.
  static const int windowDays = 60;

  /// Calcule la vitesse moyenne d'une activité, éventuellement par matière.
  ///
  /// La moyenne est **pondérée par la durée** et non par mesure : sinon une
  /// mesure de 2 minutes pèserait autant qu'une séance de 2 heures.
  static SpeedEstimate? estimate(
    List<SpeedSample> samples,
    StudyActivity activity, {
    String? subject,
    String? unit,
  }) {
    final cutoff = DateTime.now().subtract(const Duration(days: windowDays));

    final relevant = samples
        .where((s) =>
            s.activity == activity &&
            s.durationSeconds > 0 &&
            s.units > 0 &&
            !s.createdAt.isBefore(cutoff) &&
            (unit == null || s.effectiveUnit == unit) &&
            (subject == null || s.subject == subject))
        .toList();

    if (relevant.isEmpty) return null;

    var totalUnits = 0.0;
    var totalSeconds = 0;
    var slowest = double.infinity;
    var fastest = 0.0;

    for (final sample in relevant) {
      totalUnits += sample.units;
      totalSeconds += sample.durationSeconds;
      final rate = sample.unitsPerHour;
      if (rate < slowest) slowest = rate;
      if (rate > fastest) fastest = rate;
    }

    final unitsPerHour = totalUnits / (totalSeconds / 3600);
    final spread = fastest <= 0 ? 0.0 : (fastest - slowest) / fastest;

    return SpeedEstimate(
      activity: activity,
      unit: unit,
      unitsPerHour: unitsPerHour,
      sampleCount: relevant.length,
      spread: spread.clamp(0.0, 1.0),
    );
  }

  /// Toutes les estimations disponibles, une par activité et par unité
  /// mesurée (on ne mélange pas des mots et des paragraphes).
  static List<SpeedEstimate> allEstimates(
    List<SpeedSample> samples, {
    String? subject,
  }) {
    final estimates = <SpeedEstimate>[];
    for (final activity in StudyActivity.values) {
      final units = {
        for (final s in samples)
          if (s.activity == activity) s.effectiveUnit,
      };
      for (final unit in activity.units.where(units.contains)) {
        final estimate = StudySpeed.estimate(samples, activity,
            subject: subject, unit: unit);
        if (estimate != null) estimates.add(estimate);
      }
    }
    return estimates;
  }

  /// Vitesse de lecture en pages par heure, si elle a été mesurée : sert à
  /// convertir la longueur en pages d'un chapitre en temps de travail.
  static double? readingPagesPerHour(List<SpeedSample> samples) =>
      estimate(samples, StudyActivity.reading, unit: 'pages')?.unitsPerHour;

  /// Matières pour lesquelles au moins une mesure existe.
  static List<String> subjectsOf(List<SpeedSample> samples) {
    final subjects = samples
        .map((s) => s.subject)
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return subjects;
  }

  /// Formate une durée prévisionnelle en « 1 h 30 min » / « 45 min ».
  static String formatForecast(Duration duration) =>
      formatHoursMinutes(duration);
}
