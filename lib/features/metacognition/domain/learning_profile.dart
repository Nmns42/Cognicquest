/// Façon de traiter l'information — « L'app devrait suggérer des outils
/// différents selon que le profil est "global" (besoin de voir l'ensemble) ou
/// "séquentiel" (besoin d'étapes) » (CdC).
enum ProcessingStyle {
  global(
    'global',
    'Global',
    'Tu as besoin de voir l\'ensemble avant les détails.',
  ),
  sequential(
    'sequential',
    'Séquentiel',
    'Tu avances mieux étape par étape, dans l\'ordre.',
  );

  const ProcessingStyle(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static ProcessingStyle? fromValue(String? value) {
    if (value == null) return null;
    for (final style in values) {
      if (style.value == value) return style;
    }
    return null;
  }
}

/// Canal d'entrée privilégié. Le CdC s'appuie sur les apprentissages visuel,
/// auditif et kinesthésique.
enum PreferredChannel {
  visual('visual', 'Visuel', 'Schémas, cartes mentales, couleurs'),
  auditory('auditory', 'Auditif', 'Explications à voix haute, réécoute'),
  kinesthetic('kinesthetic', 'Kinesthésique', 'Manipulation, mouvement, pratique'),
  reading('reading', 'Lecture / écriture', 'Textes, reformulation écrite');

  const PreferredChannel(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static PreferredChannel? fromValue(String? value) {
    if (value == null) return null;
    for (final channel in values) {
      if (channel.value == value) return channel;
    }
    return null;
  }
}

/// Une question du questionnaire de profilage.
class ProfilingQuestion {
  const ProfilingQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String prompt;
  final List<ProfilingOption> options;
}

/// Une réponse possible, et ce qu'elle fait pencher.
class ProfilingOption {
  const ProfilingOption({
    required this.value,
    required this.label,
    this.style,
    this.channel,
  });

  final String value;
  final String label;
  final ProcessingStyle? style;
  final PreferredChannel? channel;
}

/// Profil d'apprentissage calculé — le « mode d'emploi » de l'apprenant que le
/// CdC veut lui donner **avant** qu'il commence.
class LearningProfile {
  const LearningProfile({
    required this.answers,
    this.processingStyle,
    this.preferredChannel,
    this.completedAt,
  });

  static const LearningProfile empty = LearningProfile(answers: {});

  /// Réponses brutes : question → valeur choisie.
  final Map<String, String> answers;

  final ProcessingStyle? processingStyle;
  final PreferredChannel? preferredChannel;
  final DateTime? completedAt;

  bool get isComplete => completedAt != null;

  double get progress =>
      answers.length / ProfilingQuestionnaire.questions.length;

  /// Recommandations d'outils, dérivées du profil.
  ///
  /// C'est la « personnalisation prédictive » du CdC : on ne se contente pas
  /// d'étiqueter l'apprenant, on lui dit quoi faire de cette étiquette.
  List<String> get recommendations {
    final tips = <String>[];

    switch (processingStyle) {
      case ProcessingStyle.global:
        tips.add(
          'Commence par le graphe de connaissances : voir l\'ensemble avant '
          'd\'entrer dans le détail te fait gagner du temps.',
        );
        tips.add(
          'Survole toujours un cours en entier (étape « Survol » du SQ3R) '
          'avant de le lire ligne à ligne.',
        );
      case ProcessingStyle.sequential:
        tips.add(
          'Découpe tes fiches en petites étapes numérotées plutôt qu\'en '
          'longs blocs.',
        );
        tips.add(
          'Le Kanban te servira plus que le graphe : une tâche après l\'autre, '
          'dans l\'ordre.',
        );
      case null:
        break;
    }

    switch (preferredChannel) {
      case PreferredChannel.visual:
        tips.add('Ajoute des schémas et code tes fiches par couleur de sujet.');
      case PreferredChannel.auditory:
        tips.add(
          'Utilise « Explique-moi » à voix haute avant d\'écrire : '
          'tu retiendras davantage.',
        );
      case PreferredChannel.kinesthetic:
        tips.add(
          'Alterne 25 min de travail et de vraies pauses actives : '
          'le mouvement fait partie de ta mémorisation.',
        );
      case PreferredChannel.reading:
        tips.add(
          'Reformule systématiquement par écrit : c\'est ton canal le plus '
          'efficace.',
        );
      case null:
        break;
    }

    return tips;
  }

  LearningProfile copyWith({
    Map<String, String>? answers,
    ProcessingStyle? processingStyle,
    PreferredChannel? preferredChannel,
    DateTime? completedAt,
  }) =>
      LearningProfile(
        answers: answers ?? this.answers,
        processingStyle: processingStyle ?? this.processingStyle,
        preferredChannel: preferredChannel ?? this.preferredChannel,
        completedAt: completedAt ?? this.completedAt,
      );
}

/// Le questionnaire de profilage et son dépouillement.
abstract final class ProfilingQuestionnaire {
  static const List<ProfilingQuestion> questions = [
    ProfilingQuestion(
      id: 'new_topic',
      prompt: 'Face à un chapitre entièrement nouveau, tu préfères…',
      options: [
        ProfilingOption(
          value: 'overview',
          label: 'En avoir une vue d\'ensemble avant tout',
          style: ProcessingStyle.global,
        ),
        ProfilingOption(
          value: 'step',
          label: 'Commencer au début et avancer pas à pas',
          style: ProcessingStyle.sequential,
        ),
      ],
    ),
    ProfilingQuestion(
      id: 'stuck',
      prompt: 'Quand tu bloques sur un exercice…',
      options: [
        ProfilingOption(
          value: 'context',
          label: 'Tu relies au contexte général pour comprendre à quoi ça sert',
          style: ProcessingStyle.global,
        ),
        ProfilingOption(
          value: 'method',
          label: 'Tu reprends la méthode étape par étape',
          style: ProcessingStyle.sequential,
        ),
      ],
    ),
    ProfilingQuestion(
      id: 'remember',
      prompt: 'Tu retiens le mieux une notion quand…',
      options: [
        ProfilingOption(
          value: 'diagram',
          label: 'Tu l\'as vue sous forme de schéma',
          channel: PreferredChannel.visual,
        ),
        ProfilingOption(
          value: 'said',
          label: 'Tu l\'as entendue ou dite à voix haute',
          channel: PreferredChannel.auditory,
        ),
        ProfilingOption(
          value: 'done',
          label: 'Tu l\'as mise en pratique, manipulée',
          channel: PreferredChannel.kinesthetic,
        ),
        ProfilingOption(
          value: 'written',
          label: 'Tu l\'as reformulée par écrit',
          channel: PreferredChannel.reading,
        ),
      ],
    ),
    ProfilingQuestion(
      id: 'explain',
      prompt: 'Pour expliquer une notion à quelqu\'un, tu…',
      options: [
        ProfilingOption(
          value: 'draw',
          label: 'Fais un dessin ou un schéma',
          channel: PreferredChannel.visual,
        ),
        ProfilingOption(
          value: 'talk',
          label: 'Racontes, avec des mots et des exemples',
          channel: PreferredChannel.auditory,
        ),
        ProfilingOption(
          value: 'show',
          label: 'Montres en faisant',
          channel: PreferredChannel.kinesthetic,
        ),
        ProfilingOption(
          value: 'write',
          label: 'Écris une explication structurée',
          channel: PreferredChannel.reading,
        ),
      ],
    ),
    ProfilingQuestion(
      id: 'plan',
      prompt: 'Ton planning de révision idéal ressemble à…',
      options: [
        ProfilingOption(
          value: 'themes',
          label: 'Des grands thèmes que tu attaques selon l\'envie',
          style: ProcessingStyle.global,
        ),
        ProfilingOption(
          value: 'slots',
          label: 'Des créneaux précis, dans un ordre défini',
          style: ProcessingStyle.sequential,
        ),
      ],
    ),
  ];

  /// Dépouille les réponses et en déduit le profil.
  ///
  /// En cas d'égalité, on ne tranche pas au hasard : la dimension reste nulle
  /// et l'application ne prétend pas savoir. Un profil inventé serait pire
  /// qu'un profil absent.
  static LearningProfile score(
    Map<String, String> answers, {
    DateTime? completedAt,
  }) {
    final styleVotes = <ProcessingStyle, int>{};
    final channelVotes = <PreferredChannel, int>{};

    for (final question in questions) {
      final chosen = answers[question.id];
      if (chosen == null) continue;

      for (final option in question.options) {
        if (option.value != chosen) continue;
        if (option.style != null) {
          styleVotes[option.style!] = (styleVotes[option.style!] ?? 0) + 1;
        }
        if (option.channel != null) {
          channelVotes[option.channel!] =
              (channelVotes[option.channel!] ?? 0) + 1;
        }
      }
    }

    return LearningProfile(
      answers: answers,
      processingStyle: _winner(styleVotes),
      preferredChannel: _winner(channelVotes),
      completedAt: completedAt,
    );
  }

  /// Renvoie la valeur strictement majoritaire, ou `null` en cas d'égalité.
  static T? _winner<T>(Map<T, int> votes) {
    if (votes.isEmpty) return null;

    T? best;
    var bestCount = 0;
    var tied = false;

    votes.forEach((key, count) {
      if (count > bestCount) {
        best = key;
        bestCount = count;
        tied = false;
      } else if (count == bestCount) {
        tied = true;
      }
    });

    return tied ? null : best;
  }
}
