import 'dart:math' as math;

import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/note_model.dart';
import 'note_sections.dart';

/// Origine d'une question : elle décide de ce que provoque une erreur.
enum QuizKind {
  /// Carte : recto → verso.
  card('Carte'),

  /// Carte maîtrisée, à l'envers : verso → recto (approfondissement).
  reverse('Carte inversée'),

  /// Section de fiche : que dit « tel titre » ?
  section('Fiche'),

  /// Texte à trous sur un terme en gras de la fiche.
  cloze('Texte à trous'),

  /// Définition « terme : sens » de la fiche.
  definition('Définition'),

  /// Texte à trous sur une valeur chiffrée, leurres calculés.
  numeric('Valeur chiffrée'),

  /// Liste à puces : trouver l'élément qui n'en fait pas partie.
  intruder('Intrus'),

  /// Case d'un tableau markdown.
  table('Tableau'),

  /// Chaîne « cause → effet ».
  causal('Cause → effet'),

  /// Encadré `> [!important]` ou citation.
  callout('Encadré');

  const QuizKind(this.label);

  final String label;

  bool get fromCard => this == card || this == reverse;
}

/// Mode du quiz.
enum QuizMode {
  /// Notions floues, chapitres prioritaires, cartes oubliées d'abord.
  focus('Quiz ciblé'),

  /// Cartes maîtrisées et leurs fiches : questions plus exigeantes.
  deepen('Approfondissement');

  const QuizMode(this.label);

  final String label;
}

/// Une question à choix multiple.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.options,
    required this.answerIndex,
    this.noteId,
    this.cardId,
    this.heading,
    this.context,
  });

  final String id;
  final QuizKind kind;
  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String? noteId;
  final String? cardId;

  /// Titre de la fiche concerné (sections, trous, définitions).
  final String? heading;

  /// Phrase complète, montrée après la réponse.
  final String? context;

  String get answer => options[answerIndex];
}

/// Ce qui oriente le tirage : notes à cibler, titres flous, cartes.
class QuizFocus {
  const QuizFocus({
    this.noteIds = const {},
    this.fuzzyHeadings = const {},
  });

  /// Fiches prioritaires (moteur de priorités du jour).
  final Set<String> noteIds;

  /// Titres flous par fiche : `noteId → {titre}`.
  final Map<String, Set<String>> fuzzyHeadings;

  bool isFuzzy(String? noteId, String? heading) =>
      noteId != null &&
      heading != null &&
      (fuzzyHeadings[noteId]?.contains(heading) ?? false);
}

/// Quiz génératif, sans IA : les questions viennent de la structure des
/// fiches (titres, termes en gras, définitions, valeurs chiffrées, listes,
/// tableaux, chaînes cause → effet, encadrés) et des cartes, et les
/// mauvaises réponses d'autres éléments du même cours.
class QuizGenerator {
  QuizGenerator({int seed = 0}) : _random = math.Random(seed);

  final math.Random _random;

  /// Une carte est maîtrisée à partir de J+7 (3e marche) et sans oubli
  /// récent marqué.
  static bool isMastered(Flashcard card) =>
      card.schedule.step >= 3 && card.schedule.lapses <= card.schedule.repetitions;

  List<QuizQuestion> generate({
    required List<Note> notes,
    required List<Flashcard> cards,
    QuizMode mode = QuizMode.focus,
    QuizFocus focus = const QuizFocus(),
    String? onlyNoteId,
    int count = 10,
  }) {
    final scopedNotes = onlyNoteId == null
        ? notes
        : notes.where((n) => n.id == onlyNoteId).toList();
    final scopedCards = onlyNoteId == null
        ? cards
        : cards.where((c) => c.noteId == onlyNoteId).toList();

    final candidates = <(QuizQuestion, double)>[];
    final now = DateTime.now();

    // ── Cartes ─────────────────────────────────────────────────────────
    final sides = {
      for (final c in cards)
        c.id: (CardSide.parse(c.front).text.trim(), CardSide.parse(c.back).text.trim()),
    };
    List<String> cardAnswers(Flashcard except, {required bool fronts}) => [
          for (final c in cards)
            if (c.id != except.id)
              fronts ? sides[c.id]!.$1 : sides[c.id]!.$2,
        ];

    final deepen = mode == QuizMode.deepen;
    final pool = deepen
        ? (scopedCards.where(isMastered).isEmpty
            ? scopedCards
            : scopedCards.where(isMastered).toList())
        : scopedCards;
    for (final card in pool) {
      final (front, back) = sides[card.id]!;
      if (front.isEmpty || back.isEmpty) continue;
      final reverse = deepen;
      final prompt = reverse ? back : front;
      final answer = reverse ? front : back;
      final question = _choice(
        id: '${reverse ? 'rev' : 'card'}:${card.id}',
        kind: reverse ? QuizKind.reverse : QuizKind.card,
        prompt: reverse ? 'À quoi correspond : « $prompt » ?' : prompt,
        answer: answer,
        pool: cardAnswers(card, fronts: reverse),
        preferred: [
          for (final c in cards)
            if (c.id != card.id && c.deck == card.deck)
              reverse ? sides[c.id]!.$1 : sides[c.id]!.$2,
        ],
        noteId: card.noteId,
        cardId: card.id,
      );
      if (question == null) continue;
      var weight = 1.0 + card.schedule.lapses * 1.5;
      if (!card.schedule.dueAt.isAfter(now)) weight += 2;
      if (focus.noteIds.contains(card.noteId)) weight += 2;
      candidates.add((question, weight));
    }

    // ── Fiches ─────────────────────────────────────────────────────────
    final enumsByNote = <String, List<Enumeration>>{};
    List<Enumeration> enumsOf(Note n) => enumsByNote.putIfAbsent(
        n.id, () => NoteSections.enumerations(n.content));
    final noteIdsForDepth = deepen
        ? {for (final c in pool) c.noteId}.whereType<String>().toSet()
        : null;
    for (final note in scopedNotes) {
      if (noteIdsForDepth != null &&
          noteIdsForDepth.isNotEmpty &&
          !noteIdsForDepth.contains(note.id)) {
        continue;
      }
      final sections =
          NoteSections.parse(note.content).where((s) => s.gist.length >= 12).toList();
      final terms = NoteSections.boldTerms(note.content);
      final defs = NoteSections.definitions(note.content);
      double weightFor(String? heading) =>
          1 +
          (focus.isFuzzy(note.id, heading) ? 4 : 0) +
          (focus.noteIds.contains(note.id) ? 2 : 0) +
          (deepen ? 1 : 0);

      for (final (i, section) in sections.indexed) {
        // Reste un leurre pour les autres sections, mais n'est pas posée.
        if (section.echoesHeading) continue;
        final question = _choice(
          id: 'sec:${note.id}:$i',
          kind: QuizKind.section,
          prompt: 'Dans « ${note.displayTitle} », que dit la partie '
              '« ${section.heading} » ?',
          answer: section.gist,
          pool: [for (final s in sections) if (s != section) s.gist],
          noteId: note.id,
          heading: section.heading,
        );
        if (question != null) {
          candidates.add((question, weightFor(section.heading)));
        }
      }
      final allTerms = [for (final t in terms) t.term];
      for (final (i, term) in terms.indexed) {
        // « **X** : sens » est déjà posée comme définition.
        final key = term.term.toLowerCase();
        if (defs.any((d) =>
            d.term.toLowerCase() == key && term.sentence.contains(d.meaning))) {
          continue;
        }
        // Mot entier seulement : « ion » ne vide pas « fonction ».
        final blank = term.sentence.replaceFirst(
            RegExp('(?<![\\p{L}\\d])${RegExp.escape(term.term)}(?![\\p{L}\\d])',
                unicode: true),
            '_____');
        if (blank == term.sentence) continue;
        final question = _choice(
          id: 'cloze:${note.id}:$i',
          kind: QuizKind.cloze,
          prompt: 'Complète : $blank',
          answer: term.term,
          pool: [for (final t in allTerms) if (t != term.term) t],
          preferred: [
            for (final t in terms)
              if (t.heading == term.heading && t.term != term.term) t.term,
          ],
          noteId: note.id,
          heading: term.heading,
          context: term.sentence,
        );
        if (question != null) {
          candidates.add((
            question,
            weightFor(term.heading) + 0.5 + (term.emphasized ? 1.5 : 0)
          ));
        }
      }
      for (final (i, def) in defs.indexed) {
        final question = _choice(
          id: 'def:${note.id}:$i',
          kind: QuizKind.definition,
          prompt: deepen
              ? 'Quel terme désigne : « ${def.meaning} » ?'
              : 'Que signifie « ${def.term} » ?',
          answer: deepen ? def.term : def.meaning,
          pool: [
            for (final d in defs)
              if (d != def) deepen ? d.term : d.meaning,
          ],
          preferred: [
            for (final d in defs)
              if (d != def && d.heading == def.heading)
                deepen ? d.term : d.meaning,
          ],
          noteId: note.id,
          heading: def.heading,
        );
        if (question != null) {
          candidates.add((question, weightFor(def.heading) + 0.5));
        }
      }

      // Valeurs chiffrées : leurres calculés, pas tirés de la fiche.
      for (final (i, fact) in NoteSections.numericFacts(note.content).indexed) {
        if (defs.any((d) => fact.sentence.contains(d.meaning))) continue;
        final question = _choice(
          id: 'num:${note.id}:$i',
          kind: QuizKind.numeric,
          prompt: 'Complète : ${fact.blanked}',
          answer: fact.value,
          pool: fact.variants()..shuffle(_random),
          noteId: note.id,
          heading: fact.heading,
          context: fact.sentence,
        );
        if (question != null) {
          candidates.add((
            question,
            weightFor(fact.heading) + 0.5 + (fact.emphasized ? 1.5 : 0)
          ));
        }
      }

      // Intrus : un élément d'une autre liste du cours parmi les vrais.
      final enums = enumsOf(note);
      for (final (i, list) in enums.indexed) {
        final own = {for (final item in list.items) item.toLowerCase()};
        List<String> outsiders(Iterable<Enumeration> lists) => [
              for (final other in lists)
                if (other != list)
                  for (final item in other.items)
                    if (!own.contains(item.toLowerCase())) item,
            ];
        var strangers = outsiders(enums);
        if (strangers.isEmpty) {
          strangers = outsiders([
            for (final n in notes)
              if (n.id != note.id &&
                  n.subject != null &&
                  n.subject == note.subject)
                ...enumsOf(n),
          ]);
        }
        if (strangers.isEmpty) continue;
        final close = rankDistractors(list.items.first, strangers).take(3).toList();
        final intruder = close[_random.nextInt(close.length)];
        final question = _choice(
          id: 'odd:${note.id}:$i',
          kind: QuizKind.intruder,
          prompt: 'Intrus : lequel ne fait pas partie de « ${list.intro} » ?',
          answer: intruder,
          pool: [...list.items]..shuffle(_random),
          noteId: note.id,
          heading: list.heading,
          context: '${list.intro} : ${list.items.join(', ')}.',
        );
        if (question != null) {
          candidates.add((question, weightFor(list.heading) + 0.5));
        }
      }

      // Tableaux : quelques cases par tableau, pour ne pas noyer le reste.
      for (final (t, table) in NoteSections.tables(note.content).indexed) {
        final cells = [
          for (var r = 0; r < table.rows.length; r++)
            for (var c = 1; c < table.headers.length; c++)
              if (table.rows[r][c].isNotEmpty) (r, c),
        ]..shuffle(_random);
        final where = table.heading == null ? '' : ' de « ${table.heading} »';
        for (final (r, c) in cells.take(6)) {
          final row = table.rows[r];
          final question = _choice(
            id: 'tab:${note.id}:$t:$r:$c',
            kind: QuizKind.table,
            prompt: 'Dans le tableau$where, que vaut « ${table.headers[c]} » '
                'pour « ${row.first} » ?',
            answer: row[c],
            pool: [
              for (final other in table.rows)
                if (other != row) other[c],
            ],
            noteId: note.id,
            heading: table.heading,
            context: '${row.first} — ${table.headers[c]} : ${row[c]}',
          );
          if (question != null) {
            candidates.add((question, weightFor(table.heading) + 0.3));
          }
        }
      }

      // Cause → effet : les leurres sont les autres effets du cours.
      final links = NoteSections.causes(note.content);
      for (final (i, link) in links.indexed) {
        final question = _choice(
          id: 'cause:${note.id}:$i',
          kind: QuizKind.causal,
          prompt: 'Complète la chaîne : ${link.cause} → _____',
          answer: link.effect,
          pool: [
            for (final l in links)
              if (l != link && l.cause != link.effect) l.effect,
          ],
          preferred: [
            for (final l in links)
              if (l != link && l.heading == link.heading) l.effect,
          ],
          noteId: note.id,
          heading: link.heading,
          context: '${link.cause} → ${link.effect}',
        );
        if (question != null) {
          candidates.add((question, weightFor(link.heading) + 0.5));
        }
      }

      // Encadrés : jugés importants par l'élève, ils sortent plus souvent.
      final callouts = NoteSections.callouts(note.content);
      final gists = {for (final s in sections) s.gist};
      for (final (i, callout) in callouts.indexed) {
        if (gists.contains(callout.gist)) continue;
        final about = callout.title ?? callout.heading;
        final question = _choice(
          id: 'call:${note.id}:$i',
          kind: QuizKind.callout,
          prompt: 'Encadré « ${callout.label} »'
              '${about == null ? '' : ' sur « $about »'} : que dit-il ?',
          answer: callout.gist,
          pool: [for (final s in sections) s.gist],
          preferred: [
            for (final c in callouts)
              if (c != callout) c.gist,
          ],
          noteId: note.id,
          heading: callout.heading,
          context: callout.gist,
        );
        if (question != null) {
          candidates.add((question, weightFor(callout.heading) + 1.5));
        }
      }
    }

    return _weightedSample(candidates, count);
  }

  static final RegExp _numeric = RegExp(r'^\d');

  /// Classe les leurres : même groupe (paquet, titre) d'abord, puis ceux
  /// qui ressemblent à la réponse (longueur proche, chiffre ou texte). À
  /// score égal, l'ordre d'origine est conservé.
  static List<String> rankDistractors(
    String answer,
    List<String> pool, {
    List<String> preferred = const [],
  }) {
    final target = answer.trim();
    final isNumber = _numeric.hasMatch(target);
    double score(String option, bool isPreferred) {
      final o = option.trim();
      final ratio = target.isEmpty ? 1.0 : o.length / target.length;
      return (isPreferred ? 2 : 0) +
          (ratio >= 0.6 && ratio <= 1.6 ? 2 : 0) +
          (_numeric.hasMatch(o) == isNumber ? 1 : 0);
    }

    final scored = [
      for (final (i, o) in preferred.indexed) (o, score(o, true), i),
      for (final (i, o) in pool.indexed) (o, score(o, false), preferred.length + i),
    ]..sort((a, b) {
        final byScore = b.$2.compareTo(a.$2);
        return byScore != 0 ? byScore : a.$3.compareTo(b.$3);
      });
    return [for (final s in scored) s.$1];
  }

  QuizQuestion? _choice({
    required String id,
    required QuizKind kind,
    required String prompt,
    required String answer,
    required List<String> pool,
    List<String> preferred = const [],
    String? noteId,
    String? cardId,
    String? heading,
    String? context,
  }) {
    final key = answer.trim().toLowerCase();
    final seen = <String>{key};
    final distractors = <String>[];
    // Ordre du classement conservé, puis mélange des seuls retenus.
    for (final option in rankDistractors(answer, pool, preferred: preferred)) {
      final k = option.trim().toLowerCase();
      if (k.isEmpty || !seen.add(k)) continue;
      distractors.add(option.trim());
      if (distractors.length == 3) break;
    }
    // Moins de deux leurres : la question se devinerait.
    if (distractors.length < 2) return null;
    // Réponse nettement plus longue que tous les leurres : même chose.
    final longest =
        distractors.fold<int>(0, (m, d) => math.max(m, d.length));
    final length = answer.trim().length;
    if (length > longest * 1.4 && length - longest >= 8) return null;
    final options = [answer.trim(), ...distractors]..shuffle(_random);
    return QuizQuestion(
      id: id,
      kind: kind,
      prompt: prompt,
      options: options,
      answerIndex: options.indexOf(answer.trim()),
      noteId: noteId,
      cardId: cardId,
      heading: heading,
      context: context,
    );
  }

  /// Tirage pondéré sans remise : les questions lourdes sortent plus
  /// souvent, sans exclure les autres.
  List<QuizQuestion> _weightedSample(
      List<(QuizQuestion, double)> items, int count) {
    final remaining = [...items];
    final out = <QuizQuestion>[];
    while (out.length < count && remaining.isNotEmpty) {
      final total = remaining.fold<double>(0, (s, e) => s + e.$2);
      var pick = _random.nextDouble() * total;
      var index = 0;
      for (; index < remaining.length - 1; index++) {
        pick -= remaining[index].$2;
        if (pick <= 0) break;
      }
      out.add(remaining.removeAt(index).$1);
    }
    return out;
  }
}
