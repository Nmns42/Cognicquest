import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/database/app_database.dart';
import '../../shared/models/habit_model.dart';
import '../../shared/models/metacognition_model.dart';
import '../../shared/models/note_link_model.dart';
import '../../shared/models/note_model.dart';
import '../../shared/models/planning_model.dart';
import '../../shared/models/task_model.dart';
import '../graph/data/note_link_repository.dart';
import '../habits/data/habit_repository.dart';
import '../kanban/data/task_repository.dart';
import '../metacognition/data/metacognition_repository.dart';
import '../auth/providers/auth_provider.dart';
import '../notes/data/folder_repository.dart';
import '../notes/data/note_repository.dart';
import '../planning/data/planning_repository.dart';
import '../pomodoro/data/pomodoro_repository.dart';
import '../review/data/review_repository.dart';

/// Jeu de données de démonstration, pour visualiser l'interface remplie.
///
/// Chargé une seule fois, et seulement en mode `DEV_BYPASS_AUTH` sur une base
/// locale vide : il ne peut jamais toucher les données d'un vrai compte.
final demoSeedProvider = FutureProvider<void>((ref) async {
  if (!AppConfig.devBypassAuth) return;

  final db = ref.watch(appDatabaseProvider);
  final alreadySeeded = await (db.select(db.localNotes)
        ..where((t) => t.userId.equals(AppConfig.devUserId))
        ..limit(1))
      .getSingleOrNull();
  if (alreadySeeded != null) return;

  try {
    await _DemoSeeder(ref.read, db, denseGraph: _DemoSeeder._denseGraph).run();
  } catch (error, stackTrace) {
    // Une démo incomplète ne doit pas empêcher l'app de démarrer.
    debugPrint('Démo : chargement interrompu ($error)\n$stackTrace');
  }
});

/// Point d'entrée exposé pour les tests : ils n'ont pas `DEV_BYPASS_AUTH`.
@visibleForTesting
Future<void> runDemoSeed(Ref ref, AppDatabase db, {bool denseGraph = false}) =>
    _DemoSeeder(ref.read, db, denseGraph: denseGraph).run();

/// Lecture d'un provider, commune à `Ref` et `WidgetRef`.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Résultat du bouton « Charger les données de démo ».
enum DemoLoadResult { loaded, alreadyLoaded, unavailable }

/// Titre d'une fiche de la démo : sa présence signale une démo déjà chargée.
const String demoMarkerTitle = 'Chapitre 2 – Dérivées';

/// Charge la démo dans le compte courant (bouton des réglages), sur la
/// version déployée comme en local. Les données passent par les dépôts
/// habituels : elles restent sur l'appareil et se synchronisent avec le
/// compte comme n'importe quelle saisie. Ne charge qu'une fois.
Future<DemoLoadResult> loadDemoData(ProviderReader read) async {
  final userId = read(currentUserIdProvider);
  if (userId == null || read(noteRepositoryProvider) == null) {
    return DemoLoadResult.unavailable;
  }
  final db = read(appDatabaseProvider);
  final existing = await (db.select(db.localNotes)
        ..where((t) =>
            t.userId.equals(userId) &
            t.title.equals(demoMarkerTitle) &
            t.isDeleted.equals(false))
        ..limit(1))
      .getSingleOrNull();
  if (existing != null) return DemoLoadResult.alreadyLoaded;

  await _DemoSeeder(read, db).run();
  return DemoLoadResult.loaded;
}

class _DemoSeeder {
  _DemoSeeder(this.read, this.db, {this.denseGraph = false});

  final ProviderReader read;
  final AppDatabase db;

  /// Ajoute le carnet dense des tests du graphe (cf. [_seedDenseGraph]).
  final bool denseGraph;

  /// Compte qui reçoit la démo : le vrai compte connecté, ou l'utilisateur
  /// fictif du mode `DEV_BYPASS_AUTH`.
  late final String _user = read(currentUserIdProvider) ?? AppConfig.devUserId;
  final DateTime _now = DateTime.now();

  DateTime _daysAgo(int days, {int hour = 10}) {
    final day = _now.subtract(Duration(days: days));
    return DateTime(day.year, day.month, day.day, hour);
  }

  DateTime _inDays(int days) => _now.add(Duration(days: days));

  Future<void> run() async {
    final notes = await _seedNotes();
    await _seedLinks(notes);
    final folders = await _seedFolders(notes);
    if (denseGraph) await _seedDenseGraph();
    await _seedTasks();
    await _seedHabits();
    await _seedPomodoro();
    await _seedFlashcards(notes);
    await _fileCards(folders);
    await _seedMetacognition(notes);
    await _seedPlanning(notes);
    debugPrint('Démo : données chargées.');
  }

  // ── Fiches ───────────────────────────────────────────────────────────────

  Future<Map<String, Note>> _seedNotes() async {
    final repository = read(noteRepositoryProvider)!;
    final created = <String, Note>{};

    Future<void> note(
      String key, {
      required String title,
      required String subject,
      required List<String> tags,
      required List<(NoteBlockType, String, bool)> blocks,
      int importance = 1,
      bool favorite = false,
    }) async {
      final draft = await repository.create(title: title, subject: subject);
      final full = draft.copyWith(
        tags: tags,
        importance: importance,
        isFavorite: favorite,
        blocks: [
          for (var i = 0; i < blocks.length; i++)
            NoteBlock(
              id: LocalFirstNoteRepository.newId(),
              noteId: draft.id,
              type: blocks[i].$1,
              content: blocks[i].$2,
              isChecked: blocks[i].$3,
              position: i,
            ),
        ],
      );
      await repository.save(full);
      created[key] = full;
    }

    const h = NoteBlockType.heading;
    const p = NoteBlockType.paragraph;
    const b = NoteBlockType.bulleted;
    const t = NoteBlockType.todo;
    const q = NoteBlockType.quote;
    const c = NoteBlockType.code;

    await note('derivees',
        title: 'Chapitre 2 – Dérivées',
        subject: 'Maths',
        tags: ['analyse', 'exam'],
        importance: 3,
        favorite: true,
        blocks: [
          (h, 'Définition', false),
          (
            p,
            'f est dérivable en a si le taux d\'accroissement admet une limite finie quand h → 0.',
            false
          ),
          (h, 'Formules à connaître', false),
          (b, '(u·v)\' = u\'v + uv\'', false),
          (b, '(u/v)\' = (u\'v − uv\') / v²', false),
          (b, '(f∘g)\' = g\' × f\'∘g', false),
          (h, 'À faire', false),
          (t, 'Refaire les exercices 12 à 18', true),
          (t, 'Fiche réflexe sur la dérivée composée', false),
        ]);

    await note('limites',
        title: 'Chapitre 1 – Limites et continuité',
        subject: 'Maths',
        tags: ['analyse'],
        importance: 2,
        blocks: [
          (h, 'Idée clé', false),
          (
            p,
            'Une limite décrit le comportement d\'une fonction au voisinage d\'un point.',
            false
          ),
          (b, 'Théorème des gendarmes', false),
          (b, 'Théorème des valeurs intermédiaires', false),
          (
            q,
            'Toujours vérifier la continuité avant d\'appliquer le TVI.',
            false
          ),
        ]);

    await note('integrales',
        title: 'Chapitre 3 – Intégrales',
        subject: 'Maths',
        tags: ['analyse', 'exam'],
        importance: 3,
        blocks: [
          (h, 'Lien avec les dérivées', false),
          (
            p,
            'L\'intégrale est l\'opération inverse de la dérivation (primitive).',
            false
          ),
          (b, 'Intégration par parties : ∫u\'v = [uv] − ∫uv\'', false),
          (b, 'Changement de variable', false),
          (t, 'Apprendre le tableau des primitives usuelles', false),
        ]);

    await note('thermo',
        title: 'Thermodynamique – Premier principe',
        subject: 'Physique',
        tags: ['énergie', 'exam'],
        importance: 3,
        blocks: [
          (h, 'Énoncé', false),
          (q, 'ΔU = W + Q', false),
          (
            p,
            'L\'énergie interne d\'un système fermé varie du travail et de la chaleur échangés.',
            false
          ),
          (b, 'Transformation isochore : W = 0', false),
          (b, 'Transformation adiabatique : Q = 0', false),
          (t, 'Exercices du TD 4', false),
        ]);

    await note('meca',
        title: 'Mécanique – Lois de Newton',
        subject: 'Physique',
        tags: ['mécanique'],
        importance: 2,
        blocks: [
          (h, 'Les trois lois', false),
          (b, 'Principe d\'inertie', false),
          (b, 'ΣF = m·a', false),
          (b, 'Actions réciproques', false),
          (
            p,
            'La dérivée de la vitesse donne l\'accélération : voir le chapitre sur les dérivées.',
            false
          ),
        ]);

    await note('python',
        title: 'Python – Boucles et fonctions',
        subject: 'Informatique',
        tags: [
          'code'
        ],
        blocks: [
          (h, 'Boucle for', false),
          (c, 'for i in range(10):\n    print(i ** 2)', false),
          (h, 'Fonction', false),
          (
            c,
            'def derivee(f, x, h=1e-6):\n    return (f(x + h) - f(x)) / h',
            false
          ),
          (t, 'Coder la méthode des rectangles', false),
        ]);

    await note('memoire',
        title: 'Méthode – Courbe de l\'oubli',
        subject: 'Méthodologie',
        tags: ['métacognition'],
        favorite: true,
        blocks: [
          (h, 'Principe', false),
          (
            p,
            'Sans révision, on oublie l\'essentiel en quelques jours. Les révisions espacées (J+1, J+3, J+7…) aplatissent la courbe.',
            false
          ),
          (b, 'Rappel actif plutôt que relecture', false),
          (b, 'Alterner les matières (interleaving)', false),
          (q, 'Se tester, c\'est apprendre.', false),
        ]);

    await note('pomodoro',
        title: 'Méthode – Pomodoro et concentration',
        subject: 'Méthodologie',
        tags: [
          'focus'
        ],
        blocks: [
          (b, '25 min de travail, 5 min de pause', false),
          (b, 'Pause longue toutes les 4 sessions', false),
          (b, 'Téléphone dans une autre pièce', false),
        ]);

    return created;
  }

  Future<void> _seedLinks(Map<String, Note> notes) async {
    final repository = read(noteLinkRepositoryProvider)!;

    Future<void> link(String from, String to, NoteLinkType type) =>
        repository.link(
          sourceId: notes[from]!.id,
          targetId: notes[to]!.id,
          type: type,
        );

    await link('limites', 'derivees', NoteLinkType.prerequisite);
    await link('derivees', 'integrales', NoteLinkType.prerequisite);
    await link('derivees', 'meca', NoteLinkType.related);
    await link('integrales', 'thermo', NoteLinkType.related);
    await link('meca', 'thermo', NoteLinkType.related);
    await link('python', 'derivees', NoteLinkType.related);
    await link('python', 'integrales', NoteLinkType.toReview);
    await link('memoire', 'derivees', NoteLinkType.seen);
    await link('memoire', 'pomodoro', NoteLinkType.related);
    await link('pomodoro', 'thermo', NoteLinkType.seen);
  }

  /// Actif par défaut (désactivable : `--dart-define=DEV_DENSE_GRAPH=false`) :
  /// ajoute le carnet dense des tests du
  /// graphe (cf. `test/features/graph/graph_page_test.dart`), pour éprouver la
  /// carte à l'œil sur un vrai volume.
  static const bool _denseGraph =
      bool.fromEnvironment('DEV_DENSE_GRAPH', defaultValue: true);

  /// 60 fiches sur 4 sujets, chacune reliée à ses deux suivantes et à un pivot
  /// tous les 5, tous types de lien confondus ; les 4 dernières restent
  /// isolées.
  Future<void> _seedDenseGraph({int count = 60, int isolated = 4}) async {
    final notes = read(noteRepositoryProvider)!;
    final links = read(noteLinkRepositoryProvider)!;
    const subjects = ['Maths', 'Physique', 'Info', 'Méthodo'];
    const types = NoteLinkType.values;

    final ids = <String>[];
    for (var i = 0; i < count; i++) {
      final draft = await notes.create(
        title: 'Fiche n$i',
        subject: subjects[i % subjects.length],
      );
      await notes.save(draft.copyWith(tags: ['t${i % 7}']));
      ids.add(draft.id);
    }

    final connected = count - isolated;
    for (var i = 0; i < connected; i++) {
      if (i + 1 < connected) {
        await links.link(
            sourceId: ids[i],
            targetId: ids[i + 1],
            type: types[i % types.length]);
      }
      if (i + 2 < connected) {
        await links.link(
            sourceId: ids[i],
            targetId: ids[i + 2],
            type: types[(i + 1) % types.length]);
      }
      if (i % 5 == 0 && i != 0) {
        await links.link(
            sourceId: ids[i], targetId: ids[0], type: NoteLinkType.related);
      }
    }
  }

  // ── Dossiers de l'explorateur ──────────────────────────────────────────

  /// Range les fiches dans une petite arborescence ; renvoie le dossier de
  /// chaque fiche, pour y ranger aussi ses cartes.
  Future<Map<String, String>> _seedFolders(Map<String, Note> notes) async {
    final repository = read(folderRepositoryProvider);
    if (repository == null) return const {};
    final maths = await repository.create('Mathématiques');
    final analyse = await repository.create('Analyse', parentId: maths.id);
    final physique = await repository.create('Physique');
    final info = await repository.create('Informatique');
    final methodes = await repository.create('Méthodes de travail');

    final placement = {
      'derivees': analyse.id,
      'limites': analyse.id,
      'integrales': analyse.id,
      'thermo': physique.id,
      'meca': physique.id,
      'python': info.id,
      'memoire': methodes.id,
      'pomodoro': methodes.id,
    };
    final byNoteId = <String, String>{};
    for (final MapEntry(key: key, value: folderId) in placement.entries) {
      final note = notes[key];
      if (note == null) continue;
      await repository.moveNote(note.id, folderId);
      byNoteId[note.id] = folderId;
    }
    return byNoteId;
  }

  /// Chaque carte rejoint le dossier de sa fiche d'origine.
  Future<void> _fileCards(Map<String, String> folderOfNote) async {
    final repository = read(folderRepositoryProvider);
    if (repository == null) return;
    final cards = await (db.select(db.localFlashcards)
          ..where((t) => t.userId.equals(_user)))
        .get();
    for (final card in cards) {
      final folderId = folderOfNote[card.noteId];
      if (folderId != null) await repository.moveCard(card.id, folderId);
    }
  }

  // ── Kanban / Eisenhower ──────────────────────────────────────────────────

  Future<void> _seedTasks() async {
    final repository = read(taskRepositoryProvider)!;
    final positions = <TaskStatus, int>{};

    Future<void> task(
      String title, {
      TaskStatus status = TaskStatus.todo,
      TaskPriority priority = TaskPriority.medium,
      bool urgent = false,
      bool important = false,
      int? dueInDays,
      String description = '',
    }) async {
      final position =
          positions.update(status, (v) => v + 1, ifAbsent: () => 0);
      await repository.create(Task(
        id: '',
        userId: _user,
        title: title,
        description: description,
        status: status,
        priority: priority,
        createdAt: _now,
        dueDate: dueInDays == null ? null : _inDays(dueInDays),
        isUrgent: urgent,
        isImportant: important,
        position: position,
      ));
    }

    await task('Réviser le chapitre 2 – Dérivées',
        priority: TaskPriority.high,
        urgent: true,
        important: true,
        dueInDays: 1,
        description: 'Partiel de maths vendredi.');
    await task('Finir le TD 4 de thermo',
        priority: TaskPriority.high,
        urgent: true,
        important: true,
        dueInDays: -1);
    await task('Préparer les fiches réflexes', important: true, dueInDays: 5);
    await task('Planifier les révisions du mois',
        important: true, dueInDays: 10);
    await task('Répondre au mail du prof de TP', urgent: true, dueInDays: 0);
    await task('Ranger le bureau', priority: TaskPriority.low);
    await task('Exercices d\'intégration par parties',
        status: TaskStatus.doing,
        priority: TaskPriority.high,
        important: true,
        dueInDays: 3);
    await task('Coder la méthode des rectangles en Python',
        status: TaskStatus.doing, important: true);
    await task('Relire le cours sur les limites',
        status: TaskStatus.done, important: true);
    await task('Imprimer les annales 2025',
        status: TaskStatus.done, urgent: true);
    await task('Flashcards Newton', status: TaskStatus.done);
  }

  // ── Habitudes ────────────────────────────────────────────────────────────

  Future<void> _seedHabits() async {
    final repository = read(habitRepositoryProvider)!;

    Future<void> habit(
      String name,
      HabitFrequency frequency, {
      required bool Function(int daysAgo) doneOn,
    }) async {
      final created = await repository.create(name: name, frequency: frequency);
      // Créée il y a 3 semaines, pour que constance et séries aient du sens.
      await (db.update(db.localHabits)..where((t) => t.id.equals(created.id)))
          .write(LocalHabitsCompanion(createdAt: Value(_daysAgo(21))));
      for (var day = 21; day >= 0; day--) {
        if (doneOn(day)) {
          await repository.setCompletion(created.id, _daysAgo(day), done: true);
        }
      }
    }

    await habit('Réviser 1 h (Deep Work)', HabitFrequency.daily,
        doneOn: (d) => d != 0 && d % 6 != 3);
    await habit('Sport', HabitFrequency.daily, doneOn: (d) => d % 2 == 0);
    await habit('Flashcards du jour', HabitFrequency.daily,
        doneOn: (d) => d <= 8);
    await habit('Coucher avant minuit', HabitFrequency.daily,
        doneOn: (d) => d % 3 != 0);
    await habit('Bilan de la semaine', HabitFrequency.weekly,
        doneOn: (d) => d % 7 == 1);
  }

  // ── Pomodoro ─────────────────────────────────────────────────────────────

  Future<void> _seedPomodoro() async {
    final repository = read(pomodoroRepositoryProvider)!;
    // Sessions par jour sur la semaine écoulée, aujourd'hui compris.
    const perDay = [3, 4, 2, 5, 0, 3, 6, 2];
    for (var day = 0; day < perDay.length; day++) {
      for (var i = 0; i < perDay[day]; i++) {
        final startedAt = day == 0
            ? _now.subtract(Duration(minutes: 30 * (i + 1)))
            : _daysAgo(day, hour: 9 + i);
        await repository.record(startedAt: startedAt, durationSeconds: 25 * 60);
      }
    }
  }

  // ── Flashcards ───────────────────────────────────────────────────────────

  Future<void> _seedFlashcards(Map<String, Note> notes) async {
    final repository = read(reviewRepositoryProvider)!;
    final cards = [
      ('derivees', 'Dérivée de u·v ?', 'u\'v + uv\''),
      ('derivees', 'Dérivée de f∘g ?', 'g\' × f\'∘g'),
      (
        'limites',
        'Que dit le théorème des gendarmes ?',
        'Si g ≤ f ≤ h et g, h tendent vers L, alors f tend vers L.'
      ),
      (
        'integrales',
        'Formule de l\'intégration par parties ?',
        '∫u\'v = [uv] − ∫uv\''
      ),
      ('thermo', 'Premier principe ?', 'ΔU = W + Q'),
      ('thermo', 'Que vaut Q pour une transformation adiabatique ?', 'Q = 0'),
      ('meca', 'Deuxième loi de Newton ?', 'ΣF = m·a'),
      (
        'memoire',
        'Pourquoi espacer les révisions ?',
        'Pour contrer la courbe de l\'oubli et consolider en mémoire à long terme.'
      ),
    ];
    for (final (noteKey, front, back) in cards) {
      await repository.createCard(
        front: front,
        back: back,
        noteId: notes[noteKey]!.id,
        deck: notes[noteKey]!.subject,
      );
    }
  }

  // ── Journal, erreurs ─────────────────────────────────────────────────────

  Future<void> _seedMetacognition(Map<String, Note> notes) async {
    final repository = read(metacognitionRepositoryProvider)!;

    final journal = [
      (
        6,
        3,
        3,
        7,
        'Les limites, enfin claires',
        'Refaire les exemples sans regarder',
        'Fatigue en fin de journée',
        'Attaquer les dérivées',
        'limites'
      ),
      (
        4,
        4,
        4,
        6,
        'Formules de dérivation',
        'Les flashcards le matin',
        'Notifications du téléphone',
        'Exercices 12 à 18',
        'derivees'
      ),
      (
        2,
        2,
        2,
        9,
        'Premier principe de la thermo',
        'Faire un schéma',
        'Stress du partiel, j\'ai bloqué',
        'Demander de l\'aide au TD',
        'thermo'
      ),
      (
        1,
        4,
        3,
        5,
        'Intégration par parties',
        'Expliquer à voix haute (Feynman)',
        'Rien de particulier',
        'Changement de variable',
        'integrales'
      ),
    ];
    for (final (
          days,
          mood,
          energy,
          rpe,
          learned,
          worked,
          blocked,
          next,
          noteKey
        ) in journal) {
      await repository.saveJournalEntry(JournalEntry(
        id: LocalFirstNoteRepository.newId(),
        userId: _user,
        mood: mood,
        energy: energy,
        rpe: rpe,
        createdAt: _daysAgo(days, hour: 19),
        noteId: notes[noteKey]!.id,
        whatLearned: learned,
        whatWorked: worked,
        whatBlocked: blocked,
        nextStep: next,
      ));
    }

    final errors = [
      (
        ErrorType.inattention,
        'Maths',
        'Oubli du signe moins en dérivant 1/x',
        'Dérivée de 1/x = −1/x²',
        'derivees'
      ),
      (
        ErrorType.comprehension,
        'Physique',
        'Confusion entre chaleur et température',
        'Q est un transfert, T une grandeur d\'état',
        'thermo'
      ),
      (
        ErrorType.method,
        'Maths',
        'Intégration par parties : mauvais choix de u',
        'Choisir u qui se simplifie en dérivant',
        'integrales'
      ),
      (
        ErrorType.instructions,
        'Physique',
        'Résultat donné en kJ au lieu de J',
        'Relire l\'unité demandée',
        'thermo'
      ),
      (
        ErrorType.memorisation,
        'Maths',
        'Formule de (u/v)\' oubliée',
        'Ajoutée aux flashcards',
        'derivees'
      ),
    ];
    for (var i = 0; i < errors.length; i++) {
      final (type, subject, description, correction, noteKey) = errors[i];
      await repository.saveError(ErrorLog(
        id: LocalFirstNoteRepository.newId(),
        userId: _user,
        description: description,
        errorType: type,
        createdAt: _daysAgo(i + 1, hour: 16),
        noteId: notes[noteKey]!.id,
        subject: subject,
        correction: correction,
      ));
    }
  }

  // ── Objectifs SMART et Gantt ─────────────────────────────────────────────

  Future<void> _seedPlanning(Map<String, Note> notes) async {
    final repository = read(planningRepositoryProvider)!;

    final goal = StudyGoal(
      id: newPlanningId(),
      userId: _user,
      title: 'Avoir 14 au partiel d\'analyse',
      subject: 'Maths',
      metricLabel: 'chapitres maîtrisés',
      targetValue: 3,
      currentValue: 1,
      achievablePlan: '1 h par jour + 2 annales par semaine',
      relevance: 'Valider le semestre pour intégrer l\'école visée',
      deadline: _inDays(14),
      createdAt: _daysAgo(10),
    );
    await repository.saveGoal(goal);

    await repository.saveGoal(StudyGoal(
      id: newPlanningId(),
      userId: _user,
      title: 'Faire 150 flashcards',
      subject: 'Toutes matières',
      metricLabel: 'cartes',
      targetValue: 150,
      currentValue: 64,
      deadline: _inDays(30),
      createdAt: _daysAgo(5),
    ));

    final limites = PlanItem(
      id: newPlanningId(),
      userId: _user,
      goalId: goal.id,
      title: 'Limites',
      subject: 'Maths',
      startDate: _daysAgo(9),
      endDate: _daysAgo(5),
      progress: 1,
      createdAt: _daysAgo(10),
    );
    final derivees = PlanItem(
      id: newPlanningId(),
      userId: _user,
      goalId: goal.id,
      title: 'Dérivées',
      subject: 'Maths',
      startDate: _daysAgo(4),
      endDate: _inDays(2),
      progress: 0.6,
      dependsOnId: limites.id,
      createdAt: _daysAgo(10),
    );
    final integrales = PlanItem(
      id: newPlanningId(),
      userId: _user,
      goalId: goal.id,
      title: 'Intégrales',
      subject: 'Maths',
      startDate: _inDays(3),
      endDate: _inDays(10),
      dependsOnId: derivees.id,
      createdAt: _daysAgo(10),
    );
    final partiel = PlanItem(
      id: newPlanningId(),
      userId: _user,
      goalId: goal.id,
      title: 'Partiel d\'analyse',
      subject: 'Maths',
      startDate: _inDays(14),
      endDate: _inDays(14),
      isMilestone: true,
      dependsOnId: integrales.id,
      createdAt: _daysAgo(10),
    );
    final thermo = PlanItem(
      id: newPlanningId(),
      userId: _user,
      title: 'Thermodynamique',
      subject: 'Physique',
      startDate: _daysAgo(2),
      endDate: _inDays(6),
      progress: 0.3,
      createdAt: _daysAgo(3),
    );
    await repository
        .savePlanItems([limites, derivees, integrales, partiel, thermo]);
  }
}
