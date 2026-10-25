import 'package:cognicquest/features/quiz/domain/note_sections.dart';
import 'package:cognicquest/features/quiz/domain/quiz_generator.dart';
import 'package:cognicquest/features/quiz/domain/quiz_loops.dart';
import 'package:cognicquest/features/review/domain/spaced_repetition.dart';
import 'package:cognicquest/shared/models/flashcard_model.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:cognicquest/shared/models/planning_model.dart';
import 'package:cognicquest/shared/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

const thermo = '''
# Premier principe
L'énergie d'un système isolé se **conserve** au cours d'une transformation.

## Travail
Le travail reçu par le gaz vaut moins l'intégrale de la pression extérieure.

## Chaleur
La chaleur est un transfert d'énergie **désordonné** entre deux systèmes.

# Second principe
L'**entropie** d'un système isolé ne peut que croître au cours du temps.

Entropie : grandeur qui mesure le désordre d'un système.
Enthalpie : énergie interne augmentée du produit pression-volume.
Rendement : rapport du travail fourni à la chaleur reçue.
''';

Note note(String id, String title, String content, {String? subject}) => Note(
      id: id,
      userId: 'u',
      title: title,
      content: content,
      subject: subject,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Flashcard card(String id, String front, String back,
        {String? noteId, int step = 0, int lapses = 0, int reps = 0, DateTime? due}) =>
    Flashcard(
      id: id,
      userId: 'u',
      noteId: noteId,
      front: front,
      back: back,
      deck: 'Thermo',
      createdAt: DateTime(2026),
      schedule: ScheduleState(
        step: step,
        easeFactor: 2.5,
        dueAt: due ?? DateTime.now().add(const Duration(days: 3)),
        repetitions: reps,
        lapses: lapses,
        intervalDays: 0,
      ),
    );

void main() {
  group('lecture des fiches', () {
    test('sections, termes en gras, définitions', () {
      final sections = NoteSections.parse(thermo);
      expect(sections.map((s) => s.heading),
          ['Premier principe', 'Travail', 'Chaleur', 'Second principe']);
      expect(sections.first.gist, startsWith("L'énergie d'un système isolé"));
      expect(sections.first.gist, isNot(contains('**')));

      final terms = NoteSections.boldTerms(thermo).map((t) => t.term);
      expect(terms, ['conserve', 'désordonné', 'entropie']);

      final defs = NoteSections.definitions(thermo);
      expect(defs.map((d) => d.term), ['Entropie', 'Enthalpie', 'Rendement']);
      expect(defs.first.heading, 'Second principe');
    });
  });

  group('extraction fiable', () {
    test('blocs de code ignorés : ni titre, ni définition, ni gras', () {
      const content = '''
# Script
Le script lance la simulation du gaz parfait.
```
# commentaire bash
cle: une valeur de configuration
echo **gras dans le code**
```
''';
      expect(NoteSections.parse(content).map((s) => s.heading), ['Script']);
      expect(NoteSections.parse(content).single.body, isNot(contains('echo')));
      expect(NoteSections.definitions(content), isEmpty);
      expect(NoteSections.boldTerms(content), isEmpty);
    });

    test('« Exemple : », « Attention : » ne sont pas des définitions', () {
      const content = '''
Exemple : un gaz parfait chauffé à pression constante.
Attention : ne pas confondre travail et chaleur.
Isobare : transformation à pression constante.
''';
      expect(NoteSections.definitions(content).map((d) => d.term),
          ['Isobare']);
    });

    test('texte à trous sur le mot entier', () {
      const content = '''
# Chimie
La fonction d'un **ion** est de porter une charge électrique.
Un **atome** neutre a autant de protons que d'électrons.
La **molécule** d'eau compte trois atomes liés.
''';
      final questions = QuizGenerator(seed: 3).generate(
          notes: [note('c', 'Chimie', content)], cards: const [], count: 20);
      final ion = questions.firstWhere(
          (q) => q.kind == QuizKind.cloze && q.answer == 'ion');
      expect(ion.prompt, contains('fonction'));
      expect(ion.prompt, contains("d'un _____ est"));
    });

    test('« **X** : sens » : une définition, pas de texte à trous en double', () {
      const content = '''
- **Entropie** : grandeur qui mesure le désordre d'un système.
- **Enthalpie** : énergie interne augmentée du produit PV.
- **Rendement** : rapport du travail fourni à la chaleur reçue.
''';
      final questions = QuizGenerator(seed: 4).generate(
          notes: [note('d', 'Thermo', content)], cards: const [], count: 20);
      expect(questions.where((q) => q.kind == QuizKind.definition), hasLength(3));
      expect(questions.where((q) => q.kind == QuizKind.cloze), isEmpty);
    });

    test('section dont le résumé répète le titre : pas posée', () {
      expect(
          const NoteSection(
                  heading: 'Chaleur',
                  level: 2,
                  body: 'La chaleur est un transfert.')
              .echoesHeading,
          isTrue);
      expect(
          const NoteSection(
                  heading: 'Premier principe',
                  level: 1,
                  body: "L'énergie se conserve.")
              .echoesHeading,
          isFalse);
      final sections = QuizGenerator(seed: 5)
          .generate(
              notes: [note('n', 'Thermodynamique', thermo)],
              cards: const [],
              count: 50)
          .where((q) => q.kind == QuizKind.section);
      expect(sections.map((q) => q.heading),
          unorderedEquals(['Premier principe', 'Second principe']));
    });

    test('leurres : même groupe puis forme proche de la réponse', () {
      expect(
          QuizGenerator.rankDistractors(
                  'Watt', ['Une réponse bien trop longue', '42', 'Pascal'])
              .first,
          'Pascal');
      expect(
          QuizGenerator.rankDistractors('Watt', ['Pascal'], preferred: ['Ohm'])
              .first,
          'Ohm');
      expect(QuizGenerator.rankDistractors('135', ['Sodium', '145', 'Potassium']).first,
          '145');
    });

    test('réponse bien plus longue que les leurres : question écartée', () {
      final questions = QuizGenerator(seed: 6).generate(
        notes: const [],
        cards: [
          card('long', 'Q1', 'Une définition très longue et détaillée'),
          card('a', 'Q2', 'Oui'),
          card('b', 'Q3', 'Non'),
          card('c', 'Q4', 'Peut-être'),
        ],
        count: 10,
      );
      expect(questions.map((q) => q.cardId), isNot(contains('long')));
      expect(questions, isNotEmpty);
    });
  });

  group('génération', () {
    final notes = [note('n', 'Thermodynamique', thermo)];
    final cards = [
      card('c1', 'Unité de l’entropie', 'J/K', noteId: 'n'),
      card('c2', 'Unité de l’énergie', 'Joule', noteId: 'n'),
      card('c3', 'Unité de la pression', 'Pascal', noteId: 'n',
          step: 4, reps: 4),
      card('c4', 'Unité de la puissance', 'Watt', noteId: 'n'),
    ];

    test('QCM valides : 3 ou 4 options distinctes, une seule bonne', () {
      final questions = QuizGenerator(seed: 1)
          .generate(notes: notes, cards: cards, count: 50);
      expect(questions, isNotEmpty);
      expect(questions.map((q) => q.kind).toSet(),
          containsAll([QuizKind.card, QuizKind.section, QuizKind.cloze, QuizKind.definition]));
      for (final q in questions) {
        expect(q.options.length, inInclusiveRange(3, 4));
        expect(q.options.toSet(), hasLength(q.options.length));
        expect(q.options[q.answerIndex], q.answer);
      }
      final cloze = questions.firstWhere((q) => q.kind == QuizKind.cloze);
      expect(cloze.prompt, contains('_____'));
    });

    test('approfondissement : cartes maîtrisées inversées', () {
      final questions = QuizGenerator(seed: 2).generate(
          notes: notes, cards: cards, mode: QuizMode.deepen, count: 50);
      final reversed = questions.where((q) => q.kind == QuizKind.reverse);
      expect(reversed.map((q) => q.cardId), ['c3']);
      expect(reversed.single.answer, 'Unité de la pression');
    });

    test('ciblé : les titres flous sortent bien plus souvent', () {
      var fuzzyHits = 0;
      for (var seed = 0; seed < 40; seed++) {
        final questions = QuizGenerator(seed: seed).generate(
          notes: notes,
          cards: const [],
          count: 2,
          focus: const QuizFocus(fuzzyHeadings: {
            'n': {'Second principe'},
          }),
        );
        fuzzyHits +=
            questions.where((q) => q.heading == 'Second principe').length;
      }
      // Sans pondération, ~2 questions sur 9 viendraient de ce titre.
      expect(fuzzyHits, greaterThan(40));
    });
  });

  group('boucles', () {
    final existing = [card('c1', 'Unité de l’entropie', 'J/K', noteId: 'n')];
    const cardQ = QuizQuestion(
        id: 'card:c1',
        kind: QuizKind.card,
        prompt: 'Unité de l’entropie',
        options: ['J/K', 'W', 'Pa'],
        answerIndex: 0,
        noteId: 'n',
        cardId: 'c1');
    const clozeQ = QuizQuestion(
        id: 'cloze:n:2',
        kind: QuizKind.cloze,
        prompt: "Complète : L'_____ d'un système isolé ne peut que croître.",
        options: ['entropie', 'énergie', 'enthalpie'],
        answerIndex: 0,
        noteId: 'n',
        heading: 'Second principe',
        context: "L'entropie d'un système isolé ne peut que croître.");

    test('erreur sur carte → J0 ; erreur sur fiche → carte créée et titre flou',
        () {
      final outcome = QuizOutcome.of([(cardQ, false), (clozeQ, false)],
          existingCards: existing);
      expect(outcome.correct, 0);
      expect(outcome.cardsToRelearn, ['c1']);
      expect(outcome.cardsToCreate.single.front,
          "L'_____ d'un système isolé ne peut que croître.");
      expect(outcome.cardsToCreate.single.back, clozeQ.context);
      expect(outcome.fuzzyHeadings, {
        'n': {'Second principe'}
      });
    });

    test('titres flous : levés après deux réussites', () {
      final t = DateTime(2026, 10, 20);
      QuizAttempt attempt(bool ok, int day) => QuizAttempt(
          id: '$day$ok',
          questionId: 'q',
          kind: QuizKind.section,
          correct: ok,
          answeredAt: t.add(Duration(days: day)),
          noteId: 'n',
          heading: 'Chaleur');
      final now = t.add(const Duration(days: 5));
      expect(fuzzyHeadingsFrom([attempt(false, 0)], now: now), {
        'n': {'Chaleur'}
      });
      expect(
          fuzzyHeadingsFrom(
              [attempt(false, 0), attempt(true, 1), attempt(true, 2)],
              now: now),
          isEmpty);
    });
  });

  test('priorités du jour : flou, rentabilité, SMART et Eisenhower', () {
    final now = DateTime.now();
    final notes = [
      note('a', 'Thermodynamique', thermo, subject: 'Physique'),
      note('b', 'Optique', '# Lentilles\nTexte.', subject: 'Physique'),
      note('c', 'Histoire', '# Dates\nTexte.', subject: 'Histoire'),
    ];
    final focus = RevisionEngine.rank(
      notes: notes,
      cards: [card('x', 'q', 'r', noteId: 'b', lapses: 3, due: now)],
      attempts: [
        QuizAttempt(
            id: '1',
            questionId: 'q',
            kind: QuizKind.cloze,
            correct: false,
            answeredAt: now,
            noteId: 'a'),
      ],
      targets: [
        ExamTarget(
            id: 't',
            userId: 'u',
            title: 'Optique',
            createdAt: now,
            examWeight: 4,
            currentGrade: 8,
            reachableGrade: 16,
            examDate: now.add(const Duration(days: 3))),
      ],
      tasks: [
        Task(
            id: 'k',
            userId: 'u',
            title: 'Fiche Histoire à finir',
            description: '',
            status: TaskStatus.todo,
            priority: TaskPriority.medium,
            createdAt: now,
            isUrgent: true,
            isImportant: true),
      ],
      now: now,
    );
    expect(focus.first.note.id, 'b');
    expect(focus.first.reasons.join(' '), contains('examen dans 3 j'));
    expect(focus.map((f) => f.note.id), containsAll(['a', 'b', 'c']));
    expect(focus.firstWhere((f) => f.note.id == 'c').reasons,
        contains('tâche urgente et importante'));
  });
}
