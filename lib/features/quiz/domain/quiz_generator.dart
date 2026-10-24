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
  definition('Définition');

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
/// fiches (titres, termes en gras, définitions) et des cartes, et les
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
        pool: _prefer(
          cardAnswers(card, fronts: reverse),
          sameDeck: [
            for (final c in cards)
              if (c.id != card.id && c.deck == card.deck)
                reverse ? sides[c.id]!.$1 : sides[c.id]!.$2,
          ],
        ),
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
        final blank = term.sentence.replaceFirst(term.term, '_____');
        if (blank == term.sentence) continue;
        final question = _choice(
          id: 'cloze:${note.id}:$i',
          kind: QuizKind.cloze,
          prompt: 'Complète : $blank',
          answer: term.term,
          pool: [for (final t in allTerms) if (t != term.term) t],
          noteId: note.id,
          heading: term.heading,
          context: term.sentence,
        );
        if (question != null) {
          candidates.add((question, weightFor(term.heading) + 0.5));
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
          noteId: note.id,
          heading: def.heading,
        );
        if (question != null) {
          candidates.add((question, weightFor(def.heading) + 0.5));
        }
      }
    }

    return _weightedSample(candidates, count);
  }

  /// Distracteurs du même paquet d'abord, puis du reste.
  static List<String> _prefer(List<String> all, {required List<String> sameDeck}) =>
      [...sameDeck, ...all];

  QuizQuestion? _choice({
    required String id,
    required QuizKind kind,
    required String prompt,
    required String answer,
    required List<String> pool,
    String? noteId,
    String? cardId,
    String? heading,
    String? context,
  }) {
    final key = answer.trim().toLowerCase();
    final seen = <String>{key};
    final distractors = <String>[];
    // Ordre de préférence conservé, puis mélange des seuls retenus.
    for (final option in pool) {
      final k = option.trim().toLowerCase();
      if (k.isEmpty || !seen.add(k)) continue;
      distractors.add(option.trim());
      if (distractors.length == 3) break;
    }
    // Moins de deux leurres : la question se devinerait.
    if (distractors.length < 2) return null;
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
