/// Nature d'une relation entre deux fiches.
///
/// Le CdC demande que « les liens montrent les relations logiques ou
/// temporelles ("vu", "à revoir", "lié à…") ».
enum NoteLinkType {
  related('related', 'Lié à', false),
  seen('seen', 'Vu', true),
  toReview('to_review', 'À revoir', true),
  prerequisite('prerequisite', 'Prérequis de', true);

  const NoteLinkType(this.value, this.label, this.isDirected);

  final String value;
  final String label;

  /// `false` pour « lié à » : la relation se lit dans les deux sens, donc le
  /// graphe la dessine sans flèche.
  final bool isDirected;

  static NoteLinkType fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return NoteLinkType.related;
  }
}

class NoteLink {
  const NoteLink({
    required this.id,
    required this.userId,
    required this.sourceId,
    required this.targetId,
    required this.type,
    required this.createdAt,
    this.label,
    this.isSynced = true,
  });

  final String id;
  final String userId;
  final String sourceId;
  final String targetId;
  final NoteLinkType type;
  final String? label;
  final DateTime createdAt;
  final bool isSynced;

  /// `true` si le lien touche la fiche donnée, quel que soit le sens.
  bool touches(String noteId) => sourceId == noteId || targetId == noteId;

  /// L'autre extrémité du lien, vue depuis [noteId].
  String? otherEnd(String noteId) {
    if (sourceId == noteId) return targetId;
    if (targetId == noteId) return sourceId;
    return null;
  }

  /// Deux liens sont équivalents s'ils relient les mêmes fiches avec le même
  /// type — dans les deux sens pour une relation non orientée.
  bool isSameEdgeAs(NoteLink other) {
    if (type != other.type) return false;
    if (sourceId == other.sourceId && targetId == other.targetId) return true;
    return !type.isDirected &&
        sourceId == other.targetId &&
        targetId == other.sourceId;
  }

  NoteLink copyWith({NoteLinkType? type, String? label, bool? isSynced}) =>
      NoteLink(
        id: id,
        userId: userId,
        sourceId: sourceId,
        targetId: targetId,
        type: type ?? this.type,
        label: label ?? this.label,
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'source_id': sourceId,
        'target_id': targetId,
        'type': type.value,
        'label': label,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory NoteLink.fromJson(Map<String, dynamic> json) => NoteLink(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        sourceId: json['source_id'] as String,
        targetId: json['target_id'] as String,
        type: NoteLinkType.fromValue(json['type'] as String?),
        label: json['label'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  @override
  bool operator ==(Object other) => other is NoteLink && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Lien proposé automatiquement, pas encore confirmé par l'utilisateur.
///
/// CdC : « Suggestions d'association dans le graphe pour mieux connecter les
/// connaissances ».
class SuggestedLink {
  const SuggestedLink({
    required this.sourceId,
    required this.targetId,
    required this.reason,
    required this.score,
  });

  final String sourceId;
  final String targetId;

  /// Motif lisible : « 2 tags en commun », « même sujet »…
  final String reason;

  /// Plus le score est élevé, plus la proposition est pertinente.
  final int score;
}
