import '../../notes/domain/rich_text_format.dart';

/// Première phrase utile d'un texte, coupée à 160 caractères.
String _firstSentence(String body) {
  final text = body
      .split('\n')
      .map((l) => l
          .replaceFirst(
              RegExp(r'^\s*([-*>]|\d+\.|- \[[ x]\])\s*(\[![\w-]+\][+-]?\s*)?'), '')
          .trim())
      .where((l) => l.isNotEmpty && !l.startsWith('```'))
      .join(' ');
  final end = text.indexOf(RegExp(r'[.!?](\s|$)'));
  final sentence = end < 0 ? text : text.substring(0, end + 1);
  return sentence.length > 160 ? '${sentence.substring(0, 157)}…' : sentence;
}

/// Une section d'une fiche : un titre et le texte qui le suit, jusqu'au
/// titre suivant, quel que soit son niveau.
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
  String get gist => _firstSentence(body);

  /// Le résumé reprend la majorité des mots du titre : la bonne réponse se
  /// repérerait sans connaître le cours.
  bool get echoesHeading {
    final words = heading
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\d]+', unicode: true))
        .where((w) => w.length >= 4)
        .toSet();
    if (words.isEmpty) return false;
    final text = gist.toLowerCase();
    return words.where(text.contains).length * 2 > words.length;
  }
}

/// Terme mis en gras dans une phrase : matière d'un texte à trous.
class BoldTerm {
  const BoldTerm({
    required this.term,
    required this.sentence,
    required this.heading,
    this.emphasized = false,
  });

  final String term;

  /// Phrase qui contient le terme (texte brut, terme compris).
  final String sentence;
  final String? heading;

  /// Phrase tirée d'un encadré ou d'une citation : jugée importante.
  final bool emphasized;
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

/// Valeur chiffrée d'une phrase (« 135–145 mmol/L », « 37 °C », « 1789 »),
/// matière d'un texte à trous dont les leurres sont calculés.
class NumericFact {
  const NumericFact({
    required this.sentence,
    required this.blanked,
    required this.low,
    this.separator,
    this.high,
    this.unit = '',
    this.heading,
    this.emphasized = false,
  });

  final String sentence;

  /// Phrase où la valeur est remplacée par `_____`.
  final String blanked;

  /// Nombres tels qu'écrits (« 7,35 ») ; [high] pour une fourchette.
  final String low;
  final String? separator;
  final String? high;

  /// Unité telle qu'écrite, espace compris (« mmol/L »).
  final String unit;
  final String? heading;
  final bool emphasized;

  String get value => '$low${high == null ? '' : '$separator$high'}$unit';

  bool get _isYear {
    final n = int.tryParse(low);
    return unit.isEmpty && high == null && n != null && n >= 1000 && n <= 2100;
  }

  /// Valeurs voisines plausibles : même unité, même nombre de décimales,
  /// même séparateur ; une fourchette est décalée d'un bloc.
  List<String> variants() {
    final decimals = low.contains(RegExp('[.,]')) ? low.split(RegExp('[.,]')).last.length : 0;
    final comma = low.contains(',') || (high?.contains(',') ?? false);
    final a = double.parse(low.replaceAll(',', '.'));
    final b = high == null ? null : double.parse(high!.replaceAll(',', '.'));
    final percent = unit.trim() == '%';

    final List<double Function(double)> moves;
    if (_isYear) {
      moves = [for (final d in [-10, -5, -3, 3, 5, 10]) (x) => x + d];
    } else if (decimals == 0 && a <= 10 && (b ?? 0) <= 10) {
      moves = [for (final d in [-2, -1, 1, 2, 3]) (x) => x + d];
    } else {
      moves = [for (final f in [0.5, 0.75, 1.5, 2, 10]) (x) => x * f];
    }

    String format(double x) {
      final s = x.toStringAsFixed(decimals);
      return comma ? s.replaceAll('.', ',') : s;
    }

    final out = <String>[];
    for (final move in moves) {
      final na = move(a);
      final nb = b == null ? null : move(b);
      if (na < 0 || (percent && (nb ?? na) > 100)) continue;
      final candidate =
          '${format(na)}${nb == null ? '' : '$separator${format(nb)}'}$unit';
      if (candidate != value && !out.contains(candidate)) out.add(candidate);
    }
    return out;
  }
}

/// Liste à puces introduite par une phrase « … : » ou par un titre.
class Enumeration {
  const Enumeration({
    required this.intro,
    required this.items,
    required this.heading,
  });

  final String intro;
  final List<String> items;
  final String? heading;
}

/// Tableau markdown : une ligne d'en-tête et au moins trois lignes.
class MarkdownTable {
  const MarkdownTable({
    required this.headers,
    required this.rows,
    required this.heading,
  });

  final List<String> headers;

  /// Chaque ligne a autant de cases que [headers].
  final List<List<String>> rows;
  final String? heading;
}

/// Lien « cause → effet » (flèche, ou « entraîne », « provoque »…).
class CauseEffect {
  const CauseEffect({
    required this.cause,
    required this.effect,
    required this.heading,
  });

  final String cause;
  final String effect;
  final String? heading;
}

/// Encadré `> [!important]` ou citation `>` : un point clé.
class Callout {
  const Callout({
    required this.type,
    required this.text,
    required this.heading,
    this.title,
  });

  /// `important`, `warning`, `tip`, `note`… ; `null` pour une citation.
  final String? type;
  final String? title;
  final String text;
  final String? heading;

  String get gist => _firstSentence(text);

  String get label => switch (type) {
        'important' => 'Important',
        'warning' || 'caution' || 'danger' => 'Attention',
        'tip' || 'hint' => 'Astuce',
        null => 'Citation',
        _ => 'À retenir',
      };
}

/// Lecture d'une fiche pour en tirer des questions.
abstract final class NoteSections {
  static final RegExp _heading = RegExp(r'^(#{1,6})\s+(.+)$');
  static final RegExp _bold = RegExp(r'\*\*([^*\n]{2,60})\*\*');
  static final RegExp _definition =
      RegExp(r'^\s*(?:[-*]\s+)?\**([^:—\n]{2,50}?)\**\s*(?::|—)\s+(.{6,200})$');
  static final RegExp _bullet = RegExp(r'^(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s+)?(.+)$');
  static final RegExp _prefix = RegExp(r'^(?:[-*+>]|\d+[.)])\s+');
  static final RegExp _calloutMarker = RegExp(r'^\[!([\w-]+)\][+-]?\s*');
  static final RegExp _number = RegExp(
    // Ni dans un mot (« CO2 »), ni dans une heure (« 10:30 ») ; une virgule
    // ou un point ne compte que s'il est suivi d'un chiffre.
    r'(?<![\p{L}\d:/])(?<!\d[.,])(\d+(?:[.,]\d+)?)'
    r'(?:(\s?(?:[-–]|à)\s?)(\d+(?:[.,]\d+)?))?'
    r'(\s?(?:mmol/L|µmol/L|mg/dL|g/dL|mg/L|g/L|mmHg|kHz|MHz|kPa|kJ|mV|mA|'
    r'bpm|min|mol|ms|mg|µg|kg|mL|cm|mm|nm|km|Hz|Pa|°C|%|‰|°|g|L|s|h|J|W|V|A|Ω|m))?'
    r'(?![\p{L}\d:/]|[.,]\d)',
    unicode: true,
  );
  static final RegExp _arrow = RegExp(r'\s*(?:→|⇒|⟶|->|=>)\s*');
  static final RegExp _causeVerb = RegExp(
    r'^(.{6,120}?)\s+(?:entraîne|entraine|provoque|induit|conduit à|aboutit à)\s+(.{4,160}?)\.?$',
    caseSensitive: false,
  );

  /// Étiquettes suivies de « : » qui ne sont pas des termes à définir.
  static const _notTerms = {
    'exemple', 'exemples', 'ex', 'note', 'nb', 'n.b.', 'remarque', 'attention',
    'rappel', 'important', 'astuce', 'à retenir', 'source', 'sources', 'cf',
    'définition', 'conclusion', 'résumé', 'méthode',
  };

  static String _clean(String text) =>
      RichTextFormat.plain(text).replaceAll('**', '').trim();

  /// Phrase lisible d'une ligne : sans puce, citation ni marqueur d'encadré.
  static String _sentence(String line) => _clean(line)
      .replaceFirst(_prefix, '')
      .replaceFirst(_calloutMarker, '')
      .trim();

  /// Lignes de texte hors blocs de code, avec le titre qui les couvre.
  /// Une ligne vide est rendue telle quelle : elle termine une liste.
  static Iterable<(String, String?)> _lines(String content) sync* {
    String? heading;
    var inFence = false;
    for (final raw in content.split('\n')) {
      final line = LineAlignment.parse(raw).$2.trim();
      if (line.startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;
      final h = _heading.firstMatch(line);
      if (h != null) {
        heading = _clean(h.group(2)!);
        continue;
      }
      yield (line, heading);
    }
  }

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

    var inFence = false;
    for (final raw in content.split('\n')) {
      final line = LineAlignment.parse(raw).$2;
      // Le code ne fait ni titre (« # commentaire ») ni résumé.
      if (line.trim().startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;
      final match = _heading.firstMatch(line.trim());
      if (match != null) {
        flush();
        level = match.group(1)!.length;
        heading = _clean(match.group(2)!);
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
    for (final (line, heading) in _lines(content)) {
      if (line.startsWith('|')) continue;
      for (final m in _bold.allMatches(line)) {
        final sentence = _sentence(line);
        // Une phrase trop courte ne donne pas de contexte pour deviner.
        if (sentence.length < m.group(1)!.length + 12) continue;
        out.add(BoldTerm(
          term: m.group(1)!.trim(),
          sentence: sentence,
          heading: heading,
          emphasized: line.startsWith('>'),
        ));
      }
    }
    return out;
  }

  static List<Definition> definitions(String content) {
    final out = <Definition>[];
    for (final (line, heading) in _lines(content)) {
      // Pas de lien, d'image ni d'heure (« 10:30 ») pris pour une définition.
      if (line.contains('http') || line.contains('![') || line.startsWith('|')) {
        continue;
      }
      final m = _definition.firstMatch(line);
      if (m == null) continue;
      final term = RichTextFormat.plain(m.group(1)!).replaceAll('*', '').trim();
      if (RegExp(r'^\d').hasMatch(term) ||
          _notTerms.contains(term.toLowerCase())) {
        continue;
      }
      out.add(Definition(
        term: term,
        meaning: RichTextFormat.plain(m.group(2)!).replaceAll('**', '').trim(),
        heading: heading,
      ));
    }
    return out;
  }

  /// Une valeur chiffrée par ligne : la première avec unité, sinon la
  /// première tout court.
  static List<NumericFact> numericFacts(String content) {
    final out = <NumericFact>[];
    for (final (line, heading) in _lines(content)) {
      if (line.isEmpty || line.startsWith('|') || line.contains('http')) continue;
      final sentence = _sentence(line);
      if (sentence.length < 15) continue;
      final matches = _number.allMatches(sentence).toList();
      if (matches.isEmpty) continue;
      final m = matches.firstWhere((m) => m.group(4) != null,
          orElse: () => matches.first);
      out.add(NumericFact(
        sentence: sentence,
        blanked: sentence.replaceRange(m.start, m.end, '_____'),
        low: m.group(1)!,
        separator: m.group(2),
        high: m.group(3),
        unit: m.group(4) ?? '',
        heading: heading,
        emphasized: line.startsWith('>'),
      ));
    }
    return out;
  }

  /// Listes d'au moins trois puces, introduites par « … : » ou placées
  /// juste sous un titre.
  static List<Enumeration> enumerations(String content) {
    final out = <Enumeration>[];
    String? intro;
    String? introHeading;
    String? currentHeading;
    var started = false;
    final items = <String>[];
    void flush() {
      if (intro != null && items.length >= 3) {
        out.add(Enumeration(
            intro: intro!, items: [...items], heading: introHeading));
      }
      items.clear();
      intro = null;
    }

    for (final (line, heading) in _lines(content)) {
      if (!started || heading != currentHeading) {
        flush();
        started = true;
        currentHeading = heading;
        intro = heading;
        introHeading = heading;
      }
      if (line.isEmpty) {
        // Ligne vide entre l'intro et la liste : tolérée.
        if (items.isNotEmpty) flush();
        continue;
      }
      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        if (intro == null) continue;
        var item = _clean(bullet.group(1)!);
        // « Terme : sens » : le terme suffit.
        final def = _definition.firstMatch(bullet.group(1)!);
        if (def != null) item = _clean(def.group(1)!).replaceAll('*', '');
        item = item.replaceFirst(RegExp(r'[.;,]$'), '').trim();
        if (item.length >= 2 && item.length <= 80) items.add(item);
        continue;
      }
      flush();
      final text = _sentence(line);
      if (text.endsWith(':') && text.length >= 4 && text.length <= 120) {
        intro = text.substring(0, text.length - 1).trim();
        introHeading = heading;
      }
    }
    flush();
    return out;
  }

  static List<MarkdownTable> tables(String content) {
    final out = <MarkdownTable>[];
    final block = <String>[];
    String? blockHeading;
    final separator = RegExp(r'^\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?$');
    List<String> cells(String line) {
      var l = line.trim();
      if (l.startsWith('|')) l = l.substring(1);
      if (l.endsWith('|')) l = l.substring(0, l.length - 1);
      return [for (final c in l.split('|')) _clean(c)];
    }

    void flush() {
      if (block.length >= 2 && separator.hasMatch(block[1])) {
        final headers = cells(block[0]);
        final rows = [
          for (final line in block.skip(2))
            if (cells(line) case final c when c.length == headers.length && c.first.isNotEmpty) c,
        ];
        if (headers.length >= 2 && rows.length >= 3) {
          out.add(MarkdownTable(headers: headers, rows: rows, heading: blockHeading));
        }
      }
      block.clear();
    }

    for (final (line, heading) in _lines(content)) {
      if (line.startsWith('|')) {
        if (block.isEmpty) blockHeading = heading;
        block.add(line);
      } else {
        flush();
      }
    }
    flush();
    return out;
  }

  /// Chaînes « A → B → C » (une paire par flèche) et phrases « A entraîne B ».
  static List<CauseEffect> causes(String content) {
    final out = <CauseEffect>[];
    for (final (line, heading) in _lines(content)) {
      if (line.isEmpty || line.startsWith('|')) continue;
      final sentence = _sentence(line);
      final parts = sentence.split(_arrow).map((p) => p.trim()).toList();
      if (parts.length >= 2 && parts.every((p) => p.length >= 3 && p.length <= 160)) {
        for (var i = 0; i + 1 < parts.length; i++) {
          out.add(CauseEffect(
            cause: parts[i],
            effect: parts[i + 1].replaceFirst(RegExp(r'\.$'), ''),
            heading: heading,
          ));
        }
        continue;
      }
      final m = _causeVerb.firstMatch(sentence);
      if (m != null) {
        out.add(CauseEffect(
            cause: m.group(1)!.trim(), effect: m.group(2)!.trim(), heading: heading));
      }
    }
    return out;
  }

  /// Encadrés `> [!type] titre` (suivis de lignes `>`) et citations `>`.
  static List<Callout> callouts(String content) {
    final out = <Callout>[];
    String? type;
    String? title;
    String? heading;
    final body = <String>[];
    var open = false;
    void flush() {
      if (open) {
        final text = _clean(body.join('\n'));
        final shown = text.isEmpty ? (title ?? '') : text;
        if (shown.length >= 12) {
          out.add(Callout(
            type: type,
            title: text.isEmpty ? null : title,
            text: shown,
            heading: heading,
          ));
        }
      }
      open = false;
      type = null;
      title = null;
      body.clear();
    }

    for (final (line, h) in _lines(content)) {
      if (!line.startsWith('>')) {
        flush();
        continue;
      }
      final inner = line.substring(1).trim();
      final marker = _calloutMarker.firstMatch(inner);
      if (marker != null) {
        flush();
        open = true;
        type = marker.group(1)!.toLowerCase();
        final rest = _clean(inner.substring(marker.end));
        title = rest.isEmpty ? null : rest;
        heading = h;
        continue;
      }
      if (!open) {
        open = true;
        heading = h;
      }
      if (inner.isNotEmpty) body.add(inner);
    }
    flush();
    return out;
  }
}
