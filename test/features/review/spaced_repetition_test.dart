import 'package:cognicquest/core/config/app_config.dart';
import 'package:cognicquest/features/review/domain/spaced_repetition.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 3, 10, 9);

ScheduleState advance(List<ReviewGrade> grades) {
  var state = SpacedRepetition.initial(now: _now);
  for (final grade in grades) {
    state = SpacedRepetition.next(state, grade, now: _now);
  }
  return state;
}

void main() {
  group('état initial', () {
    test('une carte neuve est due immédiatement', () {
      final state = SpacedRepetition.initial(now: _now);

      expect(state.step, 0);
      expect(state.repetitions, 0);
      expect(state.dueAt, _now);
      expect(state.easeFactor, AppConfig.initialEaseFactor);
    });
  });

  group('méthode des J', () {
    test('« correct » suit l\'échelle J+1, J+3, J+7…', () {
      // Facteur de facilité inchangé sur « correct » : on lit l'échelle brute.
      expect(advance([ReviewGrade.good]).intervalDays, 1);
      expect(advance([ReviewGrade.good, ReviewGrade.good]).intervalDays, 3);
      expect(
        advance([ReviewGrade.good, ReviewGrade.good, ReviewGrade.good])
            .intervalDays,
        7,
      );
    });

    test('l\'intervalle croît strictement le long de l\'échelle', () {
      var previous = 0;
      var state = SpacedRepetition.initial(now: _now);
      for (var i = 0; i < SpacedRepetition.jLadder.length; i++) {
        state = SpacedRepetition.next(state, ReviewGrade.good, now: _now);
        expect(state.intervalDays, greaterThan(previous));
        previous = state.intervalDays;
      }
    });

    test('au-delà de l\'échelle, l\'intervalle continue de croître', () {
      var state = SpacedRepetition.initial(now: _now);
      for (var i = 0; i < SpacedRepetition.jLadder.length + 3; i++) {
        state = SpacedRepetition.next(state, ReviewGrade.good, now: _now);
      }
      expect(state.intervalDays, greaterThan(SpacedRepetition.jLadder.last));
      expect(state.intervalDays,
          lessThanOrEqualTo(SpacedRepetition.maxIntervalDays));
    });

    test('l\'intervalle est plafonné à un an', () {
      var state = SpacedRepetition.initial(now: _now);
      for (var i = 0; i < 40; i++) {
        state = SpacedRepetition.next(state, ReviewGrade.easy, now: _now);
      }
      expect(state.intervalDays, SpacedRepetition.maxIntervalDays);
    });
  });

  group('jugements', () {
    test('« à revoir » ramène au premier rang et compte un oubli', () {
      final learned =
          advance([ReviewGrade.good, ReviewGrade.good, ReviewGrade.good]);
      expect(learned.step, 3);

      final failed = SpacedRepetition.next(learned, ReviewGrade.again, now: _now);

      expect(failed.step, 0);
      expect(failed.lapses, 1);
      // La carte revient dans la session, pas le lendemain.
      expect(failed.intervalDays, 0);
      expect(failed.dueAt.isAfter(_now), isTrue);
      expect(failed.dueAt.difference(_now).inMinutes, lessThanOrEqualTo(10));
    });

    test('« difficile » maintient le rang et abaisse la facilité', () {
      final state = advance([ReviewGrade.good, ReviewGrade.good]);
      final harder = SpacedRepetition.next(state, ReviewGrade.hard, now: _now);

      expect(harder.step, state.step);
      expect(harder.easeFactor, lessThan(state.easeFactor));
    });

    test('« facile » saute un rang et augmente la facilité', () {
      final state = advance([ReviewGrade.good]);
      final easier = SpacedRepetition.next(state, ReviewGrade.easy, now: _now);

      expect(easier.step, state.step + 2);
      expect(easier.easeFactor, greaterThan(state.easeFactor));
    });

    test('chaque jugement compte une répétition', () {
      expect(advance([ReviewGrade.good, ReviewGrade.again]).repetitions, 2);
    });
  });

  group('facteur de facilité', () {
    test('ne descend jamais sous le plancher', () {
      var state = SpacedRepetition.initial(now: _now);
      for (var i = 0; i < 30; i++) {
        state = SpacedRepetition.next(state, ReviewGrade.again, now: _now);
      }
      expect(state.easeFactor, AppConfig.minEaseFactor);
    });

    test('ne dépasse jamais le plafond', () {
      var state = SpacedRepetition.initial(now: _now);
      for (var i = 0; i < 30; i++) {
        state = SpacedRepetition.next(state, ReviewGrade.easy, now: _now);
      }
      expect(state.easeFactor, SpacedRepetition.maxEaseFactor);
    });

    test('une carte difficile revient plus vite qu\'une carte facile', () {
      var hardCard = SpacedRepetition.initial(now: _now);
      var easyCard = SpacedRepetition.initial(now: _now);

      // Même nombre de rangs gravis, vécus différemment.
      for (var i = 0; i < 4; i++) {
        hardCard = SpacedRepetition.next(hardCard, ReviewGrade.good, now: _now);
        easyCard = SpacedRepetition.next(easyCard, ReviewGrade.good, now: _now);
      }
      hardCard = SpacedRepetition.next(hardCard, ReviewGrade.hard, now: _now);

      expect(hardCard.easeFactor, lessThan(easyCard.easeFactor));
    });
  });

  group('échéances', () {
    test('un intervalle non nul tombe sur un début de journée', () {
      final state = advance([ReviewGrade.good]);

      expect(state.dueAt.hour, 0);
      expect(state.dueAt.minute, 0);
      expect(state.dueAt.day, _now.day + 1);
    });

    test('le premier rang reste à 1 jour quelle que soit la facilité', () {
      // Sans ce garde-fou, un facteur bas donnerait « revois ça dans 0 jour ».
      var state = SpacedRepetition.initial(now: _now);
      for (var i = 0; i < 10; i++) {
        state = SpacedRepetition.next(state, ReviewGrade.again, now: _now);
      }
      final afterFail = SpacedRepetition.next(state, ReviewGrade.good, now: _now);
      expect(afterFail.intervalDays, 1);
    });
  });

  group('preview', () {
    test('annonce un intervalle pour chacun des quatre jugements', () {
      final preview = SpacedRepetition.preview(advance([ReviewGrade.good]));

      expect(preview.keys, containsAll(ReviewGrade.values));
      expect(preview[ReviewGrade.again], 0);
      expect(preview[ReviewGrade.easy]!,
          greaterThan(preview[ReviewGrade.good]!));
    });

    test('ne modifie pas l\'état qu\'elle prévisualise', () {
      final state = advance([ReviewGrade.good]);
      SpacedRepetition.preview(state);
      expect(state.step, 1);
    });
  });

  group('describeInterval', () {
    test('formate les échéances en français', () {
      expect(SpacedRepetition.describeInterval(0), 'dans la session');
      expect(SpacedRepetition.describeInterval(1), 'demain');
      expect(SpacedRepetition.describeInterval(7), 'dans 7 j');
      expect(SpacedRepetition.describeInterval(30), 'dans 1 mois');
      expect(SpacedRepetition.describeInterval(90), 'dans 3 mois');
    });
  });

  group('Sq3rStep', () {
    test('couvre les cinq étapes de la méthode', () {
      expect(Sq3rStep.values, hasLength(5));
      expect(Sq3rStep.values.first, Sq3rStep.survey);
      expect(Sq3rStep.review.isLast, isTrue);
      expect(Sq3rStep.survey.isLast, isFalse);
    });

    test('fromIndex borne les valeurs hors plage', () {
      expect(Sq3rStep.fromIndex(-5), Sq3rStep.survey);
      expect(Sq3rStep.fromIndex(99), Sq3rStep.review);
      expect(Sq3rStep.fromIndex(2), Sq3rStep.read);
    });
  });

  group('ReviewGrade', () {
    test('retombe sur « correct » pour une valeur inconnue', () {
      expect(ReviewGrade.fromValue(null), ReviewGrade.good);
      expect(ReviewGrade.fromValue('inventé'), ReviewGrade.good);
      expect(ReviewGrade.fromValue('again'), ReviewGrade.again);
    });
  });
}
