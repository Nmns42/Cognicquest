import 'dart:convert';

/// Outil d'annotation d'un PDF.
enum PdfMarkKind {
  highlight('Surligner'),
  underline('Souligner'),
  strike('Barrer');

  const PdfMarkKind(this.label);

  final String label;

  static PdfMarkKind fromName(String? name) => values
      .firstWhere((k) => k.name == name, orElse: () => PdfMarkKind.highlight);
}

/// Rectangle en coordonnées de page PDF (points, origine en bas à gauche,
/// [top] ≥ [bottom]) : indépendant du zoom et de l'écran.
class PdfBox {
  const PdfBox(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  List<double> toJson() => [left, top, right, bottom];

  static PdfBox? fromJson(Object? raw) {
    if (raw is! List || raw.length != 4) return null;
    final v = [for (final n in raw) (n as num).toDouble()];
    return PdfBox(v[0], v[1], v[2], v[3]);
  }
}

/// Une annotation : un passage du PDF surligné, souligné ou barré.
class PdfMark {
  const PdfMark({
    required this.id,
    required this.page,
    required this.kind,
    required this.color,
    required this.boxes,
    this.text = '',
  });

  final String id;

  /// Numéro de page, à partir de 1.
  final int page;
  final PdfMarkKind kind;

  /// Nom de couleur (cf. `HighlightPalette`).
  final String color;
  final List<PdfBox> boxes;

  /// Texte annoté, pour la liste des annotations.
  final String text;

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'kind': kind.name,
        'color': color,
        'boxes': [for (final b in boxes) b.toJson()],
        if (text.isNotEmpty) 'text': text,
      };

  static PdfMark? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final boxes = [
      for (final b in (raw['boxes'] as List?) ?? const [])
        if (PdfBox.fromJson(b) case final box?) box,
    ];
    final page = (raw['page'] as num?)?.toInt();
    if (page == null || page < 1 || boxes.isEmpty) return null;
    return PdfMark(
      id: raw['id'] as String? ?? '$page-${boxes.first.left}',
      page: page,
      kind: PdfMarkKind.fromName(raw['kind'] as String?),
      color: raw['color'] as String? ?? 'jaune',
      boxes: boxes,
      text: raw['text'] as String? ?? '',
    );
  }
}

/// Contenu d'un bloc PDF : le fichier (référence Storage `media://…`), son
/// nom et ses annotations, enregistrés en JSON dans le texte du bloc.
class PdfBlockData {
  const PdfBlockData({
    required this.source,
    required this.name,
    this.marks = const [],
  });

  static const PdfBlockData empty = PdfBlockData(source: '', name: '');

  final String source;
  final String name;
  final List<PdfMark> marks;

  bool get isEmpty => source.isEmpty;

  PdfBlockData copyWith({List<PdfMark>? marks}) =>
      PdfBlockData(source: source, name: name, marks: marks ?? this.marks);

  String encode() => isEmpty
      ? ''
      : jsonEncode({
          'src': source,
          'name': name,
          'marks': [for (final m in marks) m.toJson()],
        });

  /// Tolérant : un contenu vide ou abîmé donne un bloc vide (à importer de
  /// nouveau) plutôt qu'une erreur.
  static PdfBlockData decode(String content) {
    if (content.trim().isEmpty) return empty;
    try {
      final json = jsonDecode(content);
      if (json is! Map) return empty;
      return PdfBlockData(
        source: json['src'] as String? ?? '',
        name: json['name'] as String? ?? 'Document.pdf',
        marks: [
          for (final m in (json['marks'] as List?) ?? const [])
            if (PdfMark.fromJson(m) case final mark?) mark,
        ],
      );
    } catch (_) {
      return empty;
    }
  }
}
