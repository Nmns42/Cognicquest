import 'dart:async';
import 'dart:convert';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/kanban/data/task_repository.dart';
import 'package:cognicquest/features/kanban/providers/task_provider.dart';
import 'package:cognicquest/features/kanban/views/kanban_page.dart';
import 'package:cognicquest/shared/models/task_model.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dépôt en mémoire : le tableau suit son flux comme il suit SQLite.
class _MemoryTaskRepository implements TaskRepository {
  _MemoryTaskRepository(List<Task> tasks) : _tasks = [...tasks];

  List<Task> _tasks;
  final _changes = StreamController<List<Task>>.broadcast();
  int writes = 0;

  List<Task> get tasks => List.unmodifiable(_tasks);

  @override
  Stream<List<Task>> watchAll() async* {
    yield tasks;
    yield* _changes.stream;
  }

  void _apply(List<Task> changed) {
    writes++;
    final byId = {for (final t in changed) t.id: t};
    _tasks = [for (final t in _tasks) byId[t.id] ?? t];
    _changes.add(tasks);
  }

  @override
  Future<void> saveOrder(List<Task> tasks) async => _apply(tasks);

  @override
  Future<void> update(Task task) async => _apply([task]);

  @override
  Future<Task> create(Task task) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<void> sync() async {}
}

/// Faux PostgREST pour `tasks` (updated_at posé par le serveur, comme le
/// trigger).
class _FakeTasksServer {
  final Map<String, Map<String, dynamic>> rows = {};
  var _tick = 0;

  late final MockClient client = MockClient((request) async {
    final json = {'content-type': 'application/json'};
    final params = request.url.queryParameters;
    switch (request.method) {
      case 'GET':
        var result = rows.values.toList();
        final filter = params['updated_at'];
        if (filter != null && filter.startsWith('gt.')) {
          final from = DateTime.parse(filter.substring(3));
          result = result
              .where((r) =>
                  DateTime.parse(r['updated_at'] as String).isAfter(from))
              .toList();
        }
        if (params['select'] == 'id') {
          result = [for (final r in result) {'id': r['id']}];
        }
        return http.Response(jsonEncode(result), 200,
            headers: json, request: request);
      case 'POST':
        final decoded = jsonDecode(request.body);
        final bodies = decoded is List ? decoded : [decoded];
        for (final body in bodies.cast<Map<String, dynamic>>()) {
          rows[body['id'] as String] = {
            ...body,
            'updated_at': DateTime.utc(2030, 1, 1, 12, 0, _tick++)
                .toIso8601String(),
          };
        }
        return http.Response('', 201, request: request);
    }
    return http.Response('non simulé', 500, request: request);
  });
}

Task _task(String id, TaskStatus status, int position) => Task(
      id: id,
      userId: 'u1',
      title: id,
      description: '',
      status: status,
      priority: TaskPriority.medium,
      createdAt: DateTime(2026, 10, 1),
      position: position,
    );

/// Titres d'une colonne, dans l'ordre affiché.
List<String> _column(List<Task> tasks, TaskStatus status) => [
      for (final t in tasks.where((t) => t.status == status).toList()
        ..sort((a, b) => a.position.compareTo(b.position)))
        t.title,
    ];

Future<_MemoryTaskRepository> _pumpBoard(
  WidgetTester tester,
  List<Task> tasks, {
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MemoryTaskRepository(tasks);
  await tester.pumpWidget(ProviderScope(
    overrides: [taskRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: KanbanPage()),
  ));
  await tester.pumpAndSettle();
  return repository;
}

/// Appui long sur [card], puis glisser jusqu'à [to] (calculé au dernier
/// moment, la liste ayant pu défiler) et lâcher.
Future<TestGesture> _grab(WidgetTester tester, Finder card) async {
  final gesture = await tester.startGesture(tester.getCenter(card));
  await tester.pump(const Duration(milliseconds: 300));
  // Premier mouvement : le glisser démarre.
  await gesture.moveBy(const Offset(0, 8));
  await tester.pump();
  return gesture;
}

Future<void> _dropOn(
    WidgetTester tester, TestGesture gesture, Finder target) async {
  // Près d'un bord, la liste défile seule pendant le glisser : on suit la
  // cible jusqu'à ce qu'elle ne bouge plus, puis on lâche dessus.
  var to = tester.getCenter(target);
  for (var i = 0; i < 40; i++) {
    await gesture.moveTo(to);
    await tester.pump(const Duration(milliseconds: 50));
    // La cible peut changer de libellé au survol (« Déposer dans… ») : on
    // garde alors la dernière position connue.
    if (target.evaluate().isEmpty) break;
    final now = tester.getCenter(target);
    if ((now - to).distance < 1) break;
    to = now;
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Finder _card(String title) => find.text(title).first;

void main() {
  group('Kanban — glisser entre colonnes', () {
    testWidgets(
        '(a) téléphone : accordéon, on dépose sur l’en-tête du tiroir fermé',
        (tester) async {
      final repository = await _pumpBoard(tester, [
        for (var i = 0; i < 6; i++) _task('A$i', TaskStatus.todo, i),
        for (var i = 0; i < 6; i++) _task('B$i', TaskStatus.doing, i),
        _task('D0', TaskStatus.done, 0),
        _task('D1', TaskStatus.done, 1),
      ]);
      // Seul « À faire » est ouvert : les tâches terminées sont repliées.
      expect(find.text('D1'), findsNothing);
      expect(find.text('Terminé').hitTestable(), findsOneWidget);

      final gesture = await _grab(tester, _card('A0'));
      await _dropOn(tester, gesture, find.text('Terminé').hitTestable());

      final a0 = repository.tasks.firstWhere((t) => t.id == 'A0');
      expect(a0.status, TaskStatus.done);
      expect(_column(repository.tasks, TaskStatus.done), contains('A0'));
      expect(_column(repository.tasks, TaskStatus.todo),
          ['A1', 'A2', 'A3', 'A4', 'A5']);
    });

    testWidgets(
        '(a bis) grand écran : colonnes côte à côte, la tâche se place où on '
        'la lâche', (tester) async {
      final repository = await _pumpBoard(
        tester,
        [
          _task('A0', TaskStatus.todo, 0),
          _task('D0', TaskStatus.done, 0),
          _task('D1', TaskStatus.done, 1),
        ],
        size: const Size(1280, 800),
      );
      // Pas d'accordéon : les trois colonnes sont visibles.
      expect(find.text('D1').hitTestable(), findsOneWidget);

      final gesture = await _grab(tester, _card('A0'));
      await _dropOn(tester, gesture, find.text('D1').hitTestable());

      expect(_column(repository.tasks, TaskStatus.done), ['D0', 'A0', 'D1']);
    });

    testWidgets(
        '(a quater) grand écran, à la souris : glisser horizontal d’une '
        'colonne à l’autre', (tester) async {
      final repository = await _pumpBoard(
        tester,
        [
          _task('A0', TaskStatus.todo, 0),
          _task('D0', TaskStatus.done, 0),
        ],
        size: const Size(1280, 800),
      );
      final from = tester.getCenter(_card('A0'));
      final to = tester.getCenter(find.text('D0'));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: from - const Offset(0, 40));
      await mouse.moveTo(from);
      await tester.pump();
      await mouse.down(from);
      // Mouvement horizontal, celui qu'un balayage de suppression capterait.
      for (var i = 1; i <= 10; i++) {
        await mouse.moveTo(Offset.lerp(from, to, i / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await mouse.up();
      await tester.pumpAndSettle();

      expect(repository.tasks.firstWhere((t) => t.id == 'A0').status,
          TaskStatus.done);
    });

    testWidgets(
        '(a ter) téléphone : indicateur fixe et un seul tiroir ouvert',
        (tester) async {
      await _pumpBoard(tester, [
        for (var i = 0; i < 4; i++) _task('A$i', TaskStatus.todo, i),
        for (var i = 0; i < 2; i++) _task('B$i', TaskStatus.doing, i),
        _task('D0', TaskStatus.done, 0),
      ]);
      expect(find.text('À FAIRE'), findsOneWidget);
      expect(find.text('4'), findsWidgets);

      // Ouvrir « En cours » referme « À faire ».
      await tester.tap(find.text('EN COURS'));
      await tester.pumpAndSettle();
      expect(find.text('B0'), findsOneWidget);
      expect(find.text('A0'), findsNothing);
    });

    testWidgets(
        '(b) dans une même colonne, la carte descendue se place juste avant '
        'la carte visée', (tester) async {
      final repository = await _pumpBoard(tester, [
        _task('A0', TaskStatus.todo, 0),
        _task('A1', TaskStatus.todo, 1),
        _task('A2', TaskStatus.todo, 2),
        _task('A3', TaskStatus.todo, 3),
      ]);

      // Descendre : A0 lâchée sur A2 → avant A2.
      var gesture = await _grab(tester, _card('A0'));
      await _dropOn(tester, gesture, _card('A2'));
      expect(_column(repository.tasks, TaskStatus.todo),
          ['A1', 'A0', 'A2', 'A3']);

      // Monter : A3 lâchée sur A1 → avant A1.
      gesture = await _grab(tester, _card('A3'));
      await _dropOn(tester, gesture, _card('A1'));
      expect(_column(repository.tasks, TaskStatus.todo),
          ['A3', 'A1', 'A0', 'A2']);
      // Positions denses : le mécanisme tasks.position est inchangé.
      expect(
          [for (final t in repository.tasks) t.position]..sort(), [0, 1, 2, 3]);
    });

    testWidgets('(c) lâcher hors d’une colonne ne change rien',
        (tester) async {
      final tasks = [
        _task('A0', TaskStatus.todo, 0),
        _task('A1', TaskStatus.todo, 1),
        _task('D0', TaskStatus.done, 0),
      ];
      final repository = await _pumpBoard(tester, tasks);

      final gesture = await _grab(tester, _card('A0'));
      // Hors de toute colonne : sur la bascule de vue, en haut à droite.
      await _dropOn(tester, gesture, find.byTooltip('Vue Kanban'));

      expect(repository.writes, 0);
      expect(repository.tasks, tasks);
      // La carte est revenue à sa place, pleinement visible.
      expect(find.text('A0').hitTestable(), findsOneWidget);
    });

    testWidgets('(d) faire défiler la liste ne saisit pas de carte',
        (tester) async {
      final tasks = [
        for (var i = 0; i < 6; i++) _task('A$i', TaskStatus.todo, i),
        for (var i = 0; i < 6; i++) _task('B$i', TaskStatus.doing, i),
        _task('D0', TaskStatus.done, 0),
      ];
      final repository = await _pumpBoard(tester, tasks);
      final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first);

      // Glissé rapide du doigt partant d'une carte, sans appui long.
      final gesture = await tester.startGesture(tester.getCenter(_card('A2')));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -30));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, greaterThan(0),
          reason: 'la liste doit avoir défilé');
      expect(repository.writes, 0);
      expect(repository.tasks, tasks);
    });

    testWidgets(
        '(e) « Déplacer vers… » donne le même résultat que le glisser sur '
        'la colonne', (tester) async {
      List<Task> board() => [
            _task('A0', TaskStatus.todo, 0),
            _task('A1', TaskStatus.todo, 1),
            _task('D0', TaskStatus.done, 0),
            _task('D1', TaskStatus.done, 1),
          ];

      // Par le glisser : A0 lâchée sur l'en-tête de la colonne « Terminé ».
      final dragged = await _pumpBoard(tester, board());
      final gesture = await _grab(tester, _card('A0'));
      await _dropOn(tester, gesture, find.text(TaskStatus.done.label));

      // Par le menu, sans glisser, sur un tableau neuf.
      await tester.pumpWidget(const SizedBox());
      final menu = await _pumpBoard(tester, board());
      final card = find.ancestor(
          of: find.text('A0'), matching: find.byType(Card));
      await tester.tap(find.descendant(
          of: card, matching: find.byTooltip('Déplacer vers…')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Déplacer vers « Terminé »'));
      await tester.pumpAndSettle();

      expect(menu.tasks.firstWhere((t) => t.id == 'A0').status,
          TaskStatus.done);
      for (final status in TaskStatus.values) {
        expect(_column(menu.tasks, status), _column(dragged.tasks, status),
            reason: status.label);
      }
      expect(_column(menu.tasks, TaskStatus.done), ['D0', 'D1', 'A0']);
    });

    testWidgets('(e bis) « Monter » et « Descendre » réordonnent sans glisser',
        (tester) async {
      final repository = await _pumpBoard(tester, [
        _task('A0', TaskStatus.todo, 0),
        _task('A1', TaskStatus.todo, 1),
        _task('A2', TaskStatus.todo, 2),
      ]);
      Future<void> choose(String title, String action) async {
        final card = find.ancestor(
            of: find.text(title), matching: find.byType(Card));
        await tester.tap(find.descendant(
            of: card, matching: find.byTooltip('Déplacer vers…')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
      }

      await choose('A0', 'Descendre');
      expect(_column(repository.tasks, TaskStatus.todo), ['A1', 'A0', 'A2']);
      await choose('A2', 'Monter');
      expect(_column(repository.tasks, TaskStatus.todo), ['A1', 'A2', 'A0']);
    });
  });

  test('(f) statut et position survivent à un aller-retour push / pull',
      () async {
    final server = _FakeTasksServer();
    final opened = <Future<void> Function()>[];
    ({LocalFirstTaskRepository repo, ProviderContainer container}) device() {
      final db = AppDatabase(NativeDatabase.memory());
      final client = SupabaseClient('http://fake.local', 'anon-key',
          httpClient: server.client,
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      final repo =
          LocalFirstTaskRepository(database: db, client: client, userId: 'u1');
      final container = ProviderContainer(
          overrides: [taskRepositoryProvider.overrideWithValue(repo)]);
      opened.add(() async {
        container.dispose();
        await repo.sync().catchError((_) {});
        await client.dispose();
        await db.close();
      });
      return (repo: repo, container: container);
    }

    addTearDown(() async {
      for (final close in opened) {
        await close();
      }
    });

    Future<List<Task>> settled(LocalFirstTaskRepository repo) async {
      await repo.sync();
      return repo.watchAll().first;
    }

    // Appareil A : trois tâches, puis les deux déplacements du tableau.
    final a = device();
    for (final t in [
      _task('A0', TaskStatus.todo, 0),
      _task('A1', TaskStatus.todo, 1),
      _task('A2', TaskStatus.todo, 2),
      _task('D0', TaskStatus.done, 0),
    ]) {
      await a.repo.saveOrder([t]);
    }
    await settled(a.repo);
    await a.container.read(taskProvider.future);
    final notifier = a.container.read(taskProvider.notifier);
    // Glisser A0 sur D0 (autre colonne), puis A1 sur… la fin de « À faire ».
    await notifier.moveTask('A0', TaskStatus.done, beforeTaskId: 'D0');
    await notifier.moveTask('A1', TaskStatus.todo);
    final expected = await settled(a.repo);

    // Appareil B, neuf : tout vient du serveur.
    final b = device();
    final pulled = await settled(b.repo);

    String describe(List<Task> tasks) => [
          for (final status in TaskStatus.values)
            '${status.value}: ${_column(tasks, status).join(',')}',
        ].join(' | ');
    expect(describe(expected), 'todo: A2,A1 | doing:  | done: A0,D0');
    expect(describe(pulled), describe(expected));
    expect({for (final t in pulled) t.id: (t.status, t.position)},
        {for (final t in expected) t.id: (t.status, t.position)});
  });
}
