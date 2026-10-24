import 'dart:convert';

/// Types de blocs composant une fiche — « Blocs de texte, listes, cases à
/// cocher, citations, fichiers, images, liens » (CdC).
enum NoteBlockType {
  paragraph('paragraph', 'Texte'),
  heading('heading', 'Titre'),
  bulleted('bulleted', 'Liste'),
  todo('todo', 'Case à cocher'),
  quote('quote', 'Citation'),
  code('code', 'Code'),
  image('image', 'Image'),
  video('video', 'Vidéo'),
  link('link', 'Lien'),
  divider('divider', 'Séparateur'),

  /// PDF importé et annoté (contenu : JSON, cf. `PdfBlockData`).
  pdf('pdf', 'PDF');

  const NoteBlockType(this.value, this.label);

  final String value;
  final String label;

  static NoteBlockType fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return NoteBlockType.paragraph;
  }

  bool get isTextual => !isMedia && this != NoteBlockType.divider;

  /// Bloc d'image ou de vidéo : son contenu est une adresse (lien, fichier
  /// de l'appareil ou image encodée), jamais du texte à lire ni à chercher.
  bool get isMedia =>
      this == NoteBlockType.image ||
      this == NoteBlockType.video ||
      this == NoteBlockType.pdf;
}

class NoteBlock {
  const NoteBlock({
    required this.id,
    required this.noteId,
    required this.type,
    required this.content,
    required this.position,
    this.isChecked = false,
  });

  final String id;
  final String noteId;
  final NoteBlockType type;
  final String content;
  final int position;
  final bool isChecked;

  NoteBlock copyWith({
    NoteBlockType? type,
    String? content,
    int? position,
    bool? isChecked,
  }) =>
      NoteBlock(
        id: id,
        noteId: noteId,
        type: type ?? this.type,
        content: content ?? this.content,
        position: position ?? this.position,
        isChecked: isChecked ?? this.isChecked,
      );

  /// Rendu Markdown d'un bloc, utilisé par l'aperçu et l'export.
  String toMarkdown() => switch (type) {
        NoteBlockType.heading => '## $content',
        NoteBlockType.bulleted => '- $content',
        NoteBlockType.todo => '- [${isChecked ? 'x' : ' '}] $content',
        NoteBlockType.quote => '> $content',
        NoteBlockType.code => '```\n$content\n```',
        NoteBlockType.image => '![]($content)',
        NoteBlockType.video => '[Vidéo]($content)',
        NoteBlockType.link => '<$content>',
        NoteBlockType.divider => '---',
        NoteBlockType.pdf => _pdfMarkdown(content),
        NoteBlockType.paragraph => content,
      };

  /// « [PDF : cours.pdf](media://…) » : lien lisible dans un export.
  static String _pdfMarkdown(String content) {
    try {
      final json = jsonDecode(content) as Map;
      return '[PDF : ${json['name'] ?? 'document'}](${json['src'] ?? ''})';
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'note_id': noteId,
        'type': type.value,
        'content': content,
        'position': position,
        'is_checked': isChecked,
      };

  factory NoteBlock.fromJson(Map<String, dynamic> json) => NoteBlock(
        id: json['id'] as String,
        noteId: json['note_id'] as String,
        type: NoteBlockType.fromValue(json['type'] as String?),
        content: json['content'] as String? ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        isChecked: json['is_checked'] as bool? ?? false,
      );
}

/// Fiche de connaissance.
class Note {
  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
    this.tags = const [],
    this.importance = 1,
    this.isFavorite = false,
    this.isArchived = false,
    this.blocks = const [],
    this.isSynced = true,
    this.position,
    this.folderId,
  });

  final String id;
  final String userId;
  final String title;

  /// Dossier de l'explorateur, `null` à la racine. Écrit uniquement par le
  /// déplacement (comme [position]) : une sauvegarde ne le touche jamais.
  final String? folderId;

  /// Clé d'ordre manuel (cf. `FractionalKey`), `null` tant que la fiche n'a
  /// jamais été placée à la main. Écrite uniquement par le réordonnancement :
  /// [copyWith] la conserve, une sauvegarde ne la touche jamais.
  final String? position;

  /// Corps libre en Markdown. Coexiste avec [blocks] : le texte long reste
  /// confortable à saisir d'un bloc, les blocs structurés servent aux
  /// check-lists, citations et ressources.
  final String content;

  final String? subject;
  final List<String> tags;

  /// 0 = normale, 1 = à revoir, 2 = essentielle. Sert au filtre « importance ».
  final int importance;

  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<NoteBlock> blocks;

  /// `false` tant que la fiche n'a pas été poussée vers Supabase : l'interface
  /// peut alors afficher un indicateur « en attente de synchronisation ».
  final bool isSynced;

  String get displayTitle => title.trim().isEmpty ? 'Sans titre' : title.trim();

  /// Extrait de prévisualisation, tous blocs confondus.
  String get excerpt {
    final raw = content.trim().isNotEmpty
        ? content
        : blocks
            .where((b) => b.type.isTextual)
            .map((b) => b.content)
            .where((c) => c.isNotEmpty)
            .join(' · ');
    final flattened = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flattened.length <= 120 ? flattened : '${flattened.substring(0, 119)}…';
  }

  int get checklistTotal =>
      blocks.where((b) => b.type == NoteBlockType.todo).length;

  int get checklistDone =>
      blocks.where((b) => b.type == NoteBlockType.todo && b.isChecked).length;

  /// Texte indexé par la recherche : titre, sujet, tags et corps.
  String get searchableText => [
        title,
        subject ?? '',
        tags.join(' '),
        content,
        // Une image encodée ou un lien de vidéo ne se cherche pas.
        ...blocks.where((b) => !b.type.isMedia).map((b) => b.content),
      ].join(' ').toLowerCase();

  /// Taille approximative de la fiche (Markdown complet, en octets UTF-8),
  /// pour la fenêtre « Propriétés ».
  int get sizeInBytes => utf8.encode(toMarkdown()).length;

  String toMarkdown() {
    final buffer = StringBuffer('# $displayTitle\n');
    if (content.trim().isNotEmpty) buffer.write('\n${content.trim()}\n');
    for (final block in blocks) {
      buffer.write('\n${block.toMarkdown()}\n');
    }
    return buffer.toString();
  }

  Note copyWith({
    String? title,
    String? content,
    String? subject,
    bool clearSubject = false,
    List<String>? tags,
    int? importance,
    bool? isFavorite,
    bool? isArchived,
    DateTime? updatedAt,
    List<NoteBlock>? blocks,
    bool? isSynced,
  }) =>
      Note(
        id: id,
        userId: userId,
        title: title ?? this.title,
        content: content ?? this.content,
        subject: clearSubject ? null : (subject ?? this.subject),
        tags: tags ?? this.tags,
        importance: importance ?? this.importance,
        isFavorite: isFavorite ?? this.isFavorite,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        blocks: blocks ?? this.blocks,
        isSynced: isSynced ?? this.isSynced,
        position: position,
        folderId: folderId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'subject': subject,
        'tags': tags,
        'importance': importance,
        'is_favorite': isFavorite,
        'is_archived': isArchived,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory Note.fromJson(
    Map<String, dynamic> json, {
    List<NoteBlock> blocks = const [],
  }) =>
      Note(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        subject: json['subject'] as String?,
        tags: decodeTags(json['tags']),
        importance: (json['importance'] as num?)?.toInt() ?? 1,
        isFavorite: json['is_favorite'] as bool? ?? false,
        isArchived: json['is_archived'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
        blocks: blocks,
      );

  /// Les tags arrivent soit en `jsonb` (liste) depuis Supabase, soit en chaîne
  /// JSON depuis SQLite : un seul point de décodage évite les divergences.
  static List<String> decodeTags(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.whereType<String>().map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }
    if (raw is String) {
      if (raw.trim().isEmpty) return const [];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decodeTags(decoded);
      } catch (_) {
        // Chaîne non-JSON : on tolère une liste séparée par des virgules.
        return raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      }
    }
    return const [];
  }

  static String encodeTags(List<String> tags) => jsonEncode(
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      );

  @override
  bool operator ==(Object other) => other is Note && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Importance, exposée sous forme lisible pour les filtres.
enum NoteImportance {
  normal(0, 'Normale'),
  review(1, 'À revoir'),
  essential(2, 'Essentielle');

  const NoteImportance(this.level, this.label);

  final int level;
  final String label;

  static NoteImportance fromLevel(int level) => switch (level) {
        2 => NoteImportance.essential,
        0 => NoteImportance.normal,
        _ => NoteImportance.review,
      };
}
