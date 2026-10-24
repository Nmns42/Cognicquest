import 'dart:convert';
import 'dart:typed_data';

import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/pdf_palette.dart';
import '../../../shared/models/note_model.dart';
import 'pdf_annotations.dart';
import 'rich_text_format.dart';

/// Polices embarquées dans le PDF (celles de l'app : accents, ligatures).
class PdfFonts {
  const PdfFonts({
    required this.regular,
    required this.bold,
    required this.serif,
    required this.serifBold,
    this.fallback,
  });

  final pw.Font regular;

  /// Glyphes absents des polices de l'app (grec, cyrillique, flèches).
  final pw.Font? fallback;
  final pw.Font bold;

  /// Italique rendu en serif (Fraunces) : l'app n'embarque pas de Plus
  /// Jakarta Sans italique, et la serif marque l'emphase avec élégance.
  final pw.Font serif;
  final pw.Font serifBold;

  factory PdfFonts.fromBytes({
    required ByteData regular,
    required ByteData bold,
    required ByteData serif,
    required ByteData serifBold,
    ByteData? fallback,
  }) =>
      PdfFonts(
        regular: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
        serif: pw.Font.ttf(serif),
        serifBold: pw.Font.ttf(serifBold),
        fallback: fallback == null ? null : pw.Font.ttf(fallback),
      );
}

/// Charge les octets d'une image (`media://…`, `data:…`) ; `null` si
/// indisponible (le PDF affiche alors une mention à la place).
typedef PdfImageLoader = Future<Uint8List?> Function(String source);

/// Export d'une fiche en PDF A4, mise en forme comprise : titres, gras,
/// italique, souligné, barré, surligné en couleur, alignements, listes,
/// citations, code, images, et mention des PDF annotés joints.
class NotePdfExporter {
  NotePdfExporter({required this.fonts, required this.loadImage});

  final PdfFonts fonts;
  final PdfImageLoader loadImage;

  final Map<String, pw.MemoryImage?> _images = {};

  static final md.ExtensionSet _extensions = md.ExtensionSet(
    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    [
      _UnderlineSyntax(),
      _HighlightSyntax(),
      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
    ],
  );

  Future<Uint8List> build(Note note) async {
    final segments = [
      for (final (alignment, text) in RichTextFormat.segments(note.content))
        if (text.trim().isNotEmpty) (alignment, _parse(text)),
    ];
    final blockNodes = [
      for (final block in note.blocks)
        if (block.type != NoteBlockType.pdf)
          (block, _parse(block.toMarkdown())),
    ];

    // Images chargées avant la mise en page (elle est synchrone).
    final sources = <String>{
      for (final (_, nodes) in segments) ..._imageSources(nodes),
      for (final (_, nodes) in blockNodes) ..._imageSources(nodes),
    };
    for (final source in sources) {
      final bytes = await _bytesOf(source);
      _images[source] = bytes == null ? null : pw.MemoryImage(bytes);
    }

    final doc = pw.Document(title: note.displayTitle, author: 'CognicQuest');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 56, 56, 64),
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
        italic: fonts.serif,
        boldItalic: fonts.serifBold,
      ).copyWith(
        defaultTextStyle: pw.TextStyle(
            font: fonts.regular,
            fontFallback: [if (fonts.fallback case final f?) f],
            fontSize: PdfTypeScale.body,
            lineSpacing: 3,
            color: PdfPalette.ink),
      ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 16),
        child: pw.Text(
          '${note.displayTitle} · ${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(
              fontSize: PdfTypeScale.footer, color: PdfPalette.muted),
        ),
      ),
      build: (context) => [
        pw.Text(note.displayTitle,
            style: pw.TextStyle(
                font: fonts.serif,
                fontSize: PdfTypeScale.title,
                color: PdfPalette.forest)),
        if (_meta(note).isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(_meta(note),
              style: pw.TextStyle(
                  fontSize: PdfTypeScale.caption, color: PdfPalette.bark)),
        ],
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfPalette.rule, thickness: 1),
        pw.SizedBox(height: 8),
        for (final (alignment, nodes) in segments)
          ..._blocks(nodes, _alignOf(alignment)),
        for (final (_, nodes) in blockNodes)
          ..._blocks(nodes, pw.TextAlign.left),
        for (final block in note.blocks)
          if (block.type == NoteBlockType.pdf) _pdfAttachment(block),
      ],
    ));
    return doc.save();
  }

  // ── Analyse ──────────────────────────────────────────────────────────

  List<md.Node> _parse(String markdown) =>
      md.Document(extensionSet: _extensions, encodeHtml: false)
          .parseLines(const LineSplitter().convert(markdown));

  static Iterable<String> _imageSources(List<md.Node> nodes) sync* {
    for (final node in nodes) {
      if (node is md.Element) {
        if (node.tag == 'img' && node.attributes['src'] != null) {
          yield node.attributes['src']!;
        }
        yield* _imageSources(node.children ?? const []);
      }
    }
  }

  Future<Uint8List?> _bytesOf(String source) async {
    if (source.startsWith('data:')) {
      try {
        return base64Decode(source.substring(source.indexOf(',') + 1));
      } catch (_) {
        return null;
      }
    }
    if (source.startsWith('http')) return null;
    try {
      return await loadImage(source);
    } catch (_) {
      return null;
    }
  }

  static String _meta(Note note) => [
        if (note.subject != null) note.subject!,
        for (final tag in note.tags) '#$tag',
      ].join(' · ');

  static pw.TextAlign _alignOf(LineAlignment alignment) => switch (alignment) {
        LineAlignment.left => pw.TextAlign.left,
        LineAlignment.center => pw.TextAlign.center,
        LineAlignment.right => pw.TextAlign.right,
        LineAlignment.justify => pw.TextAlign.justify,
      };

  // ── Blocs ────────────────────────────────────────────────────────────

  List<pw.Widget> _blocks(List<md.Node> nodes, pw.TextAlign align,
      {int depth = 0}) {
    final out = <pw.Widget>[];
    for (final node in nodes) {
      if (node is md.Text) {
        out.add(_paragraph([node], align));
        continue;
      }
      if (node is! md.Element) continue;
      final children = node.children ?? const <md.Node>[];
      switch (node.tag) {
        case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
          final level = int.parse(node.tag.substring(1));
          final size = PdfTypeScale.headings[level - 1];
          out.add(pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.only(top: level <= 2 ? 12 : 8, bottom: 4),
            child: pw.RichText(
              textAlign: align,
              text: pw.TextSpan(
                children: _inline(
                    children,
                    pw.TextStyle(
                      font: level <= 2 ? fonts.serif : fonts.bold,
                      fontSize: size,
                      color: level <= 2 ? PdfPalette.forest : PdfPalette.ink,
                    )),
              ),
            ),
          ));
        case 'p':
          final images = [
            for (final c in children)
              if (c is md.Element && c.tag == 'img') c,
          ];
          final texts = children
              .where((c) => !(c is md.Element && c.tag == 'img'))
              .toList();
          if (texts.any((c) => c.textContent.trim().isNotEmpty)) {
            out.add(_paragraph(texts, align));
          }
          for (final image in images) {
            out.add(_image(image.attributes['src'] ?? ''));
          }
        case 'ul' || 'ol':
          var index = 1;
          for (final item in children.whereType<md.Element>()) {
            final number = node.tag == 'ol'
                ? '${(int.tryParse(node.attributes['start'] ?? '') ?? 1) + index - 1}.'
                : null;
            out.add(_listItem(item, number, depth));
            index++;
          }
        case 'blockquote':
          out.add(pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            padding: const pw.EdgeInsets.fromLTRB(10, 6, 8, 6),
            decoration: const pw.BoxDecoration(
              color: PdfPalette.parchment,
              border: pw.Border(
                  left: pw.BorderSide(color: PdfPalette.sage, width: 3)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _blocks(children, align, depth: depth),
            ),
          ));
        case 'pre':
          out.add(pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfPalette.parchment,
              border: pw.Border.all(color: PdfPalette.rule),
              borderRadius: pw.BorderRadius.circular(PdfTypeScale.radius),
            ),
            child: pw.Text(node.textContent.trimRight(),
                style: pw.TextStyle(
                    font: fonts.regular, fontSize: PdfTypeScale.code)),
          ));
        case 'hr':
          out.add(pw.Divider(color: PdfPalette.rule, thickness: 1));
        case 'table':
          out.add(_table(node));
        default:
          out.addAll(_blocks(children, align, depth: depth));
      }
    }
    return out;
  }

  // Pleine largeur : sans elle, centrer ou justifier n'aurait aucun effet.
  pw.Widget _paragraph(List<md.Node> inline, pw.TextAlign align) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.RichText(
          textAlign: align,
          text: pw.TextSpan(children: _inline(inline, const pw.TextStyle())),
        ),
      );

  pw.Widget _listItem(md.Element item, String? number, int depth) {
    final children = item.children ?? const <md.Node>[];
    // Liste à cocher (GFM) : <input type="checkbox" checked>.
    final box = children.whereType<md.Element>().where((e) => e.tag == 'input');
    final checked =
        box.isNotEmpty ? box.first.attributes['checked'] != null : null;
    final inline = children
        .where((c) => !(c is md.Element &&
            (c.tag == 'input' ||
                c.tag == 'ul' ||
                c.tag == 'ol' ||
                c.tag == 'p')))
        .toList();
    final paragraphs = children
        .whereType<md.Element>()
        .where((c) => c.tag == 'p')
        .expand((p) => p.children ?? const <md.Node>[])
        .toList();
    final nested = children
        .whereType<md.Element>()
        .where((c) => c.tag == 'ul' || c.tag == 'ol')
        .toList();
    // Case dessinée : les polices n'ont pas toutes ☐ / ☑.
    final pw.Widget marker = checked == null
        ? pw.Text(number ?? '•', style: pw.TextStyle(color: PdfPalette.sage))
        : pw.Container(
            width: 9,
            height: 9,
            margin: const pw.EdgeInsets.only(top: 2.5),
            decoration: pw.BoxDecoration(
              color: checked ? PdfPalette.sage : null,
              border: pw.Border.all(color: PdfPalette.sage, width: 1),
              borderRadius:
                  pw.BorderRadius.circular(PdfTypeScale.checkboxRadius),
            ),
          );
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: 12.0 * depth, bottom: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 16,
                child: pw.Align(alignment: pw.Alignment.topLeft, child: marker),
              ),
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: _inline(
                        [...inline, ...paragraphs], const pw.TextStyle()),
                  ),
                ),
              ),
            ],
          ),
          for (final list in nested)
            ..._blocks([list], pw.TextAlign.left, depth: depth + 1),
        ],
      ),
    );
  }

  pw.Widget _table(md.Element table) {
    final rows = <List<String>>[];
    void collect(md.Node node) {
      if (node is! md.Element) return;
      if (node.tag == 'tr') {
        rows.add([
          for (final cell
              in (node.children ?? const <md.Node>[]).whereType<md.Element>())
            cell.textContent,
        ]);
      } else {
        for (final child in node.children ?? const <md.Node>[]) {
          collect(child);
        }
      }
    }

    collect(table);
    if (rows.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.TableHelper.fromTextArray(
        data: rows,
        headerStyle:
            pw.TextStyle(font: fonts.bold, fontSize: PdfTypeScale.small),
        cellStyle: pw.TextStyle(fontSize: PdfTypeScale.small),
        border: pw.TableBorder.all(color: PdfPalette.rule),
        headerDecoration: const pw.BoxDecoration(color: PdfPalette.parchment),
      ),
    );
  }

  pw.Widget _image(String source) {
    final image = _images[source];
    if (image == null) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text('[Image non incluse : $source]',
            style: pw.TextStyle(
                fontSize: PdfTypeScale.caption, color: PdfPalette.muted)),
      );
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Center(
        child: pw.ConstrainedBox(
          constraints: const pw.BoxConstraints(maxHeight: 320),
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  pw.Widget _pdfAttachment(NoteBlock block) {
    final data = PdfBlockData.decode(block.content);
    if (data.isEmpty) return pw.SizedBox();
    final count = data.marks.length;
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfPalette.rule),
        borderRadius: pw.BorderRadius.circular(PdfTypeScale.radius),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PDF joint : ${data.name}',
              style: pw.TextStyle(font: fonts.bold, color: PdfPalette.bark)),
          if (count > 0) ...[
            pw.SizedBox(height: 4),
            for (final mark in data.marks)
              if (mark.text.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.RichText(
                    text: pw.TextSpan(children: [
                      pw.TextSpan(
                        text: 'p. ${mark.page} · ',
                        style: pw.TextStyle(
                            fontSize: PdfTypeScale.caption,
                            color: PdfPalette.muted),
                      ),
                      pw.TextSpan(
                        text: mark.text,
                        style: _markStyle(mark),
                      ),
                    ]),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  static pw.TextStyle _markStyle(PdfMark mark) => switch (mark.kind) {
        PdfMarkKind.highlight => pw.TextStyle(
            fontSize: PdfTypeScale.small,
            background:
                pw.BoxDecoration(color: PdfPalette.highlight(mark.color))),
        PdfMarkKind.underline => const pw.TextStyle(
            fontSize: PdfTypeScale.small,
            decoration: pw.TextDecoration.underline),
        PdfMarkKind.strike => const pw.TextStyle(
            fontSize: PdfTypeScale.small,
            decoration: pw.TextDecoration.lineThrough),
      };

  // ── En ligne ─────────────────────────────────────────────────────────

  List<pw.InlineSpan> _inline(List<md.Node> nodes, pw.TextStyle style) {
    final spans = <pw.InlineSpan>[];
    for (final node in nodes) {
      if (node is md.Text) {
        spans.add(pw.TextSpan(text: node.text, style: style));
        continue;
      }
      if (node is! md.Element) continue;
      final children = node.children ?? const <md.Node>[];
      switch (node.tag) {
        case 'strong':
          spans.addAll(_inline(
              children, style.copyWith(fontWeight: pw.FontWeight.bold)));
        case 'em':
          spans.addAll(_inline(
              children,
              style.copyWith(
                  font: style.fontWeight == pw.FontWeight.bold
                      ? fonts.serifBold
                      : fonts.serif)));
        case 'del':
          spans.addAll(_inline(children,
              style.copyWith(decoration: pw.TextDecoration.lineThrough)));
        case 'u':
          spans.add(pw.TextSpan(
              text: node.textContent,
              style: style.copyWith(decoration: pw.TextDecoration.underline)));
        case 'mark':
          spans.add(pw.TextSpan(
              text: node.textContent,
              style: style.copyWith(
                  background: pw.BoxDecoration(
                      color: PdfPalette.highlight(
                          node.attributes['color'] ?? 'jaune')))));
        case 'code':
          spans.add(pw.TextSpan(
              text: node.textContent,
              style: style.copyWith(
                  background:
                      const pw.BoxDecoration(color: PdfPalette.parchment))));
        case 'a':
          spans.addAll(_inline(
              children,
              style.copyWith(
                  color: PdfPalette.sage,
                  decoration: pw.TextDecoration.underline)));
        case 'br':
          spans.add(const pw.TextSpan(text: '\n'));
        case 'img':
          // Image au milieu d'un texte : rendue sous le paragraphe.
          break;
        default:
          spans.addAll(_inline(children, style));
      }
    }
    return spans;
  }
}

/// Mêmes syntaxes que l'aperçu (cf. `rich_markdown.dart`), sans Flutter.
class _UnderlineSyntax extends md.InlineSyntax {
  _UnderlineSyntax() : super(r'\+\+(.+?)\+\+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('u', match[1]!));
    return true;
  }
}

class _HighlightSyntax extends md.InlineSyntax {
  _HighlightSyntax() : super(r'==(?:\{([a-z]+)\})?(.+?)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match[2]!)
      ..attributes['color'] = match[1] ?? 'jaune');
    return true;
  }
}
