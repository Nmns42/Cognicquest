import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Base locale SQLite (Drift) — arbitrage tranché en faveur de Drift/SQLite.
///
/// Elle est la **source de vérité locale** de la base de connaissances : les
/// fiches se lisent et s'écrivent hors ligne, et la synchronisation avec
/// Supabase se fait ensuite via la file [SyncQueueEntries].
///
/// Sur le web, Drift s'appuie sur `web/sqlite3.wasm` + `web/drift_worker.js`
/// (livrés dans le dépôt) et choisit tout seul OPFS ou IndexedDB selon ce que
/// le navigateur propose.

/// Fiches de connaissance — « Création de pages ou fiches (ex : Chapitre 3 –
/// Mécanique Quantique) » (CdC).
class LocalNotes extends Table {
  /// UUID généré côté client : une fiche créée hors ligne a déjà son identité
  /// définitive, ce qui évite tout remapping à la synchronisation.
  TextColumn get id => text()();

  TextColumn get userId => text()();
  TextColumn get title => text().withLength(min: 0, max: 300)();
  TextColumn get content => text().withDefault(const Constant(''))();

  /// Matière / sujet, pour le filtre « par sujet » du CdC.
  TextColumn get subject => text().nullable()();

  /// Tags sérialisés en JSON. Le nombre de tags par fiche est petit ; une table
  /// de jointure coûterait plus qu'elle ne rapporte à cette échelle.
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  IntColumn get importance => integer().withDefault(const Constant(1))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Marque de suppression logique : une fiche supprimée hors ligne doit
  /// pouvoir être propagée au serveur, donc elle ne peut pas disparaître
  /// localement avant d'avoir été synchronisée.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// `false` tant que la version locale n'a pas été poussée vers Supabase.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Blocs composant une fiche — « Blocs de texte, listes, cases à cocher,
/// citations, fichiers, images, liens » (CdC).
class LocalNoteBlocks extends Table {
  TextColumn get id => text()();
  /// `onDelete: cascade` est indispensable : sans lui, Drift génère une
  /// référence sans action et la suppression d'une fiche laisse ses blocs
  /// orphelins en base.
  TextColumn get noteId =>
      text().references(LocalNotes, #id, onDelete: KeyAction.cascade)();

  /// `paragraph` | `heading` | `bulleted` | `todo` | `quote` | `code` |
  /// `image` | `link` | `divider`
  TextColumn get type => text()();
  TextColumn get content => text().withDefault(const Constant(''))();

  /// `true` pour un bloc `todo` coché.
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();

  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Liens entre fiches — « Graphe de liaison des connaissances » (CdC).
///
/// Une arête est orientée et typée : « vu », « à revoir », « lié à ».
/// La contrainte d'unicité empêche de créer deux fois la même arête, ce que
/// l'interface ne peut pas garantir seule en mode hors ligne.
class LocalNoteLinks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  TextColumn get sourceId =>
      text().references(LocalNotes, #id, onDelete: KeyAction.cascade)();
  TextColumn get targetId =>
      text().references(LocalNotes, #id, onDelete: KeyAction.cascade)();

  /// `related` | `seen` | `to_review` | `prerequisite`
  TextColumn get type => text().withDefault(const Constant('related'))();
  TextColumn get label => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {sourceId, targetId, type},
      ];
}

/// Cartes de révision — « Quiz/flashcard sur le même style que Tutorium et
/// Anki » (CdC).
///
/// L'état de répétition espacée vit sur la même ligne que la carte : une carte
/// n'a qu'un seul planning, une table séparée n'apporterait qu'une jointure.
class LocalFlashcards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// Fiche d'origine. `setNull` et non `cascade` : supprimer une fiche ne doit
  /// pas détruire les cartes déjà mémorisées, ni l'historique de révision.
  TextColumn get noteId =>
      text().nullable().references(LocalNotes, #id, onDelete: KeyAction.setNull)();

  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get deck => text().nullable()();

  // ── État de répétition espacée ─────────────────────────────────────────
  /// Rang atteint dans l'échelle des J (J+1, J+3, J+7…).
  IntColumn get step => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Historique des révisions, pour les statistiques de progression.
class LocalReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get cardId =>
      text().references(LocalFlashcards, #id, onDelete: KeyAction.cascade)();

  /// `again` | `hard` | `good` | `easy`
  TextColumn get grade => text()();
  IntColumn get intervalDays => integer()();
  DateTimeColumn get reviewedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Lecture guidée SQ3R — « outil de lecture guidée avec étapes
/// interactives » (CdC). Une session par fiche.
class LocalSq3rSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get noteId =>
      text().references(LocalNotes, #id, onDelete: KeyAction.cascade)();

  /// 0 = Survey, 1 = Question, 2 = Read, 3 = Recite, 4 = Review.
  IntColumn get currentStep => integer().withDefault(const Constant(0))();
  TextColumn get surveyNotes => text().withDefault(const Constant(''))();
  /// Questions posées avant lecture, sérialisées en JSON.
  TextColumn get questions => text().withDefault(const Constant('[]'))();
  TextColumn get reciteNotes => text().withDefault(const Constant(''))();
  TextColumn get reviewNotes => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  /// Une seule session SQ3R par fiche : on reprend la lecture en cours plutôt
  /// que d'en empiler des copies.
  @override
  List<Set<Column>> get uniqueKeys => [
        {noteId},
      ];
}

/// Auto-explications — mode « Explique-moi » (CdC) : reformuler avec ses
/// propres mots, principe de la technique Feynman.
class LocalExplanations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get noteId =>
      text().references(LocalNotes, #id, onDelete: KeyAction.cascade)();

  TextColumn get content => text()();
  /// Confiance ressentie, de 1 à 5 : l'auto-évaluation fait partie de la
  /// démarche métacognitive.
  IntColumn get confidence => integer().withDefault(const Constant(3))();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Journal métacognitif — « bilan de fin de session avec questions guidées »
/// (CdC), fusionné avec le tracker d'émotions et le RPE.
///
/// Les trois vivent sur la même ligne à dessein : le CdC veut « comprendre
/// comment une émotion impacte la mémorisation ». Séparer humeur, effort et
/// bilan en trois tables rendrait la corrélation coûteuse à calculer.
class LocalJournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// Fiche ou notion travaillée, si la session en visait une.
  TextColumn get noteId =>
      text().nullable().references(LocalNotes, #id, onDelete: KeyAction.setNull)();

  /// Humeur ressentie, de 1 (très bas) à 5 (très bien).
  IntColumn get mood => integer().withDefault(const Constant(3))();

  /// Énergie disponible, de 1 à 5.
  IntColumn get energy => integer().withDefault(const Constant(3))();

  /// RPE — perception de l'effort, de 1 à 10. Exigence explicite du CdC :
  /// « tracker le RPE ⇒ perception de la difficulté ».
  IntColumn get rpe => integer().withDefault(const Constant(5))();

  // Questions guidées du bilan.
  TextColumn get whatLearned => text().withDefault(const Constant(''))();
  TextColumn get whatWorked => text().withDefault(const Constant(''))();
  TextColumn get whatBlocked => text().withDefault(const Constant(''))();
  TextColumn get nextStep => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recadrage cognitif — « identifier et transformer les pensées bloquantes
/// (ex : "Je suis nul en maths") en objectifs de croissance » (CdC).
class LocalReframes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  TextColumn get limitingThought => text()();
  /// Distorsion repérée : `all_or_nothing`, `overgeneralisation`…
  TextColumn get distortion => text().nullable()();
  TextColumn get evidenceAgainst => text().withDefault(const Constant(''))();
  TextColumn get reframedThought => text().withDefault(const Constant(''))();
  TextColumn get growthGoal => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Chaîne des 5 Pourquoi, pour remonter d'un blocage à sa cause réelle.
///
/// Sa sortie alimente l'exigence du CdC : « un module pour identifier si le
/// frein est cognitif, émotionnel, sensoriel ou environnemental ».
class LocalWhyChains extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  TextColumn get problem => text()();
  /// Les réponses successives, sérialisées en JSON (jusqu'à 5).
  TextColumn get answers => text().withDefault(const Constant('[]'))();
  TextColumn get rootCause => text().withDefault(const Constant(''))();
  /// `cognitive` | `emotional` | `sensory` | `environmental`
  TextColumn get blockerType => text().nullable()();
  TextColumn get actionPlan => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Analyse des erreurs — « regroupe les types d'erreurs commises par l'élève
/// (erreurs d'inattention vs erreurs de compréhension) » (CdC).
class LocalErrorLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get noteId =>
      text().nullable().references(LocalNotes, #id, onDelete: KeyAction.setNull)();

  TextColumn get subject => text().nullable()();
  TextColumn get description => text()();
  /// `inattention` | `comprehension` | `method` | `memorisation` | `instructions`
  TextColumn get errorType => text()();
  TextColumn get correction => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Profil d'apprentissage issu de l'onboarding de profilage.
///
/// Une seule ligne par utilisateur : c'est son « mode d'emploi », pas un
/// historique.
class LocalLearningProfiles extends Table {
  TextColumn get userId => text()();

  /// Réponses brutes au questionnaire, sérialisées en JSON.
  TextColumn get answers => text().withDefault(const Constant('{}'))();
  /// `global` | `sequential`
  TextColumn get processingStyle => text().nullable()();
  /// `visual` | `auditory` | `kinesthetic` | `reading`
  TextColumn get preferredChannel => text().nullable()();

  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {userId};
}

/// Objectif SMART — « définir des objectifs précis, atteignables et
/// mesurables » (CdC), décliné sur les cinq critères.
class LocalStudyGoals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// S — l'objectif énoncé précisément.
  TextColumn get title => text()();
  TextColumn get subject => text().nullable()();

  /// M — nom de l'unité mesurée (« chapitres », « exercices »), et cibles.
  TextColumn get metricLabel => text().withDefault(const Constant(''))();
  RealColumn get targetValue => real().withDefault(const Constant(0))();
  RealColumn get currentValue => real().withDefault(const Constant(0))();

  /// A — ce qui rend l'objectif atteignable (moyens, disponibilité).
  TextColumn get achievablePlan => text().withDefault(const Constant(''))();

  /// R — pourquoi il compte. Répond au « générateur de pourquoi » du CdC.
  TextColumn get relevance => text().withDefault(const Constant(''))();

  /// T — l'échéance.
  DateTimeColumn get deadline => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Barre du diagramme de Gantt — « vue chronologique horizontale avec barres
/// ajustables », « affichage des dépendances (tâche A → tâche B) » (CdC).
class LocalPlanItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  TextColumn get goalId =>
      text().nullable().references(LocalStudyGoals, #id, onDelete: KeyAction.setNull)();
  /// Lien avec le Kanban — « lien direct avec les cartes Trello et tâches ».
  TextColumn get taskId => text().nullable()();

  TextColumn get title => text()();
  TextColumn get subject => text().nullable()();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();

  /// Avancement de 0 à 1.
  RealColumn get progress => real().withDefault(const Constant(0))();

  /// Jalon : une date sans durée (examen, rendu).
  BoolColumn get isMilestone => boolean().withDefault(const Constant(false))();

  /// Élément qui doit être terminé avant celui-ci.
  TextColumn get dependsOnId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mesure de vitesse — « estimation/pronostic de la vitesse de
/// lecture/rédaction/rétention/compréhension » (CdC).
class LocalSpeedSamples extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// `reading` | `writing` | `memorising` | `exercises`
  TextColumn get activity => text()();
  TextColumn get subject => text().nullable()();

  /// Quantité traitée, dans l'unité de l'activité (pages, mots, cartes…).
  RealColumn get units => real()();
  IntColumn get durationSeconds => integer()();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Chapitre à réviser, avec de quoi calculer sa rentabilité.
///
/// CdC : « viser là où il y a le plus de points en examen, comparaison note
/// actuelle → note atteignable, longueur du cours, difficulté ⇒ ordre de
/// révision ».
class LocalExamTargets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get noteId =>
      text().nullable().references(LocalNotes, #id, onDelete: KeyAction.setNull)();

  TextColumn get title => text()();
  TextColumn get subject => text().nullable()();

  /// Points que ce chapitre pèse dans l'examen.
  RealColumn get examWeight => real().withDefault(const Constant(0))();
  /// Note actuelle estimée, sur 20.
  RealColumn get currentGrade => real().withDefault(const Constant(0))();
  /// Note que l'on pense pouvoir atteindre, sur 20.
  RealColumn get reachableGrade => real().withDefault(const Constant(20))();
  /// Longueur du cours, en heures de travail estimées.
  RealColumn get lengthHours => real().withDefault(const Constant(1))();
  /// Difficulté ressentie, de 1 à 5.
  IntColumn get difficulty => integer().withDefault(const Constant(3))();

  DateTimeColumn get examDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tâche du Kanban / de la matrice d'Eisenhower.
///
/// Rapatriée en local au Lot 10 : le CdC exige un « mode offline avec
/// synchronisation automatique dès qu'internet est disponible », et la to-do
/// était jusque-là inutilisable sans réseau.
class LocalTasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  /// `todo` | `doing` | `done`
  TextColumn get status => text().withDefault(const Constant('todo'))();
  /// `low` | `medium` | `high`
  TextColumn get priority => text().withDefault(const Constant('medium'))();

  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isUrgent => boolean().withDefault(const Constant(false))();
  BoolColumn get isImportant => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Habitude suivie — « Habit Tracker » (CdC).
class LocalHabits extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  TextColumn get name => text()();
  /// `daily` | `weekly` | `monthly`
  TextColumn get frequency => text().withDefault(const Constant('daily'))();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Jour coché d'une habitude.
///
/// La clé (habitude, jour) reprend la contrainte d'unicité de `habit_logs`
/// côté Supabase : un double tap hors ligne ne peut pas compter deux fois.
class LocalHabitLogs extends Table {
  TextColumn get habitId =>
      text().references(LocalHabits, #id, onDelete: KeyAction.cascade)();

  /// Jour local au format `yyyy-MM-dd` (cf. `Habit.toDateKey`).
  TextColumn get date => text()();

  @override
  Set<Column> get primaryKey => {habitId, date};
}

/// Session Pomodoro terminée — « sessions terminées, temps total d'étude »
/// (CdC).
class LocalPomodoroSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationSeconds => integer()();

  /// Volontairement sans clé étrangère locale : la tâche peut n'exister que
  /// sur un autre appareil, pas encore rapatriée.
  TextColumn get taskId => text().nullable()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// File de synchronisation : chaque écriture locale y dépose une intention.
///
/// C'est la pièce qui manquait depuis le Lot 2 pour un vrai mode hors ligne.
/// Elle est générique (table + identifiant + opération) afin que les Lots
/// suivants — et la reprise des tâches/habitudes — s'y branchent sans
/// nouvelle structure.
class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityTable => text()();
  TextColumn get entityId => text()();

  /// `upsert` | `delete`
  TextColumn get operation => text()();

  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(tables: [
  LocalNotes,
  LocalNoteBlocks,
  LocalNoteLinks,
  LocalFlashcards,
  LocalReviewLogs,
  LocalSq3rSessions,
  LocalExplanations,
  LocalJournalEntries,
  LocalReframes,
  LocalWhyChains,
  LocalErrorLogs,
  LocalLearningProfiles,
  LocalStudyGoals,
  LocalPlanItems,
  LocalSpeedSamples,
  LocalExamTargets,
  LocalTasks,
  LocalHabits,
  LocalHabitLogs,
  LocalPomodoroSessions,
  SyncQueueEntries,
])
class AppDatabase extends _$AppDatabase {
  /// [executor] n'est fourni que par les tests, qui injectent une base en
  /// mémoire. Le code applicatif laisse [_open] choisir selon la plateforme.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// v1 : fiches + blocs + file de synchronisation (Lot 4).
  /// v2 : liens entre fiches, pour le graphe de connaissances (Lot 5).
  /// v3 : cartes de révision, historique, SQ3R et auto-explications (Lot 6).
  /// v4 : journal métacognitif, recadrage, 5 Pourquoi, erreurs, profil (Lot 7).
  /// v5 : objectifs SMART, Gantt, vitesse de travail, cibles d'examen (Lot 8).
  /// v6 : tâches, habitudes et sessions Pomodoro hors ligne (Lot 10).
  @override
  int get schemaVersion => 6;

  /// Efface toutes les données locales, file de synchronisation comprise.
  ///
  /// Appelé à la déconnexion explicite : sans ça, les fiches, le journal et
  /// les tâches du compte précédent restaient lisibles sur l'appareil.
  /// `defer_foreign_keys` reporte la vérification des clés étrangères à la fin
  /// de la transaction : l'ordre de suppression des tables n'importe plus.
  Future<void> wipeAll() => transaction(() async {
        await customStatement('PRAGMA defer_foreign_keys = ON');
        for (final table in allTables) {
          await delete(table).go();
        }
      });

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // Sans cette migration, une base déjà installée perdrait ses fiches
          // au moment d'accueillir la nouvelle table.
          if (from < 2) {
            await m.createTable(localNoteLinks);
          }
          if (from < 3) {
            await m.createTable(localFlashcards);
            await m.createTable(localReviewLogs);
            await m.createTable(localSq3rSessions);
            await m.createTable(localExplanations);
          }
          if (from < 4) {
            await m.createTable(localJournalEntries);
            await m.createTable(localReframes);
            await m.createTable(localWhyChains);
            await m.createTable(localErrorLogs);
            await m.createTable(localLearningProfiles);
          }
          if (from < 5) {
            await m.createTable(localStudyGoals);
            await m.createTable(localPlanItems);
            await m.createTable(localSpeedSamples);
            await m.createTable(localExamTargets);
          }
          if (from < 6) {
            await m.createTable(localTasks);
            await m.createTable(localHabits);
            await m.createTable(localHabitLogs);
            await m.createTable(localPomodoroSessions);
          }
        },
        beforeOpen: (details) async {
          // Indispensable : sans ça SQLite ignore silencieusement les
          // contraintes de clé étrangère, et des blocs orphelins
          // s'accumuleraient après suppression d'une fiche.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'cognicquest',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty && kDebugMode) {
            debugPrint(
              'Drift web : implémentation ${result.chosenImplementation} '
              '(fonctions manquantes : ${result.missingFeatures})',
            );
          }
        },
      ),
    );
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
