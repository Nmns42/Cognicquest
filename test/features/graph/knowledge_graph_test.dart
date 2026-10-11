import 'package:cognicquest/features/graph/domain/knowledge_graph.dart';
import 'package:cognicquest/shared/models/note_link_model.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:flutter_test/flutter_test.dart';

Note note(String id, {List<String> tags = const [], String? subject, bool archived = false}) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: id,
    userId: 'u1',
    title: 'Fiche $id',
    content: '',
    subject: subject,
    tags: tags,
    isArchived: archived,
    createdAt: now,
    updatedAt: now,
  );
}

NoteLink link(
  String source,
  String target, {
  NoteLinkType type = NoteLinkType.related,
}) =>
    NoteLink(
      id: '$source-$target-${type.value}',
      userId: 'u1',
      sourceId: source,
      targetId: target,
      type: type,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('KnowledgeGraph.buildNodes', () {
    test('calcule le degré sans tenir compte du sens du lien', () {
      final nodes = KnowledgeGraph.buildNodes(
        [note('a'), note('b'), note('c')],
        [link('a', 'b'), link('c', 'a')],
      );

      final byId = {for (final n in nodes) n.note.id: n};
      expect(byId['a']!.degree, 2);
      expect(byId['b']!.degree, 1);
      expect(byId['c']!.degree, 1);
    });

    test('ignore un lien dont une extrémité n\'existe pas', () {
      // Cas réel : fiche supprimée ou pas encore synchronisée.
      final nodes = KnowledgeGraph.buildNodes(
        [note('a')],
        [link('a', 'fantome')],
      );

      expect(nodes.single.degree, 0);
      expect(nodes.single.isIsolated, isTrue);
    });

    test('ne compte pas une boucle sur soi-même', () {
      final nodes = KnowledgeGraph.buildNodes([note('a')], [link('a', 'a')]);
      expect(nodes.single.degree, 0);
    });

    test('ne compte qu\'une fois deux liens de types différents', () {
      final nodes = KnowledgeGraph.buildNodes(
        [note('a'), note('b')],
        [
          link('a', 'b'),
          link('a', 'b', type: NoteLinkType.toReview),
        ],
      );

      // Le degré compte les fiches voisines, pas les arêtes.
      expect(nodes.first.degree, 1);
    });
  });

  group('composantes connexes', () {
    test('regroupe les fiches reliées, sépare les îlots', () {
      final nodes = KnowledgeGraph.buildNodes(
        [note('a'), note('b'), note('c'), note('d')],
        [link('a', 'b'), link('c', 'd')],
      );

      final byId = {for (final n in nodes) n.note.id: n};
      expect(byId['a']!.componentId, byId['b']!.componentId);
      expect(byId['c']!.componentId, byId['d']!.componentId);
      expect(byId['a']!.componentId, isNot(byId['c']!.componentId));
    });

    test('relie transitivement a-b-c en une seule composante', () {
      final nodes = KnowledgeGraph.buildNodes(
        [note('a'), note('b'), note('c')],
        [link('a', 'b'), link('b', 'c')],
      );

      expect(nodes.map((n) => n.componentId).toSet(), hasLength(1));
    });
  });

  group('KnowledgeGraph.analyse', () {
    test('repère les fiches isolées', () {
      final insights = KnowledgeGraph.analyse(
        [note('a'), note('b'), note('seule')],
        [link('a', 'b')],
      );

      expect(insights.isolatedNotes.map((n) => n.id), ['seule']);
      expect(insights.summary, contains('reliée à rien'));
    });

    test('compte les îlots', () {
      final insights = KnowledgeGraph.analyse(
        [note('a'), note('b'), note('c'), note('d')],
        [link('a', 'b'), link('c', 'd')],
      );

      expect(insights.componentCount, 2);
      expect(insights.largestComponentSize, 2);
      expect(insights.summary, contains('îlots'));
    });

    test('identifie une plaque tournante', () {
      // « centre » est relié à 4 fiches, les autres à 1 seule.
      final notes = [
        note('centre'),
        note('a'),
        note('b'),
        note('c'),
        note('d'),
      ];
      final links = [
        link('centre', 'a'),
        link('centre', 'b'),
        link('centre', 'c'),
        link('centre', 'd'),
      ];

      final insights = KnowledgeGraph.analyse(notes, links);
      expect(insights.hubs.map((n) => n.id), contains('centre'));
    });

    test('ne qualifie pas de pivot une fiche à 2 liens sur un petit carnet', () {
      final insights = KnowledgeGraph.analyse(
        [note('a'), note('b'), note('c')],
        [link('a', 'b'), link('a', 'c')],
      );

      expect(insights.hubs, isEmpty);
    });

    test('rend un diagnostic vide sans fiche', () {
      final insights = KnowledgeGraph.analyse(const [], const []);
      expect(insights.isEmpty, isTrue);
      expect(insights.componentCount, 0);
      expect(insights.summary, contains('Crée quelques fiches'));
    });

    test('calcule le degré moyen', () {
      final insights = KnowledgeGraph.analyse(
        [note('a'), note('b')],
        [link('a', 'b')],
      );

      expect(insights.averageDegree, 1.0);
    });
  });

  group('KnowledgeGraph.suggest', () {
    test('propose les fiches partageant un tag', () {
      final suggestions = KnowledgeGraph.suggest(
        [note('a', tags: ['maths']), note('b', tags: ['maths'])],
        const [],
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.single.reason, contains('maths'));
    });

    test('ne propose pas une paire déjà reliée', () {
      final notes = [note('a', tags: ['maths']), note('b', tags: ['maths'])];

      expect(KnowledgeGraph.suggest(notes, [link('a', 'b')]), isEmpty);
      // Le sens du lien existant ne doit pas rouvrir la suggestion.
      expect(KnowledgeGraph.suggest(notes, [link('b', 'a')]), isEmpty);
    });

    test('ne propose rien sur le seul sujet commun', () {
      // Sans tag partagé, tout un chapitre se relierait à lui-même.
      final suggestions = KnowledgeGraph.suggest(
        [note('a', subject: 'Physique'), note('b', subject: 'Physique')],
        const [],
      );

      expect(suggestions, isEmpty);
    });

    test('classe les paires les plus proches en premier', () {
      final notes = [
        note('a', tags: ['maths', 'exam'], subject: 'Maths'),
        note('b', tags: ['maths', 'exam'], subject: 'Maths'),
        note('c', tags: ['maths']),
      ];

      final suggestions = KnowledgeGraph.suggest(notes, const []);

      expect(suggestions.first.score, greaterThan(suggestions.last.score));
      expect({suggestions.first.sourceId, suggestions.first.targetId},
          {'a', 'b'});
    });

    test('exclut les fiches archivées', () {
      final suggestions = KnowledgeGraph.suggest(
        [
          note('a', tags: ['maths']),
          note('b', tags: ['maths'], archived: true),
        ],
        const [],
      );

      expect(suggestions, isEmpty);
    });

    test('respecte la limite demandée', () {
      final notes = [
        for (var i = 0; i < 10; i++) note('n$i', tags: ['commun']),
      ];

      expect(KnowledgeGraph.suggest(notes, const [], limit: 3), hasLength(3));
    });
  });

  group('KnowledgeGraph.neighboursOf', () {
    test('rend les voisins dans les deux sens', () {
      final neighbours = KnowledgeGraph.neighboursOf(
        'a',
        [note('a'), note('b'), note('c')],
        [link('a', 'b'), link('c', 'a')],
      );

      expect(neighbours.map((entry) => entry.$1.id).toSet(), {'b', 'c'});
    });

    test('ignore une boucle sur soi-même', () {
      final neighbours =
          KnowledgeGraph.neighboursOf('a', [note('a')], [link('a', 'a')]);
      expect(neighbours, isEmpty);
    });
  });

  group('NoteLink', () {
    test('otherEnd rend l\'extrémité opposée, ou null', () {
      final l = link('a', 'b');
      expect(l.otherEnd('a'), 'b');
      expect(l.otherEnd('b'), 'a');
      expect(l.otherEnd('z'), isNull);
    });

    test('« lié à » est symétrique, « à revoir » ne l\'est pas', () {
      expect(link('a', 'b').isSameEdgeAs(link('b', 'a')), isTrue);

      final directed = link('a', 'b', type: NoteLinkType.toReview);
      final reversed = link('b', 'a', type: NoteLinkType.toReview);
      expect(directed.isSameEdgeAs(reversed), isFalse);
    });

    test('des types différents ne sont jamais la même arête', () {
      expect(
        link('a', 'b').isSameEdgeAs(link('a', 'b', type: NoteLinkType.seen)),
        isFalse,
      );
    });

    test('fait l\'aller-retour JSON', () {
      final original = link('a', 'b', type: NoteLinkType.prerequisite);
      final restored = NoteLink.fromJson(original.toJson());

      expect(restored.sourceId, 'a');
      expect(restored.targetId, 'b');
      expect(restored.type, NoteLinkType.prerequisite);
    });

    test('retombe sur « lié à » pour un type inconnu', () {
      expect(NoteLinkType.fromValue('inventé'), NoteLinkType.related);
      expect(NoteLinkType.fromValue(null), NoteLinkType.related);
    });
  });
}
