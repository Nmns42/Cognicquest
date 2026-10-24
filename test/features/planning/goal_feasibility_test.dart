import 'package:cognicquest/features/planning/domain/goal_feasibility.dart';
import 'package:cognicquest/features/planning/domain/study_speed.dart';
import 'package:cognicquest/shared/models/planning_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reading = SpeedEstimate(
    activity: StudyActivity.reading,
    unit: 'pages',
    unitsPerHour: 20,
    sampleCount: 4,
    spread: 0.2,
  );
  const cards = SpeedEstimate(
    activity: StudyActivity.memorising,
    unit: 'cartes',
    unitsPerHour: 60,
    sampleCount: 3,
    spread: 0.1,
  );

  StudyGoal goal({
    String unit = 'pages',
    double target = 120,
    double done = 20,
    int? inDays = 10,
  }) {
    final now = DateTime.now();
    return StudyGoal(
      id: 'g',
      userId: 'u',
      title: 'Lire le cours de thermo',
      createdAt: now,
      metricLabel: unit,
      targetValue: target,
      currentValue: done,
      deadline: inDays == null
          ? null
          : DateTime(now.year, now.month, now.day + inDays),
    );
  }

  test('unités comparées sans casse, pluriel ni complément', () {
    expect(GoalFeasibility.normalizeUnit('Pages'), 'page');
    expect(GoalFeasibility.normalizeUnit('cartes maîtrisées'), 'carte');
    expect(GoalFeasibility.normalizeUnit('quiz'), 'quiz');
  });

  test('temps restant et rythme quotidien d\'après la vitesse', () {
    // 100 pages à 20 pages/h = 5 h, sur 10 jours = 30 min par jour.
    final f = GoalFeasibility.of(goal(), [reading, cards])!;
    expect(f.speed.unit, 'pages');
    expect(f.totalTime, const Duration(hours: 5));
    expect(f.perDay, const Duration(minutes: 30));
    expect(f.isStretched, isFalse);
  });

  test('« cartes maîtrisées » utilise la vitesse de mémorisation', () {
    final f = GoalFeasibility.of(
        goal(unit: 'cartes maîtrisées', target: 300, done: 0, inDays: 5),
        [reading, cards])!;
    expect(f.totalTime, const Duration(hours: 5));
    expect(f.perDay, const Duration(hours: 1));
  });

  test('sans vitesse dans cette unité (ex. % aux quiz) : rien', () {
    expect(GoalFeasibility.of(goal(unit: '% de réussite'), [reading]), isNull);
  });

  test('sans échéance : total seulement ; trop serré : signalé', () {
    expect(GoalFeasibility.of(goal(inDays: null), [reading])!.perDay, isNull);
    final tight = GoalFeasibility.of(
        goal(target: 1000, done: 0, inDays: 2), [reading])!;
    expect(tight.isStretched, isTrue);
  });
}
