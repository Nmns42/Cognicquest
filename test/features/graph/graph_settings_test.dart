import 'package:cognicquest/features/graph/domain/graph_layout.dart';
import 'package:cognicquest/features/graph/domain/graph_settings.dart';
import 'package:cognicquest/shared/models/note_link_model.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:flutter_test/flutter_test.dart';

Note note(String id, String title,
        {String content = '', List<NoteBlock> blocks = const [], String? folder}) =>
    Note(
      id: id,
      userId: 'u',
      title: title,
      content: content,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      blocks: blocks,
      folderId: folder,
    );

NoteLink link(String a, String b) => NoteLink(
      id: '$a-$b',
      userId: 'u',
      sourceId: a,
      targetId: b,
      type: NoteLinkType.related,
      createdAt: DateTime(2026),
    );

void main() {
  final notes = [
    note('a', 'Thermodynamique', content: 'Voir [[Entropie]] et [[Carnot]]',
        blocks: [
          NoteBlock(
              id: 'img',
              noteId: 'a',
              type: NoteBlockType.image,
              content: 'media://u/x.png',
              position: 0),
        ]),
    note('b', 'Carnot'),
    note('c', 'Orpheline'),
  ];
  final links = [link('a', 'b')];

  test('par défaut : fiches réelles seulement, orphelines comprises', () {
    final view = GraphView.build(notes, links, GraphSettings.defaults);
    expect(view.nodes.map((n) => n.note.id), unorderedEquals(['a', 'b', 'c']));
    expect(view.links, hasLength(1));
  });

  test('recherche par mot-clé (titre ou texte)', () {
    final view = GraphView.build(
        notes, links, const GraphSettings(query: 'entropie'));
    expect(view.nodes.map((n) => n.note.id), ['a']);
  });

  test('orphelines masquées', () {
    final view = GraphView.build(
        notes, links, const GraphSettings(showOrphans: false));
    expect(view.nodes.map((n) => n.note.id), unorderedEquals(['a', 'b']));
  });

  test('pièces jointes en satellites reliés à leur fiche', () {
    final view = GraphView.build(
        notes, links, const GraphSettings(showAttachments: true));
    final attachment =
        view.nodes.singleWhere((n) => GraphNodeIds.isAttachment(n.note.id));
    expect(attachment.note.title, 'Image');
    expect(view.links.any((l) =>
        l.sourceId == 'a' && l.targetId == attachment.note.id), isTrue);
  });

  test('fichiers inexistants : [[Entropie]] devient un nœud fantôme', () {
    final view = GraphView.build(
        notes, links, const GraphSettings(existingOnly: false));
    final ghosts =
        view.nodes.where((n) => GraphNodeIds.isGhost(n.note.id)).toList();
    // [[Carnot]] existe : pas de fantôme pour lui.
    expect(ghosts.map((n) => n.note.title), ['Entropie']);
  });

  test('réglages : aller-retour JSON et bornes', () {
    const settings = GraphSettings(
      query: 'x',
      showAttachments: true,
      groupByFolder: true,
      nodeSize: 2,
      forces: GraphForces(center: 0.1, repel: 2, link: 1.2, distance: 220),
    );
    final back = GraphSettings.fromJson(settings.toJson());
    expect(back.query, 'x');
    expect(back.groupByFolder, isTrue);
    expect(back.nodeSize, 2);
    expect(back.forces, settings.forces);

    final clamped = GraphSettings.fromJson({'distance': 9999, 'node_size': -3});
    expect(clamped.forces.distance, GraphForces.distanceRange.max);
    expect(clamped.nodeSize, GraphSettings.nodeSizeRange.min);
  });

  test('forces : une distance plus grande écarte les fiches reliées', () {
    double spread(double distance) {
      final simulation = GraphSimulation()
        ..forces = GraphForces(distance: distance);
      simulation.load(
          GraphLayout.compute(['a', 'b'], [('a', 'b')]), [('a', 'b')]);
      simulation.settle();
      return (simulation.positions['a']! - simulation.positions['b']!).distance;
    }

    expect(spread(300), greaterThan(spread(80) * 1.5));
  });
}
