import '../../features/review/domain/spaced_repetition.dart';

/// Carte de révision — « Quiz/flashcard sur le même style que Tutorium et
/// Anki » (CdC).
class Flashcard {
  const Flashcard({
    required this.id,
    required this.userId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.schedule,
    this.noteId,
    this.deck,
    this.isSynced = true,
    this.folderId,
  });

  final String id;
  final String userId;

  /// Dossier de l'explorateur, `null` à la racine (déplacement uniquement).
  final String? folderId;

  /// Fiche d'origine, si la carte en a été tirée.
  final String? noteId;

  final String front;
  final String back;

  /// Paquet / matière. Reprend le sujet de la fiche d'origine par défaut.
  final String? deck;

  final DateTime createdAt;
  final ScheduleState schedule;
  final bool isSynced;

  bool get isDue => !schedule.dueAt.isAfter(DateTime.now());

  /// Carte jamais révisée : elle compte comme « nouvelle » dans le décompte
  /// du jour, et non comme un rappel.
  bool get isNew => schedule.repetitions == 0;

  /// Nombre de jours restants avant l'échéance (négatif si en retard).
  int get daysUntilDue {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final dueDay = DateTime(
      schedule.dueAt.year,
      schedule.dueAt.month,
      schedule.dueAt.day,
    );
    return dueDay.difference(startOfToday).inDays;
  }

  /// Taux d'échec, indicateur de carte mal formulée quand il reste élevé.
  double get lapseRate => schedule.repetitions == 0
      ? 0
      : schedule.lapses / schedule.repetitions;

  Flashcard copyWith({
    String? front,
    String? back,
    String? deck,
    bool clearDeck = false,
    ScheduleState? schedule,
    bool? isSynced,
  }) =>
      Flashcard(
        id: id,
        userId: userId,
        noteId: noteId,
        front: front ?? this.front,
        back: back ?? this.back,
        deck: clearDeck ? null : (deck ?? this.deck),
        createdAt: createdAt,
        schedule: schedule ?? this.schedule,
        isSynced: isSynced ?? this.isSynced,
        folderId: folderId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'note_id': noteId,
        'front': front,
        'back': back,
        'deck': deck,
        'step': schedule.step,
        'ease_factor': schedule.easeFactor,
        'due_at': schedule.dueAt.toUtc().toIso8601String(),
        'repetitions': schedule.repetitions,
        'lapses': schedule.lapses,
        'created_at': createdAt.toUtc().toIso8601String(),
        'folder_id': folderId,
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        noteId: json['note_id'] as String?,
        folderId: json['folder_id'] as String?,
        front: json['front'] as String? ?? '',
        back: json['back'] as String? ?? '',
        deck: json['deck'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        schedule: ScheduleState(
          step: (json['step'] as num?)?.toInt() ?? 0,
          easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
          dueAt: DateTime.parse(json['due_at'] as String).toLocal(),
          repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
          lapses: (json['lapses'] as num?)?.toInt() ?? 0,
          intervalDays: 0,
        ),
      );

  @override
  bool operator ==(Object other) => other is Flashcard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Compteurs de la file de révision du jour.
class ReviewQueueStats {
  const ReviewQueueStats({
    required this.dueCount,
    required this.newCount,
    required this.totalCards,
    required this.reviewedToday,
    required this.upcomingWeek,
  });

  const ReviewQueueStats.empty()
      : dueCount = 0,
        newCount = 0,
        totalCards = 0,
        reviewedToday = 0,
        upcomingWeek = const [];

  final int dueCount;
  final int newCount;
  final int totalCards;
  final int reviewedToday;

  /// Charge prévisionnelle des 7 prochains jours : anticiper évite les
  /// journées à 200 cartes.
  final List<int> upcomingWeek;

  bool get hasWork => dueCount > 0;
}

/// Auto-explication — mode « Explique-moi » (CdC).
class Explanation {
  const Explanation({
    required this.id,
    required this.userId,
    required this.noteId,
    required this.content,
    required this.confidence,
    required this.createdAt,
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String noteId;
  final String content;

  /// Confiance ressentie, de 1 à 5.
  final int confidence;

  final DateTime createdAt;
  final bool isSynced;

  int get wordCount =>
      content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'note_id': noteId,
        'content': content,
        'confidence': confidence,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory Explanation.fromJson(Map<String, dynamic> json) => Explanation(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        noteId: json['note_id'] as String,
        content: json['content'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toInt() ?? 3,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

/// Session de lecture guidée SQ3R.
class Sq3rSession {
  const Sq3rSession({
    required this.id,
    required this.userId,
    required this.noteId,
    required this.currentStep,
    required this.createdAt,
    required this.updatedAt,
    this.surveyNotes = '',
    this.questions = const [],
    this.reciteNotes = '',
    this.reviewNotes = '',
    this.completedAt,
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String noteId;
  final Sq3rStep currentStep;
  final String surveyNotes;
  final List<String> questions;
  final String reciteNotes;
  final String reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool isSynced;

  bool get isComplete => completedAt != null;

  double get progress => (currentStep.index + 1) / Sq3rStep.values.length;

  Sq3rSession copyWith({
    Sq3rStep? currentStep,
    String? surveyNotes,
    List<String>? questions,
    String? reciteNotes,
    String? reviewNotes,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool? isSynced,
  }) =>
      Sq3rSession(
        id: id,
        userId: userId,
        noteId: noteId,
        currentStep: currentStep ?? this.currentStep,
        surveyNotes: surveyNotes ?? this.surveyNotes,
        questions: questions ?? this.questions,
        reciteNotes: reciteNotes ?? this.reciteNotes,
        reviewNotes: reviewNotes ?? this.reviewNotes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt ?? this.completedAt,
        isSynced: isSynced ?? this.isSynced,
      );
}
