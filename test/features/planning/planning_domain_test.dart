import 'package:cognicquest/features/planning/domain/adaptive_schedule.dart';
import 'package:cognicquest/features/planning/domain/gantt_timeline.dart';
import 'package:cognicquest/features/planning/domain/revision_priority.dart';
import 'package:cognicquest/features/planning/domain/study_speed.dart';
import 'package:cognicquest/shared/models/planning_model.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 4, 10);

ExamTarget target({
  required String id,
  double weight = 10,
  double current = 0,
  double reachable = 20,
  double length = 2,
  int difficulty = 3,
  int? examInDays,
}) =>
    ExamTarget(
      id: id,
      userId: 'u1',
      title: 'Chapitre $id',
      examWeight: weight,
      currentGrade: current,
      reachableGrade: reachable,
      lengthHours: length,
      difficulty: difficulty,
      examDate: examInDays == null
          ? null
          : DateTime.now().add(Duration(days: examInDays)),
      createdAt: DateTime.now(),
    );

PlanItem item({
  required String id,
  int startOffset = 0,
  int days = 3,
  String? dependsOn,
  bool milestone = false,
  double progress = 0,
}) =>
    PlanItem(
      id: id,
      userId: 'u1',
      title: 'Item $id',
      startDate: _today.add(Duration(days: startOffset)),
      endDate: _today.add(Duration(days: startOffset + days - 1)),
      dependsOnId: dependsOn,
      isMilestone: milestone,
      progress: progress,
      createdAt: _today,
    );

SpeedSample sample({
  StudyActivity activity = StudyActivity.reading,
  double units = 10,
  int seconds = 3600,
  String? subject,
  int daysAgo = 0,
}) =>
    SpeedSample(
      id: 's$units-$seconds-$daysAgo',
      userId: 'u1',
      activity: activity,
      units: units,
      durationSeconds: seconds,
      subject: subject,
      createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
    );

void main() {
  group('StudyGoal — critères SMART', () {
    StudyGoal goal({
      String title = 'Terminer le chapitre 3 de mécanique',
      String metric = '',
      double target = 0,
      String achievable = '',
      String relevance = '',
      DateTime? deadline,
      double current = 0,
    }) =>
        StudyGoal(
          id: 'g1',
          userId: 'u1',
          title: title,
          metricLabel: metric,
          targetValue: target,
          currentValue: current,
          achievablePlan: achievable,
          relevance: relevance,
          deadline: deadline,
          createdAt: DateTime.now(),
        );

    test('repère les critères manquants', () {
      final incomplete = goal();
      expect(incomplete.satisfiedCriteria, {SmartCriterion.specific});
      expect(incomplete.missingCriteria, hasLength(4));
      expect(incomplete.isFullySmart, isFalse);
    });

    test('valide un objectif complet', () {
      final complete = goal(
        metric: 'exercices',
        target: 20,
        achievable: '2 par jour',
        relevance: 'Partiel de mai',
        deadline: DateTime.now().add(const Duration(days: 10)),
      );

      expect(complete.isFullySmart, isTrue);
      expect(complete.missingCriteria, isEmpty);
    });

    test('un titre trop court n\'est pas spécifique', () {
      expect(goal(title: 'Maths').satisfiedCriteria,
          isNot(contains(SmartCriterion.specific)));
    });

    test('une mesure sans cible chiffrée ne compte pas', () {
      expect(goal(metric: 'exercices').satisfiedCriteria,
          isNot(contains(SmartCriterion.measurable)));
    });

    test('l\'avancement vaut 0 sans cible, plutôt qu\'une valeur inventée', () {
      expect(goal(current: 5).progress, 0);
      expect(goal(metric: 'x', target: 10, current: 5).progress, 0.5);
    });

    test('l\'avancement est plafonné à 1', () {
      expect(goal(metric: 'x', target: 10, current: 25).progress, 1);
    });
  });

  group('StudyGoal — rythme requis', () {
    StudyGoal withDeadline(int days, {double target = 10, double current = 0}) =>
        StudyGoal(
          id: 'g1',
          userId: 'u1',
          title: 'Objectif mesurable précis',
          metricLabel: 'chapitres',
          targetValue: target,
          currentValue: current,
          deadline: DateTime.now().add(Duration(days: days)),
          createdAt: DateTime.now(),
        );

    test('répartit le reste sur les jours restants', () {
      expect(withDeadline(5, target: 10).requiredPacePerDay, 2);
      expect(withDeadline(4, target: 10, current: 2).requiredPacePerDay, 2);
    });

    test('vaut 0 quand la cible est atteinte', () {
      expect(withDeadline(5, target: 10, current: 10).requiredPacePerDay, 0);
    });

    test('n\'a pas de sens sans cible ni échéance', () {
      final noDeadline = StudyGoal(
        id: 'g',
        userId: 'u',
        title: 'Sans échéance du tout',
        metricLabel: 'x',
        targetValue: 5,
        createdAt: DateTime.now(),
      );
      expect(noDeadline.requiredPacePerDay, isNull);
    });

    test('renvoie tout le reste quand l\'échéance est dépassée', () {
      final late = StudyGoal(
        id: 'g',
        userId: 'u',
        title: 'Objectif en retard précis',
        metricLabel: 'x',
        targetValue: 10,
        currentValue: 3,
        deadline: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now(),
      );
      expect(late.requiredPacePerDay, 7);
      expect(late.isOverdue, isTrue);
    });
  });

  group('RevisionPriority — rentabilité', () {
    test('classe en tête le meilleur rapport points / heures', () {
      final ranked = RevisionPriority.rank([
        // 10 pts pour 10 h.
        target(id: 'long', weight: 10, length: 10),
        // 10 pts pour 2 h → bien plus rentable.
        target(id: 'court', weight: 10, length: 2),
      ]);

      expect(ranked.first.target.id, 'court');
    });

    test('les points récupérables tiennent compte de la note actuelle', () {
      // Déjà à 15/20 : il ne reste qu'un quart des points à prendre.
      final almostDone = target(id: 'a', weight: 20, current: 15);
      expect(almostDone.gainablePoints, closeTo(5, 0.01));

      final fromScratch = target(id: 'b', weight: 20, current: 0);
      expect(fromScratch.gainablePoints, closeTo(20, 0.01));
    });

    test('la difficulté alourdit le coût estimé', () {
      expect(target(id: 'a', length: 10, difficulty: 3).estimatedCost, 10);
      expect(target(id: 'b', length: 10, difficulty: 5).estimatedCost,
          closeTo(14, 0.01));
      expect(target(id: 'c', length: 10, difficulty: 1).estimatedCost,
          closeTo(6, 0.01));
    });

    test('un examen proche remonte le chapitre', () {
      final ranked = RevisionPriority.rank([
        target(id: 'lointain', weight: 12, length: 2, examInDays: 90),
        target(id: 'proche', weight: 10, length: 2, examInDays: 2),
      ]);

      // Sans urgence, « lointain » gagnerait (12 pts contre 10).
      expect(ranked.first.target.id, 'proche');
    });

    test('l\'urgence plafonne au-delà de l\'horizon', () {
      expect(RevisionPriority.urgencyFor(target(id: 'a', examInDays: 90)), 1);
      expect(RevisionPriority.urgencyFor(target(id: 'b', examInDays: 21)), 1);
      expect(RevisionPriority.urgencyFor(target(id: 'c', examInDays: 0)), 2);
    });

    test('écarte les chapitres sans gain possible', () {
      final ranked = RevisionPriority.rank([
        target(id: 'fini', weight: 10, current: 20, reachable: 20),
        target(id: 'utile', weight: 10, current: 5),
      ]);

      expect(ranked.map((r) => r.target.id), ['utile']);
    });

    test('écarte les examens déjà passés', () {
      final ranked = RevisionPriority.rank([
        target(id: 'passe', weight: 10, examInDays: -3),
      ]);
      expect(ranked, isEmpty);
    });

    test('explique pourquoi un chapitre est écarté', () {
      final excluded = RevisionPriority.excluded([
        target(id: 'passe', weight: 10, examInDays: -3),
        target(id: 'fini', weight: 10, current: 20),
        target(id: 'sans_points', weight: 0),
      ]);

      expect(excluded, hasLength(3));
      expect(excluded.map((e) => e.$2), contains('Examen passé'));
      expect(excluded.map((e) => e.$2), contains('Rien de plus à y gagner'));
    });

    test('totalise l\'effort des premiers chapitres', () {
      final ranked = RevisionPriority.rank([
        target(id: 'a', weight: 10, length: 2),
        target(id: 'b', weight: 10, length: 3),
        target(id: 'c', weight: 10, length: 4),
      ]);

      expect(RevisionPriority.effortFor(ranked, count: 2), closeTo(5, 0.01));
    });

    test('rend une liste vide sans chapitre', () {
      expect(RevisionPriority.rank(const []), isEmpty);
    });
  });

  group('GanttTimeline — mise en page', () {
    test('encadre la période avec une marge', () {
      final layout = GanttTimeline.layout([item(id: 'a', days: 3)]);

      expect(layout.start, _today.subtract(const Duration(days: 2)));
      expect(layout.totalDays, 3 + 2 * GanttTimeline.paddingDays);
    });

    test('place sur des lignes distinctes les éléments qui se chevauchent', () {
      final layout = GanttTimeline.layout([
        item(id: 'a', startOffset: 0, days: 5),
        item(id: 'b', startOffset: 2, days: 5),
      ]);

      expect(layout.laneCount, 2);
      expect(layout.items.map((p) => p.lane).toSet(), {0, 1});
    });

    test('réutilise une ligne quand il n\'y a pas de chevauchement', () {
      final layout = GanttTimeline.layout([
        item(id: 'a', startOffset: 0, days: 2),
        item(id: 'b', startOffset: 5, days: 2),
      ]);

      expect(layout.laneCount, 1);
    });

    test('un jalon occupe une journée', () {
      expect(item(id: 'm', milestone: true, days: 10).durationDays, 1);
    });

    test('rend null pour une date hors fenêtre', () {
      final layout = GanttTimeline.layout([item(id: 'a')]);

      expect(layout.offsetOf(_today), GanttTimeline.paddingDays);
      expect(layout.offsetOf(_today.subtract(const Duration(days: 30))), isNull);
      expect(layout.offsetOf(_today.add(const Duration(days: 30))), isNull);
    });

    test('rend une mise en page vide sans élément', () {
      final layout = GanttTimeline.layout(const []);
      expect(layout.isEmpty, isTrue);
      expect(layout.totalDays, 0);
    });
  });

  group('GanttTimeline — dépendances', () {
    test('détecte une auto-dépendance', () {
      expect(GanttTimeline.wouldCreateCycle([item(id: 'a')], 'a', 'a'), isTrue);
    });

    test('détecte un cycle indirect A → B → C → A', () {
      final items = [
        item(id: 'a'),
        item(id: 'b', dependsOn: 'a'),
        item(id: 'c', dependsOn: 'b'),
      ];

      // Faire dépendre A de C fermerait la boucle.
      expect(GanttTimeline.wouldCreateCycle(items, 'a', 'c'), isTrue);
    });

    test('autorise une dépendance linéaire', () {
      final items = [item(id: 'a'), item(id: 'b')];
      expect(GanttTimeline.wouldCreateCycle(items, 'b', 'a'), isFalse);
    });

    test('repère un enchaînement incohérent', () {
      final items = [
        item(id: 'a', startOffset: 5, days: 3),
        // Démarre avant la fin de « a ».
        item(id: 'b', startOffset: 0, days: 3, dependsOn: 'a'),
      ];

      expect(GanttTimeline.violatedDependencies(items).map((i) => i.id), ['b']);
    });

    test('ne signale rien quand l\'enchaînement est correct', () {
      final items = [
        item(id: 'a', startOffset: 0, days: 3),
        item(id: 'b', startOffset: 4, days: 2, dependsOn: 'a'),
      ];
      expect(GanttTimeline.violatedDependencies(items), isEmpty);
    });
  });

  group('GanttTimeline — décalage', () {
    test('propage le décalage aux éléments dépendants', () {
      final items = [
        item(id: 'a', startOffset: 0, days: 2),
        item(id: 'b', startOffset: 3, days: 2, dependsOn: 'a'),
        item(id: 'c', startOffset: 6, days: 2, dependsOn: 'b'),
        item(id: 'independant', startOffset: 0, days: 2),
      ];

      final shifted =
          GanttTimeline.shift(items, 'a', const Duration(days: 3));
      final byId = {for (final i in shifted) i.id: i};

      expect(byId['a']!.startDate, _today.add(const Duration(days: 3)));
      expect(byId['b']!.startDate, _today.add(const Duration(days: 6)));
      expect(byId['c']!.startDate, _today.add(const Duration(days: 9)));
      // Ce qui ne dépend pas de « a » ne bouge pas.
      expect(byId['independant']!.startDate, _today);
    });

    test('ne fait rien pour un décalage nul ou un identifiant inconnu', () {
      final items = [item(id: 'a')];
      expect(GanttTimeline.shift(items, 'a', Duration.zero), items);
      expect(GanttTimeline.shift(items, 'inconnu', const Duration(days: 2)),
          items);
    });
  });

  group('StudySpeed', () {
    test('pondère la moyenne par la durée, pas par mesure', () {
      // 1 page en 1 h, puis 100 pages en 10 h : la moyenne simple donnerait
      // ~5,5 p/h, la moyenne pondérée ~9,2 p/h.
      final estimate = StudySpeed.estimate(
        [
          sample(units: 1, seconds: 3600),
          sample(units: 100, seconds: 36000),
        ],
        StudyActivity.reading,
      )!;

      expect(estimate.unitsPerHour, closeTo(101 / 11, 0.01));
    });

    test('ignore les mesures trop anciennes', () {
      final estimate = StudySpeed.estimate(
        [sample(units: 10, seconds: 3600, daysAgo: 200)],
        StudyActivity.reading,
      );
      expect(estimate, isNull);
    });

    test('filtre par matière', () {
      final samples = [
        sample(units: 20, seconds: 3600, subject: 'Physique'),
        sample(units: 5, seconds: 3600, subject: 'Droit'),
      ];

      expect(
        StudySpeed.estimate(samples, StudyActivity.reading, subject: 'Droit')!
            .unitsPerHour,
        closeTo(5, 0.01),
      );
    });

    test('ne se dit fiable qu\'avec assez de mesures concordantes', () {
      final single = StudySpeed.estimate(
        [sample(units: 10, seconds: 3600)],
        StudyActivity.reading,
      )!;
      expect(single.isReliable, isFalse);
      expect(single.confidenceLabel, contains('confirmer'));

      final consistent = StudySpeed.estimate(
        [
          sample(units: 10, seconds: 3600, daysAgo: 0),
          sample(units: 11, seconds: 3600, daysAgo: 1),
          sample(units: 10, seconds: 3600, daysAgo: 2),
        ],
        StudyActivity.reading,
      )!;
      expect(consistent.isReliable, isTrue);
    });

    test('signale une vitesse trop variable', () {
      final erratic = StudySpeed.estimate(
        [
          sample(units: 2, seconds: 3600, daysAgo: 0),
          sample(units: 30, seconds: 3600, daysAgo: 1),
          sample(units: 10, seconds: 3600, daysAgo: 2),
        ],
        StudyActivity.reading,
      )!;

      expect(erratic.isReliable, isFalse);
      expect(erratic.confidenceLabel, contains('Variable'));
    });

    test('pronostique une durée', () {
      final estimate = StudySpeed.estimate(
        [sample(units: 10, seconds: 3600)],
        StudyActivity.reading,
      )!;

      expect(estimate.forecast(20), const Duration(hours: 2));
      expect(estimate.forecast(0), isNull);
    });

    test('ignore les mesures de durée nulle', () {
      expect(
        StudySpeed.estimate(
          [sample(units: 10, seconds: 0)],
          StudyActivity.reading,
        ),
        isNull,
      );
    });

    test('formate les pronostics', () {
      expect(StudySpeed.formatForecast(const Duration(minutes: 45)), '45 min');
      expect(StudySpeed.formatForecast(const Duration(hours: 2)), '2 h');
      expect(
          StudySpeed.formatForecast(const Duration(hours: 2, minutes: 30)),
          '2 h 30');
    });
  });

  group('AdaptiveSchedule', () {
    test('répartit le travail sur les jours disponibles', () {
      final plan = AdaptiveSchedule.generate(
        [target(id: 'a', weight: 10, length: 6, difficulty: 3)],
        dailyCapacityHours: 2,
        horizonDays: 7,
        from: _today,
      );

      expect(plan.totalPlannedHours, closeTo(6, 0.01));
      expect(plan.isFeasible, isTrue);
      expect(plan.days.where((d) => !d.isEmpty), hasLength(3));
    });

    test('ne planifie jamais après la date d\'examen', () {
      final plan = AdaptiveSchedule.generate(
        [target(id: 'a', weight: 10, length: 10, examInDays: 1)],
        dailyCapacityHours: 2,
        horizonDays: 14,
        from: DateTime.now(),
      );

      // 10 h à caser en 2 jours à 2 h : impossible, et c'est dit.
      expect(plan.isFeasible, isFalse);
      expect(plan.unscheduled, hasLength(1));
      expect(plan.summary, contains('Il manque'));
    });

    test('sert les chapitres les plus rentables en premier', () {
      final plan = AdaptiveSchedule.generate(
        [
          target(id: 'peu_rentable', weight: 5, length: 10),
          target(id: 'rentable', weight: 20, length: 2),
        ],
        dailyCapacityHours: 2,
        horizonDays: 2,
        from: _today,
      );

      expect(plan.days.first.sessions.first.target.id, 'rentable');
    });

    test('respecte la capacité journalière', () {
      final plan = AdaptiveSchedule.generate(
        [target(id: 'a', weight: 10, length: 20)],
        dailyCapacityHours: 3,
        horizonDays: 5,
        from: _today,
      );

      for (final day in plan.days) {
        expect(day.plannedHours, lessThanOrEqualTo(3.001));
      }
    });

    test('rend un plan vide sans capacité ou sans chapitre', () {
      expect(
        AdaptiveSchedule.generate([target(id: 'a')],
                dailyCapacityHours: 0, from: _today)
            .isEmpty,
        isTrue,
      );
      expect(
        AdaptiveSchedule.generate(const [],
                dailyCapacityHours: 2, from: _today)
            .isEmpty,
        isTrue,
      );
    });

    test('convertit le plan en barres de Gantt, une par chapitre', () {
      var counter = 0;
      final plan = AdaptiveSchedule.generate(
        [target(id: 'a', weight: 10, length: 6)],
        dailyCapacityHours: 2,
        horizonDays: 7,
        from: _today,
      );

      final items = AdaptiveSchedule.toPlanItems(
        plan,
        userId: 'u1',
        idGenerator: () => 'id${counter++}',
      );

      // 3 journées de travail, mais une seule barre.
      expect(items, hasLength(1));
      expect(items.single.startDate, _today);
      expect(items.single.endDate, _today.add(const Duration(days: 2)));
    });

    test('marque une journée saturée', () {
      final plan = AdaptiveSchedule.generate(
        [target(id: 'a', weight: 10, length: 10)],
        dailyCapacityHours: 2,
        horizonDays: 10,
        from: _today,
      );

      expect(plan.days.first.isSaturated, isTrue);
      expect(plan.days.first.load, closeTo(1, 0.01));
    });
  });
}
