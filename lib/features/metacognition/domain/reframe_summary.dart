import '../../../shared/models/metacognition_model.dart';

/// Une étape du plan d'action proposé par le bilan.
class ReframeStep {
  const ReframeStep(this.text, {this.route, this.actionLabel});

  final String text;

  /// Écran de CognicQuest qui aide à faire l'étape.
  final String? route;
  final String? actionLabel;
}

/// Bilan personnalisé du recadrage, recalculé à chaque réponse : il
/// synthétise ce qui a été identifié et propose un plan d'action adapté à
/// la cause et au piège de pensée repérés.
class ReframeSummary {
  const ReframeSummary({
    required this.synthesis,
    required this.plan,
    required this.completeness,
    this.firstStep,
    this.reframed,
  });

  /// Ce que l'utilisateur a mis au jour, en phrases simples.
  final List<String> synthesis;

  /// Plan d'action : le premier pas de l'utilisateur, puis les étapes
  /// adaptées à la cause et au piège.
  final List<ReframeStep> plan;

  /// Part des six étapes renseignées (0 à 1).
  final double completeness;

  final String? firstStep;
  final String? reframed;

  bool get isEmpty => synthesis.isEmpty;

  static ReframeSummary build({
    required String thought,
    required List<String> digging,
    BlockerType? cause,
    CognitiveDistortion? distortion,
    String evidence = '',
    String reframed = '',
    String goal = '',
  }) {
    String clean(String s) => s.trim();
    final t = clean(thought);
    final answered = digging.map(clean).where((a) => a.isNotEmpty).toList();
    final filled = [
      t.isNotEmpty,
      answered.isNotEmpty || cause != null,
      distortion != null,
      clean(evidence).isNotEmpty,
      clean(reframed).isNotEmpty,
      clean(goal).isNotEmpty,
    ].where((x) => x).length;

    final synthesis = <String>[
      if (t.isNotEmpty) 'La pensée qui te freinait : « $t ».',
      if (answered.isNotEmpty)
        'En creusant, tu remontes à : « ${answered.last} ».',
      if (cause != null)
        'Cause principale : ${ReframeDigging.causeLabel(cause).toLowerCase()}.',
      if (distortion != null)
        'Piège repéré : ${distortion.label.toLowerCase()}.',
      if (clean(evidence).isNotEmpty)
        'Et les faits disent autre chose : « ${clean(evidence)} ».',
    ];

    final plan = <ReframeStep>[
      if (clean(goal).isNotEmpty)
        ReframeStep('Ton premier pas : ${clean(goal)}'),
      ..._forCause(cause),
      ..._forDistortion(distortion),
    ];
    if (plan.isEmpty && t.isNotEmpty) {
      plan.add(const ReframeStep(
          'Réponds aux questions « Creuse » : la cause guide le plan '
          'd’action.'));
    }

    return ReframeSummary(
      synthesis: synthesis,
      plan: plan,
      completeness: filled / 6,
      firstStep: clean(goal).isEmpty ? null : clean(goal),
      reframed: clean(reframed).isEmpty ? null : clean(reframed),
    );
  }

  static List<ReframeStep> _forCause(BlockerType? cause) => switch (cause) {
        BlockerType.cognitive => const [
            ReframeStep(
              'Reprends la notion en étude guidée : survol, questions, '
              'explication avec tes mots.',
              route: '/review/sq3r',
              actionLabel: 'Étude guidée',
            ),
            ReframeStep(
              'Puis un quiz ciblé : chaque erreur devient une carte à revoir '
              'aujourd’hui.',
              route: '/review/quiz',
              actionLabel: 'Quiz ciblé',
            ),
          ],
        BlockerType.emotional => const [
            ReframeStep(
              'Avant de t’y remettre : 2 minutes de respiration lente '
              '(4 s inspiration, 6 s expiration).',
            ),
            ReframeStep(
              'Une session Pomodoro courte (15 à 20 min) : commencer petit '
              'fait baisser l’anxiété plus vite que d’attendre d’être prêt.',
              route: '/pomodoro',
              actionLabel: 'Pomodoro',
            ),
            ReframeStep(
              'Ce soir, note ton humeur et ce qui a marché dans le journal.',
              route: '/journal/entry',
              actionLabel: 'Bilan du jour',
            ),
          ],
        BlockerType.sensory => const [
            ReframeStep(
              'Ton corps passe d’abord : une vraie pause (eau, lumière, '
              'quelques pas), et un coucher fixe ce soir.',
            ),
            ReframeStep(
              'Place tes révisions à ton heure la plus fraîche avec un '
              'rappel quotidien.',
              route: '/settings',
              actionLabel: 'Régler le rappel',
            ),
          ],
        BlockerType.environmental => const [
            ReframeStep(
              'Range ce qui t’attend dans la matrice d’Eisenhower : '
              'l’urgent-important d’abord, le reste planifié.',
              route: '/kanban',
              actionLabel: 'Organiser',
            ),
            ReframeStep(
              'Un lieu, un créneau, téléphone hors de vue : lance une session '
              'en mode concentration.',
              route: '/pomodoro',
              actionLabel: 'Pomodoro',
            ),
          ],
        null => const [],
      };

  static List<ReframeStep> _forDistortion(CognitiveDistortion? d) =>
      switch (d) {
        CognitiveDistortion.allOrNothing => const [
            ReframeStep('Remplace « réussi / raté » par une note sur 10 et '
                'vise +1, pas la perfection.'),
          ],
        CognitiveDistortion.overgeneralisation => const [
            ReframeStep('Compte : sur tes 5 derniers essais, combien de '
                'réussites ? Écris-le.'),
          ],
        CognitiveDistortion.labelling => const [
            ReframeStep('Décris l’action ratée, pas la personne : « j’ai '
                'raté l’exercice 3 », pas « je suis nul ».'),
          ],
        CognitiveDistortion.mindReading => const [
            ReframeStep('Vérifie plutôt que deviner : pose ta question au '
                'professeur ou à un camarade.'),
          ],
        CognitiveDistortion.catastrophising => const [
            ReframeStep('Écris le scénario le plus probable et ton plan B : '
                'le pire perd de sa force une fois écrit.'),
          ],
        CognitiveDistortion.discounting => const [
            ReframeStep('Note une réussite par jour cette semaine, même '
                'petite, et relis-les vendredi.'),
          ],
        null => const [],
      };
}
