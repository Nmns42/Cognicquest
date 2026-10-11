import 'dart:async';

import 'package:cognicquest/features/graph/data/note_link_repository.dart';
import 'package:cognicquest/features/graph/domain/graph_layout.dart';
import 'package:cognicquest/features/graph/providers/graph_provider.dart';
import 'package:cognicquest/features/graph/views/graph_page.dart';
import 'package:cognicquest/features/notes/providers/note_provider.dart';
import 'package:cognicquest/shared/models/note_link_model.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'knowledge_graph_test.dart' show note;

/// Chantier 12 (A) : deux recalculs asynchrones qui se chevauchent.
///
/// Le calcul est remplacé par des `Completer` pour décider de l'ordre
/// d'arrivée des résultats : celui d'un calcul dépassé ne doit jamais
/// remplacer la carte la plus récente.
void main() {
  final pending =
      <(List<String>, Completer<GraphLayout>, List<(String, String)>)>[];

  setUp(() {
    pending.clear();
    graphLayoutAsync = (ids, edges) {
      final completer = Completer<GraphLayout>();
      pending.add((ids, completer, edges));
      return completer.future;
    };
  });

  tearDown(() => graphLayoutAsync = GraphLayout.computeAsync);

  /// Termine le calcul n° [index] avec la vraie disposition de son entrée.
  void finish(int index) {
    final (ids, completer, edges) = pending[index];
    completer.complete(GraphLayout.compute(ids, edges));
  }

  List<Note> notebook(int count) =>
      [for (var i = 0; i < count; i++) note('n${i.toString().padLeft(2, '0')}')];

  Widget app(StreamController<List<Note>> notes) => ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) => notes.stream),
          noteLinksProvider
              .overrideWith((ref) => Stream.value(const <NoteLink>[])),
          noteLinkRepositoryProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: GraphPage()),
      );

  const above = GraphLayout.asyncThreshold + 6;

  testWidgets('le résultat d\'un calcul dépassé n\'écrase pas le plus récent',
      (tester) async {
    final notes = StreamController<List<Note>>();
    addTearDown(notes.close);
    await tester.pumpWidget(app(notes));

    // Premier carnet, puis ajout rapide d'une fiche : deux calculs en vol.
    notes.add(notebook(above));
    await tester.pump();
    notes.add(notebook(above + 1));
    await tester.pump();
    expect(pending, hasLength(2));

    // Ordre inverse : le plus récent se termine d'abord…
    finish(1);
    await tester.pump();
    final newest = 'Fiche n${(above).toString().padLeft(2, '0')}';
    expect(find.text(newest), findsOneWidget);

    // … puis l'ancien, qui ne connaît pas la dernière fiche.
    finish(0);
    await tester.pump();
    expect(find.text(newest), findsOneWidget,
        reason: 'la carte la plus récente a été remplacée par une ancienne');
    expect(tester.takeException(), isNull);
  });

  testWidgets('quitter la page pendant le calcul ne provoque aucune erreur',
      (tester) async {
    final notes = StreamController<List<Note>>();
    addTearDown(notes.close);
    await tester.pumpWidget(app(notes));
    notes.add(notebook(above));
    await tester.pump();
    expect(pending, hasLength(1));

    // L'utilisateur quitte la carte avant la fin du calcul.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    finish(0);
    await tester.pump();

    // Un setState après dispose lèverait ici une FlutterError.
    expect(tester.takeException(), isNull);
  });
}
