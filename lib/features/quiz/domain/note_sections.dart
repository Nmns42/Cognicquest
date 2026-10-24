import '../../notes/domain/rich_text_format.dart';

/// Une section d'une fiche : un titre et le texte qui le suit, jusqu'au
/// titre suivant de même niveau ou de niveau supérieur.
class NoteSection {
  const NoteSection({
    required this.heading,
    required this.level,
    required this.body,
  });

  final String heading;

  /// 1 pour `#`, 6 pour `######`.
  final int level;

  /// Texte brut de la section (marqueurs de mise en forme retirés).
  final String body;

  /// Première phrase utile du texte : la « réponse » à « que dit cette
  /// section ? ».
  String get gist {
    final text = body
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^\s*([-*>]|\d+\.|- \[[ x]\])\s*'), '').trim())
        .where((l) => l.isNotEmpty && !l.startsWith('```'))
        .join(' ');
    final end = text.indexOf(RegExp(r'[.!?](\s|$)'));
    final sentence = end < 0 ? text : text.substring(0, end + 1);
    return sentence.length > 160 ? '${sentence.substring(0, 157)}…' : sentence;
  }
}

/// Terme mis en gras dans une phrase : matière d'un texte à trous.
class BoldTerm {
  const BoldTerm({
    required this.term,
    required this.sentence,
    required this.heading,
  });

  final String term;

  /// Phrase qui contient le terme (texte brut, terme compris).
  final String sentence;
  final String? heading;
}

/// Définition « terme : sens » (ou « terme — sens ») sur une ligne.
class Definition {
  const Definition({
    required this.term,
    required this.meaning,
    required this.heading,
  });

  final String term;
  final String meaning;
  final String? heading;
}

/// Lecture d'une fiche pour en tirer des questions.
abstract final class NoteSections {
  static final RegExp _heading = RegExp(r'^(#{1,6})\s+(.+)$');
  static final RegExp _bold = RegExp(r'\*\*([^*\n]{2,60})\*\*');
  static final RegExp _definition =
      RegExp(r'^\s*(?:[-*]\s+)?\**([^:—\n]{2,50}?)\**\s*(?::|—)\s+(.{6,200})$');

  static List<NoteSection> parse(String content) {
    final sections = <NoteSection>[];
    String? heading;
    var level = 0;
    final body = <String>[];
    void flush() {
      if (heading != null && body.join().trim().isNotEmpty) {
        sections.add(NoteSection(
          heading: heading,
          level: level,
          body: RichTextFormat.plain(body.join('\n')).replaceAll('**', ''),
        ));
      }
      body.clear();
    }

    for (final raw in content.split('\n')) {
      final line = LineAlignment.parse(raw).$2;
      final match = _heading.firstMatch(line.trim());
      if (match != null) {
        flush();
        level = match.group(1)!.length;
        heading = RichTextFormat.plain(match.group(2)!).replaceAll('**', '').trim();
      } else {
        body.add(line);
      }
    }
    flush();
    return sections;
  }

  /// Termes en gras, avec leur phrase et la section qui les contient.
  static List<BoldTerm> boldTerms(String content) {
    final out = <BoldTerm>[];
    String? heading;
    for (final raw in content.split('\n')) {
      final line = LineAlignment.parse(raw).$2.trim();
      final h = _heading.firstMatch(line);
      if (h != null) {
        heading = RichTextFormat.plain(h.group(2)!).replaceAll('**', '').trim();
        continue;
      }
      for (final m in _bold.allMatches(line)) {
        final sentence =
            RichTextFormat.plain(line).replaceAll('**', '').replaceFirst(
                  RegExp(r'^([-*>]|\d+\.)\s+'),
                  '',
                );
        // Une phrase trop courte ne donne pas de contexte pour deviner.
        if (sentence.length < m.group(1)!.length + 12) continue;
        out.add(BoldTerm(
            term: m.group(1)!.trim(), sentence: sentence, heading: heading));
      }
    }
    return out;
  }

  static List<Definition> definitions(String content) {
    final out = <Definition>[];
    String? heading;
    for (final raw in content.split('\n')) {
      final line = LineAlignment.parse(raw).$2.trim();
      final h = _heading.firstMatch(line);
      if (h != null) {
        heading = RichTextFormat.plain(h.group(2)!).replaceAll('**', '').trim();
        continue;
      }
      // Pas de lien, d'image ni d'heure (« 10:30 ») pris pour une définition.
      if (line.contains('http') || line.contains('![') || line.startsWith('|')) {
        continue;
      }
      final m = _definition.firstMatch(line);
      if (m == null) continue;
      final term = RichTextFormat.plain(m.group(1)!).replaceAll('*', '').trim();
      if (RegExp(r'^\d').hasMatch(term)) continue;
      out.add(Definition(
        term: term,
        meaning: RichTextFormat.plain(m.group(2)!).replaceAll('**', '').trim(),
        heading: heading,
      ));
    }
    return out;
  }
}
