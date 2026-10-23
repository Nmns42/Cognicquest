import 'package:cognicquest/core/config/app_config.dart';
import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/dev/demo_seed.dart';
import 'package:cognicquest/features/graph/data/note_link_repository.dart';
import 'package:cognicquest/features/graph/domain/graph_layout.dart';
import 'package:cognicquest/features/graph/domain/knowledge_graph.dart';
import 'package:cognicquest/features/graph/providers/graph_provider.dart';
import 'package:cognicquest/features/graph/views/graph_page.dart';
import 'package:cognicquest/features/notes/providers/note_provider.dart';
import 'package:cognicquest/shared/models/note_link_model.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mêmes fabriques que les tests du domaine : une fiche ou un lien construits
// ici sont identiques à ceux de knowledge_graph_test.
import 'knowledge_graph_test.dart' show link, note;

/// Carnet dense : [count] fiches réparties sur 4 sujets, chacune reliée à ses
/// deux suivantes et à une fiche « pivot » tous les 5, avec tous les types de
/// lien. Les [isolated] dernières fiches ne sont reliées à rien.
({List<Note> notes, List<NoteLink> links}) denseNotebook({
  int count = 60,
  int isolated = 4,
}) {
  const subjects = ['Maths', 'Physique', 'Info', 'Méthodo'];
  final notes = [
    for (var i = 0; i < count; i++)
      note('n$i', subject: subjects[i % subjects.length], tags: ['t${i % 7}']),
  ];
  final connected = count - isolated;
  const types = NoteLinkType.values;
  final links = <NoteLink>[
    for (var i = 0; i < connected; i++) ...[
      if (i + 1 < connected)
        link('n$i', 'n${i + 1}', type: types[i % types.length]),
      if (i + 2 < connected)
        link('n$i', 'n${i + 2}', type: types[(i + 1) % types.length]),
      if (i % 5 == 0 && i != 0) link('n$i', 'n0'),
    ],
    // Bruit réaliste : lien vers une fiche supprimée et boucle.
    link('n1', 'supprimee'),
    link('n2', 'n2'),
  ];
  return (notes: notes, links: links);
}

Widget graphApp({required List<Note> notes, required List<NoteLink> links}) {
  return ProviderScope(
    overrides: [
      notesProvider.overrideWith((ref) => Stream.value(notes)),
      noteLinksProvider.overrideWith((ref) => Stream.value(links)),
      noteLinkRepositoryProvider.overrideWithValue(null),
    ],
    child: const MaterialApp(home: GraphPage()),
  );
}

/// Point d'une fiche : peint sur la toile, il est repéré par sa sémantique
/// (titre annoncé aux lecteurs d'écran, cf. `semanticsBuilder`).
FinderBase<SemanticsNode> chipOf(String id) =>
    find.semantics.byLabel('Fiche $id');

/// Centre à l'écran (pixels logiques) du point d'une fiche : toutes les
/// transformations de l'arbre sémantique, ramenées des pixels physiques.
Offset centerOf(WidgetTester tester, String id) {
  final node = chipOf(id).evaluate().single;
  var rect = node.rect;
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    if (n.transform != null) rect = MatrixUtils.transformRect(n.transform!, rect);
  }
  return rect.center / tester.view.devicePixelRatio;
}

/// Attend la fin du calcul de disposition. Au-delà de
/// [GraphLayout.asyncThreshold] fiches, il tourne dans un isolate, qui
/// n'avance pas dans le temps simulé de `testWidgets` : on lui laisse du
/// temps réel jusqu'à ce que l'indicateur de chargement disparaisse.
Future<void> settleGraph(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 200; i++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  group('GraphPage — carnet dense', () {
    late List<Note> notes;
    late List<NoteLink> links;

    setUp(() {
      final notebook = denseNotebook();
      notes = notebook.notes;
      links = notebook.links;
    });

    testWidgets('affiche toutes les fiches, isolées comprises', (tester) async {
      await tester.pumpWidget(graphApp(notes: notes, links: links));
      await settleGraph(tester);

      for (final n in notes) {
        expect(chipOf(n.id), findsOne, reason: 'fiche ${n.id} absente');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('la carte ne bouge pas quand on sélectionne un nœud',
        (tester) async {
      await tester.pumpWidget(graphApp(notes: notes, links: links));
      await settleGraph(tester);

      final before = centerOf(tester, 'n10');
      await tester.tapAt(centerOf(tester, 'n0'));
      await tester.pumpAndSettle();
      // Ferme l'aperçu ouvert par le tap.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(centerOf(tester, 'n10'), before);
    });

    testWidgets('le filtre par sujet ne garde que les fiches du sujet',
        (tester) async {
      await tester.pumpWidget(graphApp(notes: notes, links: links));
      await settleGraph(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Physique'));
      await settleGraph(tester);

      expect(chipOf('n1'), findsOne); // Physique
      expect(chipOf('n0'), findsNothing); // Maths
      expect(chipOf('n2'), findsNothing); // Info
    });

    testWidgets('le bouton Recentrer et le zoom ne lèvent pas d\'erreur',
        (tester) async {
      await tester.pumpWidget(graphApp(notes: notes, links: links));
      await settleGraph(tester);

      await tester.tap(find.byTooltip('Recentrer'));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const Key('graph-canvas')),
          const Offset(-200, 80));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('attraper un point le déplace, ses voisins le suivent',
        (tester) async {
      await tester.pumpWidget(graphApp(notes: notes, links: links));
      await settleGraph(tester);

      final start = centerOf(tester, 'n20');
      final neighbour = centerOf(tester, 'n21');
      final far = centerOf(tester, 'n58');

      // Glissé lentement, comme un doigt : la simulation tourne pendant le
      // geste.
      final gesture = await tester.startGesture(start);
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(12, 6));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // Lâché, le point reste là où on l'a posé (à l'élasticité près). La
      // carte de départ dépend de cos/sin, qui diffèrent d'un système à
      // l'autre (≈ 83 px sous Linux, plus sous Windows) : le seuil garde
      // juste l'écart net avec la fiche isolée (< 40 px).
      expect((centerOf(tester, 'n20') - start).distance, greaterThan(60));
      expect((centerOf(tester, 'n21') - neighbour).distance, greaterThan(5),
          reason: 'la voisine doit suivre le point déplacé');

      // Une fiche isolée, sans lien, bouge à peine.
      expect((centerOf(tester, 'n58') - far).distance, lessThan(40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('l\'encadré d\'analyse se ferme d\'une croix', (tester) async {
      await tester.pumpWidget(graphApp(notes: notes, links: links));
      await settleGraph(tester);

      expect(find.byTooltip('Fermer l’analyse'), findsOneWidget);
      await tester.tap(find.byTooltip('Fermer l’analyse'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Fermer l’analyse'), findsNothing);
    });

    testWidgets('un carnet vide propose d\'aller aux fiches', (tester) async {
      await tester.pumpWidget(graphApp(notes: const [], links: const []));
      await tester.pumpAndSettle();

      expect(find.text('Pas encore de carte'), findsOneWidget);
    });
  });

  group('Graphe sur le jeu de démo (cf. demo_seed_test)', () {
    test('les providers du graphe voient les 8 fiches et 10 liens seedés',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final client = SupabaseClient(
        'http://offline.invalid',
        'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        supabaseClientProvider.overrideWithValue(client),
        currentUserIdProvider.overrideWithValue(AppConfig.devUserId),
      ]);
      addTearDown(() async {
        container.dispose();
        await client.dispose();
        await db.close();
      });

      final seed = FutureProvider<void>((ref) => runDemoSeed(ref, db));
      await container.read(seed.future);

      // Les flux Drift émettent de façon asynchrone : on attend leur valeur.
      final sub1 = container.listen(notesProvider, (_, __) {});
      final sub2 = container.listen(noteLinksProvider, (_, __) {});
      addTearDown(sub1.close);
      addTearDown(sub2.close);
      await container.read(notesProvider.future);
      await container.read(noteLinksProvider.future);

      final nodes = container.read(graphNodesProvider);
      final graphLinks = container.read(visibleLinksProvider);
      final insights = container.read(graphInsightsProvider);

      expect(nodes, hasLength(8));
      expect(graphLinks, hasLength(10));
      expect(insights.isolatedNotes, isEmpty);
      expect(insights.componentCount, 1);

      final layout = GraphLayout.compute(
        nodes.map((n) => n.note.id),
        graphLinks.map((l) => (l.sourceId, l.targetId)),
      );
      expect(layout.positions, hasLength(8));
    });
  });

  group('Passage à l\'échelle', () {
    test('300 fiches et ~900 liens : disposition sans chevauchement', () {
      final notebook = denseNotebook(count: 300, isolated: 20);
      final extra = [
        for (var i = 0; i < 280; i += 3) link('n$i', 'n${(i * 7) % 280}'),
      ];
      final allLinks = [...notebook.links, ...extra];

      final nodes = KnowledgeGraph.buildNodes(notebook.notes, allLinks);
      final insights = KnowledgeGraph.analyse(notebook.notes, allLinks);
      expect(insights.isolatedNotes, hasLength(20));
      expect(insights.hubs, isNotEmpty);

      final stopwatch = Stopwatch()..start();
      final layout = GraphLayout.compute(
        nodes.map((n) => n.note.id),
        allLinks.map((l) => (l.sourceId, l.targetId)),
        iterations: 150,
      );
      stopwatch.stop();

      expect(layout.positions, hasLength(300));
      final points = layout.positions.values.toList();
      var closest = double.infinity;
      for (var i = 0; i < points.length; i++) {
        for (var j = i + 1; j < points.length; j++) {
          final d = (points[i] - points[j]).distance;
          if (d < closest) closest = d;
        }
      }
      // spacing (170) × 0,75, à l'arrondi près.
      expect(closest, greaterThan(120));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
    });
  });
}
