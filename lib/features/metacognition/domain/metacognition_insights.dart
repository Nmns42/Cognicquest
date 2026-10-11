import '../../../shared/models/metacognition_model.dart';

/// Répartition des erreurs par type, et ce qu'on en tire.
class ErrorPattern {
  const ErrorPattern({
    required this.countsByType,
    required this.total,
    required this.dominant,
    required this.correctedCount,
  });

  const ErrorPattern.empty()
      : countsByType = const {},
        total = 0,
        dominant = null,
        correctedCount = 0;

  final Map<ErrorType, int> countsByType;
  final int total;

  /// Type d'erreur nettement majoritaire, s'il y en a un.
  final ErrorType? dominant;

  final int correctedCount;

  bool get isEmpty => total == 0;

  double shareOf(ErrorType type) =>
      total == 0 ? 0 : (countsByType[type] ?? 0) / total;

  /// Message de remédiation, dans l'esprit du CdC : « cela permet au
  /// professionnel de cibler précisément la remédiation ».
  String get summary {
    if (isEmpty) {
      return 'Consigne tes erreurs pour voir apparaître leurs motifs.';
    }
    if (dominant == null) {
      return 'Tes erreurs sont réparties. Aucun motif ne domine pour l\'instant.';
    }
    final share = (shareOf(dominant!) * 100).round();
    return '$share % de tes erreurs sont de type « ${dominant!.label} ». '
        '${dominant!.remedy}';
  }

  factory ErrorPattern.from(List<ErrorLog> errors) {
    if (errors.isEmpty) return const ErrorPattern.empty();

    final counts = <ErrorType, int>{};
    var corrected = 0;
    for (final error in errors) {
      counts[error.errorType] = (counts[error.errorType] ?? 0) + 1;
      if (error.isCorrected) corrected++;
    }

    // « Dominant » suppose une vraie majorité relative : au moins 40 % et
    // strictement devant les autres. Sans ce seuil, 3 erreurs réparties
    // 2-1-1 désigneraient un « motif » qui n'en est pas un.
    ErrorType? dominant;
    var bestCount = 0;
    var tied = false;
    counts.forEach((type, count) {
      if (count > bestCount) {
        dominant = type;
        bestCount = count;
        tied = false;
      } else if (count == bestCount) {
        tied = true;
      }
    });

    if (tied || bestCount / errors.length < 0.4) dominant = null;

    return ErrorPattern(
      countsByType: counts,
      total: errors.length,
      dominant: dominant,
      correctedCount: corrected,
    );
  }
}

/// Niveau d'alerte sur le rythme de travail.
enum StrainLevel {
  healthy('Rythme sain'),
  watch('À surveiller'),
  atRisk('Risque d\'épuisement');

  const StrainLevel(this.label);

  final String label;
}

/// Lecture d'ensemble du journal — « prévenir le burn-out en évaluant le
/// tracker d'émotions et de rythme de travail » (CdC).
class MetacognitionInsights {
  const MetacognitionInsights({
    required this.entryCount,
    required this.averageMood,
    required this.averageRpe,
    required this.averageEnergy,
    required this.strainLevel,
    required this.moodTrend,
    required this.currentStreak,
    required this.strainedDays,
  });

  const MetacognitionInsights.empty()
      : entryCount = 0,
        averageMood = 0,
        averageRpe = 0,
        averageEnergy = 0,
        strainLevel = StrainLevel.healthy,
        moodTrend = const [],
        currentStreak = 0,
        strainedDays = 0;

  final int entryCount;
  final double averageMood;
  final double averageRpe;
  final double averageEnergy;
  final StrainLevel strainLevel;

  /// Humeur moyenne des 7 derniers jours, du plus ancien au plus récent.
  /// `null` pour un jour sans entrée — ne pas confondre « pas noté » et
  /// « moral à zéro ».
  final List<double?> moodTrend;

  /// Nombre de jours consécutifs avec au moins une entrée.
  final int currentStreak;

  /// Journées à effort fort et moral bas sur les deux dernières semaines.
  final int strainedDays;

  bool get isEmpty => entryCount == 0;

  String get summary {
    if (isEmpty) {
      return 'Note ton ressenti après une session : c\'est ce qui rend les '
          'tendances visibles.';
    }
    return switch (strainLevel) {
      StrainLevel.atRisk =>
        'Effort soutenu et moral bas depuis plusieurs jours. Allège la charge '
            'et programme une vraie pause.',
      StrainLevel.watch =>
        'Ton effort ressenti est élevé. Surveille ton énergie sur les '
            'prochains jours.',
      StrainLevel.healthy =>
        'Ton rythme paraît tenable. Continue à noter pour garder le repère.',
    };
  }

  factory MetacognitionInsights.from(List<JournalEntry> entries) {
    if (entries.isEmpty) return const MetacognitionInsights.empty();

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    var moodSum = 0;
    var rpeSum = 0;
    var energySum = 0;
    for (final entry in entries) {
      moodSum += entry.mood;
      rpeSum += entry.rpe;
      energySum += entry.energy;
    }

    // Tendance sur 7 jours : moyenne par jour, `null` si rien n'a été noté.
    final moodByDay = <int, List<int>>{};
    for (final entry in entries) {
      final day = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      final offset = startOfToday.difference(day).inDays;
      if (offset >= 0 && offset < 7) {
        moodByDay.putIfAbsent(offset, () => []).add(entry.mood);
      }
    }

    final trend = <double?>[];
    for (var i = 6; i >= 0; i--) {
      final moods = moodByDay[i];
      trend.add(moods == null || moods.isEmpty
          ? null
          : moods.reduce((a, b) => a + b) / moods.length);
    }

    // Série : jours consécutifs avec au moins une entrée. On tolère que la
    // journée en cours ne soit pas encore notée — elle n'est pas finie.
    final loggedDays = entries
        .map((e) => DateTime(
              e.createdAt.year,
              e.createdAt.month,
              e.createdAt.day,
            ))
        .toSet();

    var cursor = loggedDays.contains(startOfToday)
        ? startOfToday
        : startOfToday.subtract(const Duration(days: 1));
    var streak = 0;
    while (loggedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final twoWeeksAgo = startOfToday.subtract(const Duration(days: 14));
    final recent =
        entries.where((e) => !e.createdAt.isBefore(twoWeeksAgo)).toList();
    final strainedDays = recent.where((e) => e.isStrainedDay).length;

    final averageRpe = rpeSum / entries.length;
    final averageMood = moodSum / entries.length;

    // Deux signaux concordants valent mieux qu'un seuil unique : on croise la
    // répétition des journées difficiles avec les moyennes.
    final level = switch (strainedDays) {
      >= 3 => StrainLevel.atRisk,
      >= 1 => StrainLevel.watch,
      _ => averageRpe >= 7.5 && averageMood <= 2.5
          ? StrainLevel.watch
          : StrainLevel.healthy,
    };

    return MetacognitionInsights(
      entryCount: entries.length,
      averageMood: averageMood,
      averageRpe: averageRpe,
      averageEnergy: energySum / entries.length,
      strainLevel: level,
      moodTrend: trend,
      currentStreak: streak,
      strainedDays: strainedDays,
    );
  }
}
