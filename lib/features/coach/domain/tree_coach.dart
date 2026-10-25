/// Arbre-Coach : transforme les vraies données de l'utilisateur (journal,
/// habitudes, révisions, auto-explications) en une vitalité de l'arbre et
/// en conseils contextuels, du plus urgent au plus encourageant.
///
/// Logique pure, sans Flutter : chaque règle est testée isolément.
library;

/// Signaux lus dans l'app, tous facultatifs : une donnée absente ne compte
/// ni pour ni contre.
class CoachSignals {
  const CoachSignals({
    this.recentMood,
    this.recentEnergy,
    this.recentEffort,
    this.journalEntries = 0,
    this.strainedDays = 0,
    this.daysSinceLastEntry,
    this.habitCount = 0,
    this.habitConsistency = 0,
    this.habitsDoneToday = 0,
    this.retentionRate,
    this.reviewsLast30Days = 0,
    this.dueCards = 0,
    this.fuzzyChapters = const [],
    this.wellbeingEnabled = true,
  });

  /// Moyennes récentes du journal : humeur et énergie de 1 à 5, effort
  /// ressenti (RPE) de 1 à 10.
  final double? recentMood;
  final double? recentEnergy;
  final double? recentEffort;
  final int journalEntries;

  /// Journées à effort fort et moral bas sur deux semaines.
  final int strainedDays;

  /// `null` sans aucune entrée.
  final int? daysSinceLastEntry;

  final int habitCount;

  /// Régularité moyenne des habitudes, de 0 à 1.
  final double habitConsistency;
  final int habitsDoneToday;

  /// Taux de rétention sur 30 jours (0 à 1), `null` s'il n'est pas encore
  /// significatif.
  final double? retentionRate;
  final int reviewsLast30Days;
  final int dueCards;

  /// Fiches dont la compréhension reste floue, la plus floue d'abord.
  final List<FuzzyChapter> fuzzyChapters;

  /// Consentement aux données de bien-être : sans lui, aucun conseil ne
  /// renvoie vers le journal (désactivé).
  final bool wellbeingEnabled;
}

/// Fiche à retravailler : auto-explication jugée peu claire, ou cartes
/// souvent oubliées.
class FuzzyChapter {
  const FuzzyChapter({
    required this.noteId,
    required this.title,
    this.confidence,
    this.lapses = 0,
  });

  final String noteId;
  final String title;

  /// Dernière confiance déclarée en mode « Explique-moi » (1 à 5).
  final int? confidence;

  /// Oublis cumulés des cartes de la fiche.
  final int lapses;

  /// Plus le score est haut, plus la notion est floue.
  double get fuzziness =>
      (confidence == null ? 0 : (3 - confidence!).clamp(0, 2) * 2) +
      (lapses >= 2 ? lapses.toDouble() : 0);
}

/// Thème d'un conseil, pour son icône et sa couleur.
enum CoachTopic { rest, mood, retention, understanding, habits, journal, cheer }

class CoachAdvice {
  const CoachAdvice({
    required this.topic,
    required this.title,
    required this.body,
    this.actionLabel,
    this.route,
  });

  final CoachTopic topic;
  final String title;
  final String body;

  /// Bouton facultatif menant à l'écran utile.
  final String? actionLabel;
  final String? route;
}

/// Chemins utilisés par les conseils (copie des constantes du routeur, pour
/// garder ce fichier sans dépendance).
abstract final class CoachRoute {
  static const String journalEntry = '/journal/entry';
  static const String reframe = '/journal/reframe';
  static const String review = '/review';
  static const String habits = '/habits';
  static const String pomodoro = '/pomodoro';
  static String explain(String noteId) => '/review/explain/$noteId';
}

class TreeCoach {
  const TreeCoach(this.signals);

  final CoachSignals signals;

  /// Vitalité de l'arbre (0 à 1) : moyenne pondérée des signaux connus —
  /// régularité (40 %), rétention (30 %), humeur et énergie (15 % chacune).
  double get vitality {
    final s = signals;
    var weight = 0.0;
    var total = 0.0;
    void add(double? value, double w) {
      if (value == null) return;
      total += value.clamp(0.0, 1.0) * w;
      weight += w;
    }

    if (s.habitCount > 0) add(s.habitConsistency, 0.4);
    add(s.retentionRate, 0.3);
    if (s.recentMood != null) add((s.recentMood! - 1) / 4, 0.15);
    if (s.recentEnergy != null) add((s.recentEnergy! - 1) / 4, 0.15);
    return weight == 0 ? 0 : total / weight;
  }

  /// Phrase sous l'arbre.
  String get headline {
    final v = vitality;
    if (signals.habitCount == 0 &&
        signals.retentionRate == null &&
        signals.journalEntries == 0) {
      return 'Ton arbre attend ses premières données : une habitude, '
          'une révision ou un bilan suffisent à le faire pousser.';
    }
    if (v >= 0.75) return 'Ton arbre est en pleine santé.';
    if (v >= 0.5) {
      return 'Ton arbre pousse bien : quelques soins le fortifient.';
    }
    if (v >= 0.3) return 'Ton arbre a besoin d’attention cette semaine.';
    return 'Ton arbre a soif : reprends doucement, une chose à la fois.';
  }

  /// Conseils, du plus prioritaire au plus encourageant ; [limit] au plus.
  List<CoachAdvice> advice({int limit = 3}) {
    final s = signals;
    final out = <CoachAdvice>[];

    // 1. Épuisement : passe avant tout le reste.
    final exhausted = s.strainedDays >= 3 ||
        ((s.recentEffort ?? 0) >= 8 && (s.recentEnergy ?? 5) <= 2);
    if (exhausted) {
      out.add(const CoachAdvice(
        topic: CoachTopic.rest,
        title: 'Ton corps demande une pause',
        body: 'Effort élevé et énergie basse ces derniers jours : raccourcis '
            'tes sessions (25 min), dors avant de réviser plus, et garde une '
            'soirée sans travail.',
        actionLabel: 'Régler le Pomodoro',
        route: CoachRoute.pomodoro,
      ));
    }

    // 2. Moral bas.
    if ((s.recentMood ?? 5) <= 2.2) {
      out.add(const CoachAdvice(
        topic: CoachTopic.mood,
        title: 'Moral en berne',
        body: 'Ton humeur est basse depuis quelques jours. Un recadrage '
            'cognitif aide à remettre une pensée difficile en perspective.',
        actionLabel: 'Faire un recadrage',
        route: CoachRoute.reframe,
      ));
    }

    // 3. Notions floues.
    if (s.fuzzyChapters.isNotEmpty) {
      final top = s.fuzzyChapters.first;
      final others = s.fuzzyChapters.skip(1).take(2).map((c) => c.title);
      out.add(CoachAdvice(
        topic: CoachTopic.understanding,
        title: 'Notion encore floue : ${top.title}',
        body: 'Explique-la avec tes mots avant de revoir ses cartes : c’est '
            'là que la compréhension se fixe.'
            '${others.isEmpty ? '' : ' À reprendre ensuite : '
                '${others.join(', ')}.'}',
        actionLabel: 'M’expliquer la notion',
        route: CoachRoute.explain(top.noteId),
      ));
    }

    // 4. Rétention.
    final retention = s.retentionRate;
    if (retention != null && retention < 0.7) {
      out.add(CoachAdvice(
        topic: CoachTopic.retention,
        title: 'Rétention à consolider (${(retention * 100).round()} %)',
        body: 'Révise tes cartes dues avant d’en créer de nouvelles, et '
            'reformule celles que tu oublies souvent.',
        actionLabel: s.dueCards > 0
            ? 'Réviser ${s.dueCards} carte${s.dueCards > 1 ? 's' : ''}'
            : 'Ouvrir les révisions',
        route: CoachRoute.review,
      ));
    } else if (s.dueCards >= 20) {
      out.add(CoachAdvice(
        topic: CoachTopic.retention,
        title: '${s.dueCards} cartes t’attendent',
        body: 'Fractionne : 15 minutes maintenant, 15 minutes ce soir. Le '
            'retard de révision se rattrape mieux par petites doses.',
        actionLabel: 'Réviser',
        route: CoachRoute.review,
      ));
    }

    // 5. Régularité des habitudes.
    if (s.habitCount > 0 && s.habitConsistency < 0.4) {
      out.add(const CoachAdvice(
        topic: CoachTopic.habits,
        title: 'Régularité en baisse',
        body: 'Garde une seule habitude cette semaine, la plus facile, et '
            'fais-la à heure fixe. La régularité compte plus que la quantité.',
        actionLabel: 'Voir mes habitudes',
        route: CoachRoute.habits,
      ));
    }

    // 6. Journal délaissé.
    final silent = s.daysSinceLastEntry;
    if (s.wellbeingEnabled && (silent == null || silent >= 3)) {
      out.add(CoachAdvice(
        topic: CoachTopic.journal,
        title: silent == null
            ? 'Commence ton journal'
            : 'Pas de bilan depuis $silent jours',
        body: 'Deux minutes après ta séance : humeur, énergie, effort. '
            'C’est ce qui me permet de te conseiller juste.',
        actionLabel: 'Écrire mon bilan',
        route: CoachRoute.journalEntry,
      ));
    }

    // 7. Encouragements, quand tout va bien.
    if (retention != null && retention >= 0.9) {
      out.add(const CoachAdvice(
        topic: CoachTopic.cheer,
        title: 'Rétention très solide',
        body: 'Tu peux ajouter de nouvelles cartes : ta mémoire suit le '
            'rythme.',
      ));
    }
    if (s.habitCount > 0 && s.habitConsistency >= 0.7) {
      out.add(const CoachAdvice(
        topic: CoachTopic.cheer,
        title: 'Belle régularité',
        body: 'Tes habitudes tiennent : c’est la base de tout le reste. '
            'Continue à ce rythme.',
      ));
    }

    if (out.isEmpty) {
      out.add(const CoachAdvice(
        topic: CoachTopic.cheer,
        title: 'Cap sur la séance',
        body: 'Avant de commencer, pose une intention claire : qu’auras-tu '
            'compris à la fin ?',
      ));
    }
    return out.take(limit).toList();
  }
}
