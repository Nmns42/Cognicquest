/// Type d'erreur — « regroupe les types d'erreurs commises par l'élève
/// (erreurs d'inattention vs erreurs de compréhension) » (CdC).
///
/// La distinction est la clé de la remédiation : une erreur d'inattention et
/// une erreur de compréhension appellent des réponses opposées.
enum ErrorType {
  inattention(
    'inattention',
    'Inattention',
    'Je savais, mais j\'ai mal lu, mal recopié, oublié un signe.',
    'Ralentis et relis. Ce n\'est pas un manque de savoir.',
  ),
  comprehension(
    'comprehension',
    'Compréhension',
    'Je n\'ai pas compris la notion elle-même.',
    'Reprends la notion à la source, puis reformule-la (Explique-moi).',
  ),
  method(
    'method',
    'Méthode',
    'Je comprends, mais j\'ai mal choisi ou mal appliqué la démarche.',
    'Refais des exercices du même type pour ancrer la démarche.',
  ),
  memorisation(
    'memorisation',
    'Mémorisation',
    'La notion ne me revenait pas au moment voulu.',
    'Crée une carte de révision : c\'est un problème de rappel.',
  ),
  instructions(
    'instructions',
    'Consigne',
    'J\'ai répondu à côté de ce qui était demandé.',
    'Décode la consigne avant de répondre : reformule l\'attendu.',
  );

  const ErrorType(this.value, this.label, this.description, this.remedy);

  final String value;
  final String label;
  final String description;

  /// Conseil de remédiation associé.
  final String remedy;

  static ErrorType fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return ErrorType.comprehension;
  }
}

/// Nature du frein rencontré — « un module pour identifier si le frein est
/// cognitif, émotionnel, sensoriel ou environnemental » (CdC).
enum BlockerType {
  cognitive('cognitive', 'Cognitif', 'La notion résiste, la charge est trop lourde.'),
  emotional('emotional', 'Émotionnel', 'Stress, peur de l\'échec, découragement.'),
  sensory('sensory', 'Sensoriel', 'Bruit, lumière, fatigue visuelle, inconfort.'),
  environmental(
    'environmental',
    'Environnemental',
    'Lieu, interruptions, matériel, organisation.',
  );

  const BlockerType(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static BlockerType? fromValue(String? value) {
    if (value == null) return null;
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Distorsions cognitives courantes, pour le recadrage.
enum CognitiveDistortion {
  allOrNothing(
    'all_or_nothing',
    'Tout ou rien',
    'Soit je réussis parfaitement, soit j\'ai tout raté.',
  ),
  overgeneralisation(
    'overgeneralisation',
    'Généralisation',
    'Un échec devient « je n\'y arrive jamais ».',
  ),
  labelling(
    'labelling',
    'Étiquetage',
    'Je confonds ce que j\'ai fait et ce que je suis.',
  ),
  mindReading(
    'mind_reading',
    'Lecture de pensée',
    'Je suppose ce que les autres pensent de moi.',
  ),
  catastrophising(
    'catastrophising',
    'Catastrophisme',
    'J\'imagine le pire scénario comme s\'il était certain.',
  ),
  discounting(
    'discounting',
    'Minimisation',
    'Mes réussites « ne comptent pas ».',
  );

  const CognitiveDistortion(this.value, this.label, this.example);

  final String value;
  final String label;
  final String example;

  static CognitiveDistortion? fromValue(String? value) {
    if (value == null) return null;
    for (final distortion in values) {
      if (distortion.value == value) return distortion;
    }
    return null;
  }
}

/// Entrée du journal métacognitif, humeur et effort compris.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.energy,
    required this.rpe,
    required this.createdAt,
    this.noteId,
    this.whatLearned = '',
    this.whatWorked = '',
    this.whatBlocked = '',
    this.nextStep = '',
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String? noteId;

  /// 1 à 5.
  final int mood;

  /// 1 à 5.
  final int energy;

  /// 1 à 10 : perception de l'effort fourni.
  final int rpe;

  final String whatLearned;
  final String whatWorked;
  final String whatBlocked;
  final String nextStep;
  final DateTime createdAt;
  final bool isSynced;

  bool get hasWrittenReflection =>
      whatLearned.trim().isNotEmpty ||
      whatWorked.trim().isNotEmpty ||
      whatBlocked.trim().isNotEmpty ||
      nextStep.trim().isNotEmpty;

  /// Effort élevé pour un moral bas : la combinaison qui précède l'épuisement.
  bool get isStrainedDay => rpe >= 8 && mood <= 2;

  JournalEntry copyWith({
    int? mood,
    int? energy,
    int? rpe,
    String? whatLearned,
    String? whatWorked,
    String? whatBlocked,
    String? nextStep,
    bool? isSynced,
  }) =>
      JournalEntry(
        id: id,
        userId: userId,
        noteId: noteId,
        mood: mood ?? this.mood,
        energy: energy ?? this.energy,
        rpe: rpe ?? this.rpe,
        whatLearned: whatLearned ?? this.whatLearned,
        whatWorked: whatWorked ?? this.whatWorked,
        whatBlocked: whatBlocked ?? this.whatBlocked,
        nextStep: nextStep ?? this.nextStep,
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'note_id': noteId,
        'mood': mood,
        'energy': energy,
        'rpe': rpe,
        'what_learned': whatLearned,
        'what_worked': whatWorked,
        'what_blocked': whatBlocked,
        'next_step': nextStep,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

/// Pensée bloquante recadrée.
class Reframe {
  const Reframe({
    required this.id,
    required this.userId,
    required this.limitingThought,
    required this.createdAt,
    this.distortion,
    this.evidenceAgainst = '',
    this.reframedThought = '',
    this.growthGoal = '',
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String limitingThought;
  final CognitiveDistortion? distortion;
  final String evidenceAgainst;
  final String reframedThought;

  /// Objectif de croissance : ce que le CdC appelle transformer la pensée
  /// bloquante « en objectif de croissance ».
  final String growthGoal;

  final DateTime createdAt;
  final bool isSynced;

  bool get isComplete =>
      reframedThought.trim().isNotEmpty && growthGoal.trim().isNotEmpty;

  Reframe copyWith({
    CognitiveDistortion? distortion,
    String? evidenceAgainst,
    String? reframedThought,
    String? growthGoal,
    bool? isSynced,
  }) =>
      Reframe(
        id: id,
        userId: userId,
        limitingThought: limitingThought,
        distortion: distortion ?? this.distortion,
        evidenceAgainst: evidenceAgainst ?? this.evidenceAgainst,
        reframedThought: reframedThought ?? this.reframedThought,
        growthGoal: growthGoal ?? this.growthGoal,
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
}

/// Chaîne des 5 Pourquoi.
class WhyChain {
  const WhyChain({
    required this.id,
    required this.userId,
    required this.problem,
    required this.answers,
    required this.createdAt,
    this.rootCause = '',
    this.blockerType,
    this.actionPlan = '',
    this.isSynced = true,
  });

  static const int maxDepth = 5;

  final String id;
  final String userId;
  final String problem;

  /// Réponses successives aux « pourquoi ».
  final List<String> answers;

  final String rootCause;
  final BlockerType? blockerType;
  final String actionPlan;
  final DateTime createdAt;
  final bool isSynced;

  int get depth => answers.where((a) => a.trim().isNotEmpty).length;

  bool get canGoDeeper => depth < maxDepth;

  /// La chaîne n'a de valeur que si elle aboutit à une cause et à une action :
  /// s'arrêter au diagnostic, c'est ruminer.
  bool get isComplete =>
      depth >= 3 && rootCause.trim().isNotEmpty && actionPlan.trim().isNotEmpty;

  /// Libellé de la question suivante, numérotée.
  String get nextQuestion => depth == 0
      ? 'Pourquoi cela arrive-t-il ?'
      : 'Pourquoi ${depth + 1} : et pourquoi cela ?';

  WhyChain copyWith({
    List<String>? answers,
    String? rootCause,
    BlockerType? blockerType,
    String? actionPlan,
    bool? isSynced,
  }) =>
      WhyChain(
        id: id,
        userId: userId,
        problem: problem,
        answers: answers ?? this.answers,
        rootCause: rootCause ?? this.rootCause,
        blockerType: blockerType ?? this.blockerType,
        actionPlan: actionPlan ?? this.actionPlan,
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
}

/// Erreur consignée.
class ErrorLog {
  const ErrorLog({
    required this.id,
    required this.userId,
    required this.description,
    required this.errorType,
    required this.createdAt,
    this.noteId,
    this.subject,
    this.correction = '',
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String? noteId;
  final String? subject;
  final String description;
  final ErrorType errorType;
  final String correction;
  final DateTime createdAt;
  final bool isSynced;

  bool get isCorrected => correction.trim().isNotEmpty;
}
