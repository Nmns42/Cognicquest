import '../../../core/config/app_config.dart';

/// Jugement porté par l'apprenant après avoir vu la réponse.
enum ReviewGrade {
  again('again', 'À revoir', 'Je ne savais pas'),
  hard('hard', 'Difficile', 'Retrouvé avec peine'),
  good('good', 'Correct', 'Su, sans hésiter longtemps'),
  easy('easy', 'Facile', 'Immédiat');

  const ReviewGrade(this.value, this.label, this.hint);

  final String value;
  final String label;
  final String hint;

  static ReviewGrade fromValue(String? value) {
    for (final grade in values) {
      if (grade.value == value) return grade;
    }
    return ReviewGrade.good;
  }
}

/// État de planification d'une carte.
class ScheduleState {
  const ScheduleState({
    required this.step,
    required this.easeFactor,
    required this.dueAt,
    required this.repetitions,
    required this.lapses,
    required this.intervalDays,
  });

  final int step;
  final double easeFactor;
  final DateTime dueAt;
  final int repetitions;
  final int lapses;

  /// Intervalle effectivement appliqué, en jours : c'est lui qu'on affiche
  /// (« revu dans 7 jours ») et qu'on archive dans l'historique.
  final int intervalDays;
}

/// Planification par **répétition espacée, méthode des J**.
///
/// Le CdC est explicite : « revoir l'information à intervalles espacés. On
/// propose la méthode des J pour pallier à la courbe de l'oubli. »
///
/// L'échelle des J donne le rythme de base (J+1, J+3, J+7…). Un facteur de
/// facilité, dans l'esprit de SM-2, l'ajuste ensuite à la personne : deux
/// apprenants n'oublient pas au même rythme. Les bornes de ce facteur
/// (`initialEaseFactor`, `minEaseFactor`) étaient déjà déclarées dans
/// `AppConfig` depuis l'origine du projet, sans jamais servir.
abstract final class SpacedRepetition {
  /// Échelle des J. Au-delà du dernier rang, l'intervalle continue de croître
  /// en multipliant par le facteur de facilité.
  static const List<int> jLadder = [1, 3, 7, 15, 30, 60];

  static const double maxEaseFactor = 2.8;
  static const int maxIntervalDays = 365;

  /// État d'une carte qui vient d'être créée : due immédiatement, pour que le
  /// premier passage ait lieu le jour même de la saisie.
  static ScheduleState initial({DateTime? now}) {
    final reference = now ?? DateTime.now();
    return ScheduleState(
      step: 0,
      easeFactor: AppConfig.initialEaseFactor,
      dueAt: reference,
      repetitions: 0,
      lapses: 0,
      intervalDays: 0,
    );
  }

  /// Calcule le prochain passage d'une carte à partir du jugement porté.
  ///
  /// Règles :
  ///  - `again` : retour au premier rang, facteur diminué, on recompte un
  ///    oubli. La carte revient le jour même — une notion ratée ne s'oublie
  ///    pas en la repoussant à demain.
  ///  - `hard` : on reste au même rang, facteur légèrement diminué.
  ///  - `good` : on monte d'un rang.
  ///  - `easy` : on monte de deux rangs, facteur augmenté.
  static ScheduleState next(
    ScheduleState current,
    ReviewGrade grade, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();

    var ease = current.easeFactor;
    int step;
    var lapses = current.lapses;

    switch (grade) {
      case ReviewGrade.again:
        step = 0;
        ease -= 0.20;
        lapses += 1;
      case ReviewGrade.hard:
        step = current.step;
        ease -= 0.15;
      case ReviewGrade.good:
        step = current.step + 1;
      case ReviewGrade.easy:
        step = current.step + 2;
        ease += 0.15;
    }

    ease = ease.clamp(AppConfig.minEaseFactor, maxEaseFactor);

    final intervalDays = grade == ReviewGrade.again
        ? 0
        : _intervalFor(step, ease);

    return ScheduleState(
      step: step,
      easeFactor: ease,
      // Un intervalle de 0 jour signifie « à refaire dans cette session » :
      // on place l'échéance 10 minutes plus tard pour que la carte
      // réapparaisse après les autres, et non immédiatement.
      dueAt: intervalDays == 0
          ? reference.add(const Duration(minutes: 10))
          : _startOfDay(reference).add(Duration(days: intervalDays)),
      repetitions: current.repetitions + 1,
      lapses: lapses,
      intervalDays: intervalDays,
    );
  }

  /// Intervalle en jours pour un rang donné, modulé par le facteur de facilité.
  ///
  /// `step` compte les passages réussis : `step == 0` est une carte non encore
  /// apprise, `step == 1` correspond donc au **premier** barreau de l'échelle
  /// (J+1). Indexer directement par `step` sauterait ce barreau et enverrait
  /// une carte neuve à J+3.
  static int _intervalFor(int step, double ease) {
    if (step <= 0) return 1;

    final index = step - 1;
    final ratio = ease / AppConfig.initialEaseFactor;

    if (index < jLadder.length) {
      final base = jLadder[index];
      // Le premier barreau reste à 1 jour quoi qu'il arrive : le moduler
      // donnerait « revois ça dans 0 jour ».
      final scaled = index == 0 ? base : (base * ratio).round();
      return scaled.clamp(1, maxIntervalDays);
    }

    // Au-delà de l'échelle, on prolonge géométriquement.
    var interval = jLadder.last.toDouble();
    for (var i = jLadder.length; i <= index; i++) {
      interval *= ease;
    }
    return interval.round().clamp(1, maxIntervalDays);
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Libellé de l'échéance, tel qu'affiché sur les boutons de jugement.
  static String describeInterval(int intervalDays) {
    if (intervalDays <= 0) return 'dans la session';
    if (intervalDays == 1) return 'demain';
    if (intervalDays < 30) return 'dans $intervalDays j';
    final months = (intervalDays / 30).round();
    return months <= 1 ? 'dans 1 mois' : 'dans $months mois';
  }

  /// Prévisualise l'intervalle associé à chaque jugement, pour afficher son
  /// effet **avant** de cliquer.
  static Map<ReviewGrade, int> preview(ScheduleState current) => {
        for (final grade in ReviewGrade.values)
          grade: next(current, grade).intervalDays,
      };
}

/// Étapes de la méthode SQ3R — « méthode structurée pour mieux lire,
/// comprendre et retenir un texte » (CdC).
enum Sq3rStep {
  survey(
    'Survol',
    'Parcours titres, intertitres et schémas. Que va traiter ce texte ?',
  ),
  question(
    'Questions',
    'Transforme chaque titre en question. Tu liras pour y répondre.',
  ),
  read(
    'Lecture',
    'Lis en cherchant les réponses à tes questions, pas pour tout retenir.',
  ),
  recite(
    'Récitation',
    'Ferme le texte. Réponds à tes questions avec tes propres mots.',
  ),
  review(
    'Révision',
    'Reprends ce qui a résisté. Que retiens-tu, et que dois-tu revoir ?',
  );

  const Sq3rStep(this.label, this.instruction);

  final String label;
  final String instruction;

  bool get isLast => index == Sq3rStep.values.length - 1;

  static Sq3rStep fromIndex(int index) =>
      values[index.clamp(0, values.length - 1)];
}
