import 'package:cognicquest/features/metacognition/domain/learning_profile.dart';
import 'package:cognicquest/features/metacognition/domain/metacognition_insights.dart';
import 'package:cognicquest/shared/models/metacognition_model.dart';
import 'package:flutter_test/flutter_test.dart';

JournalEntry entry({
  int mood = 3,
  int energy = 3,
  int rpe = 5,
  int daysAgo = 0,
  String id = 'e',
}) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: daysAgo))
      // Midi : à l'abri des bascules de jour selon l'heure du test.
      .add(const Duration(hours: 12));
  return JournalEntry(
    id: '$id-$daysAgo-$mood',
    userId: 'u1',
    mood: mood,
    energy: energy,
    rpe: rpe,
    createdAt: day,
  );
}

ErrorLog error(ErrorType type, {String? subject, String correction = ''}) =>
    ErrorLog(
      id: '${type.value}-${DateTime.now().microsecondsSinceEpoch}',
      userId: 'u1',
      description: 'Erreur',
      errorType: type,
      subject: subject,
      correction: correction,
      createdAt: DateTime.now(),
    );

void main() {
  group('ErrorPattern', () {
    test('compte les erreurs par type', () {
      final pattern = ErrorPattern.from([
        error(ErrorType.inattention),
        error(ErrorType.inattention),
        error(ErrorType.comprehension),
      ]);

      expect(pattern.total, 3);
      expect(pattern.countsByType[ErrorType.inattention], 2);
      expect(pattern.shareOf(ErrorType.inattention), closeTo(0.666, 0.01));
    });

    test('désigne un type dominant au-delà de 40 %', () {
      final pattern = ErrorPattern.from([
        error(ErrorType.inattention),
        error(ErrorType.inattention),
        error(ErrorType.inattention),
        error(ErrorType.comprehension),
      ]);

      expect(pattern.dominant, ErrorType.inattention);
      expect(pattern.summary, contains('Inattention'));
      // Le conseil de remédiation accompagne le diagnostic.
      expect(pattern.summary, contains('Ralentis'));
    });

    test('ne désigne pas de dominant en cas d\'égalité', () {
      final pattern = ErrorPattern.from([
        error(ErrorType.inattention),
        error(ErrorType.comprehension),
      ]);

      expect(pattern.dominant, isNull);
      expect(pattern.summary, contains('réparties'));
    });

    test('ne désigne pas de dominant sous le seuil de 40 %', () {
      // 2 sur 5 = 40 %… mais les autres types se partagent le reste ; on veut
      // strictement plus de 40 % pour parler de motif.
      final pattern = ErrorPattern.from([
        error(ErrorType.inattention),
        error(ErrorType.comprehension),
        error(ErrorType.method),
        error(ErrorType.memorisation),
        error(ErrorType.instructions),
      ]);

      expect(pattern.dominant, isNull);
    });

    test('compte les erreurs corrigées', () {
      final pattern = ErrorPattern.from([
        error(ErrorType.method, correction: 'Refaire la démarche'),
        error(ErrorType.method),
      ]);

      expect(pattern.correctedCount, 1);
    });

    test('rend un motif vide sans erreur', () {
      final pattern = ErrorPattern.from(const []);
      expect(pattern.isEmpty, isTrue);
      expect(pattern.dominant, isNull);
      expect(pattern.shareOf(ErrorType.method), 0);
    });
  });

  group('MetacognitionInsights — moyennes', () {
    test('calcule humeur, énergie et effort moyens', () {
      final insights = MetacognitionInsights.from([
        entry(mood: 2, energy: 2, rpe: 6),
        entry(mood: 4, energy: 4, rpe: 8, daysAgo: 1),
      ]);

      expect(insights.averageMood, 3);
      expect(insights.averageEnergy, 3);
      expect(insights.averageRpe, 7);
      expect(insights.entryCount, 2);
    });

    test('rend des agrégats vides sans entrée', () {
      final insights = MetacognitionInsights.from(const []);
      expect(insights.isEmpty, isTrue);
      expect(insights.currentStreak, 0);
      expect(insights.summary, contains('Note ton ressenti'));
    });
  });

  group('MetacognitionInsights — risque d\'épuisement', () {
    test('signale un risque après 3 journées tendues', () {
      final insights = MetacognitionInsights.from([
        for (var i = 0; i < 3; i++) entry(mood: 2, rpe: 9, daysAgo: i),
      ]);

      expect(insights.strainedDays, 3);
      expect(insights.strainLevel, StrainLevel.atRisk);
      expect(insights.summary, contains('Allège'));
    });

    test('met en veille dès une journée tendue', () {
      final insights = MetacognitionInsights.from([
        entry(mood: 1, rpe: 10),
        entry(mood: 4, rpe: 4, daysAgo: 1),
      ]);

      expect(insights.strainLevel, StrainLevel.watch);
    });

    test('reste sain quand effort et moral vont ensemble', () {
      final insights = MetacognitionInsights.from([
        for (var i = 0; i < 5; i++) entry(mood: 4, rpe: 6, daysAgo: i),
      ]);

      expect(insights.strainLevel, StrainLevel.healthy);
      expect(insights.strainedDays, 0);
    });

    test('un effort fort avec bon moral n\'est pas une journée tendue', () {
      // Travailler dur en se sentant bien n'est pas un signal d'alerte.
      expect(entry(mood: 5, rpe: 10).isStrainedDay, isFalse);
      expect(entry(mood: 2, rpe: 8).isStrainedDay, isTrue);
    });

    test('ignore les journées tendues de plus de deux semaines', () {
      final insights = MetacognitionInsights.from([
        for (var i = 20; i < 24; i++) entry(mood: 1, rpe: 10, daysAgo: i),
      ]);

      expect(insights.strainedDays, 0);
    });
  });

  group('MetacognitionInsights — série et tendance', () {
    test('compte les jours consécutifs de suivi', () {
      final insights = MetacognitionInsights.from([
        entry(daysAgo: 0),
        entry(daysAgo: 1),
        entry(daysAgo: 2),
      ]);

      expect(insights.currentStreak, 3);
    });

    test('ne casse pas la série si le jour en cours n\'est pas encore noté', () {
      // La journée n'est pas finie : elle ne doit pas compter comme un trou.
      final insights = MetacognitionInsights.from([
        entry(daysAgo: 1),
        entry(daysAgo: 2),
      ]);

      expect(insights.currentStreak, 2);
    });

    test('s\'arrête au premier jour manquant', () {
      final insights = MetacognitionInsights.from([
        entry(daysAgo: 0),
        entry(daysAgo: 1),
        entry(daysAgo: 4),
      ]);

      expect(insights.currentStreak, 2);
    });

    test('la tendance a 7 points, null pour les jours non notés', () {
      final insights = MetacognitionInsights.from([entry(mood: 5)]);

      expect(insights.moodTrend, hasLength(7));
      // Un jour non noté n'est pas un jour à zéro.
      expect(insights.moodTrend.last, 5);
      expect(insights.moodTrend.take(6), everyElement(isNull));
    });

    test('moyenne plusieurs entrées du même jour', () {
      final insights = MetacognitionInsights.from([
        entry(mood: 2, id: 'a'),
        entry(mood: 4, id: 'b'),
      ]);

      expect(insights.moodTrend.last, 3);
    });
  });

  group('ProfilingQuestionnaire', () {
    test('déduit un profil global', () {
      final profile = ProfilingQuestionnaire.score({
        'new_topic': 'overview',
        'stuck': 'context',
        'plan': 'themes',
      });

      expect(profile.processingStyle, ProcessingStyle.global);
    });

    test('déduit un profil séquentiel', () {
      final profile = ProfilingQuestionnaire.score({
        'new_topic': 'step',
        'stuck': 'method',
        'plan': 'slots',
      });

      expect(profile.processingStyle, ProcessingStyle.sequential);
    });

    test('ne tranche pas en cas d\'égalité', () {
      // Un profil inventé serait pire qu'un profil absent.
      final profile = ProfilingQuestionnaire.score({
        'new_topic': 'overview',
        'stuck': 'method',
      });

      expect(profile.processingStyle, isNull);
    });

    test('déduit le canal privilégié', () {
      final profile = ProfilingQuestionnaire.score({
        'remember': 'diagram',
        'explain': 'draw',
      });

      expect(profile.preferredChannel, PreferredChannel.visual);
    });

    test('ignore les réponses inconnues', () {
      final profile = ProfilingQuestionnaire.score({
        'question_inexistante': 'peu importe',
        'new_topic': 'valeur_invalide',
      });

      expect(profile.processingStyle, isNull);
      expect(profile.preferredChannel, isNull);
    });

    test('marque le profil complet quand une date est fournie', () {
      final profile = ProfilingQuestionnaire.score(
        {'new_topic': 'overview'},
        completedAt: DateTime(2026, 5, 1),
      );

      expect(profile.isComplete, isTrue);
      expect(ProfilingQuestionnaire.score({'new_topic': 'overview'}).isComplete,
          isFalse);
    });

    test('la progression suit le nombre de réponses', () {
      final total = ProfilingQuestionnaire.questions.length;
      final profile =
          ProfilingQuestionnaire.score({'new_topic': 'overview', 'stuck': 'context'});

      expect(profile.progress, closeTo(2 / total, 0.001));
    });
  });

  group('LearningProfile.recommendations', () {
    test('conseille le graphe à un profil global', () {
      final profile = ProfilingQuestionnaire.score({
        'new_topic': 'overview',
        'stuck': 'context',
      });

      expect(profile.recommendations.join(), contains('graphe'));
    });

    test('conseille le Kanban à un profil séquentiel', () {
      final profile = ProfilingQuestionnaire.score({
        'new_topic': 'step',
        'stuck': 'method',
      });

      expect(profile.recommendations.join(), contains('Kanban'));
    });

    test('ne conseille rien sans profil déterminé', () {
      expect(LearningProfile.empty.recommendations, isEmpty);
    });
  });

  group('WhyChain', () {
    WhyChain chain({
      List<String> answers = const [],
      String rootCause = '',
      String actionPlan = '',
    }) =>
        WhyChain(
          id: 'w1',
          userId: 'u1',
          problem: 'Je n\'ai pas révisé',
          answers: answers,
          rootCause: rootCause,
          actionPlan: actionPlan,
          createdAt: DateTime.now(),
        );

    test('la profondeur ignore les réponses vides', () {
      expect(chain(answers: ['a', '  ', 'b']).depth, 2);
    });

    test('se ferme à cinq niveaux', () {
      expect(chain(answers: ['1', '2', '3', '4']).canGoDeeper, isTrue);
      expect(chain(answers: ['1', '2', '3', '4', '5']).canGoDeeper, isFalse);
    });

    test('n\'est complète qu\'avec une cause ET une action', () {
      // S'arrêter au diagnostic, c'est ruminer.
      expect(
        chain(answers: ['1', '2', '3'], rootCause: 'Fatigue').isComplete,
        isFalse,
      );
      expect(
        chain(
          answers: ['1', '2', '3'],
          rootCause: 'Fatigue',
          actionPlan: 'Coucher à 23 h',
        ).isComplete,
        isTrue,
      );
    });

    test('exige au moins trois pourquoi', () {
      expect(
        chain(
          answers: ['1', '2'],
          rootCause: 'Fatigue',
          actionPlan: 'Dormir',
        ).isComplete,
        isFalse,
      );
    });
  });

  group('Reframe', () {
    test('n\'est complet qu\'avec reformulation et objectif', () {
      Reframe build({String reframed = '', String goal = ''}) => Reframe(
            id: 'r1',
            userId: 'u1',
            limitingThought: 'Je suis nul',
            reframedThought: reframed,
            growthGoal: goal,
            createdAt: DateTime.now(),
          );

      expect(build().isComplete, isFalse);
      expect(build(reframed: 'Ça résiste').isComplete, isFalse);
      expect(build(reframed: 'Ça résiste', goal: 'Un exo/jour').isComplete,
          isTrue);
    });
  });

  group('Énumérations', () {
    test('ErrorType retombe sur « compréhension » si inconnu', () {
      expect(ErrorType.fromValue(null), ErrorType.comprehension);
      expect(ErrorType.fromValue('inventé'), ErrorType.comprehension);
      expect(ErrorType.fromValue('inattention'), ErrorType.inattention);
    });

    test('BlockerType rend null si inconnu', () {
      expect(BlockerType.fromValue(null), isNull);
      expect(BlockerType.fromValue('inventé'), isNull);
      expect(BlockerType.fromValue('emotional'), BlockerType.emotional);
    });

    test('BlockerType couvre les quatre natures du CdC', () {
      expect(BlockerType.values, hasLength(4));
    });
  });

  group('Recadrage : pièges en mots simples', () {
    test('aucun jargon de psychologie dans les libellés', () {
      const jargon = [
        'distorsion',
        'catastroph',
        'généralisation',
        'étiquetage',
        'minimisation',
        'lecture de pensée',
        'tout ou rien',
      ];
      for (final distortion in CognitiveDistortion.values) {
        final label = distortion.label.toLowerCase();
        for (final word in jargon) {
          expect(label, isNot(contains(word)), reason: distortion.name);
        }
      }
    });

    test('chaque piège a une phrase typique et sa question pour le désamorcer',
        () {
      for (final distortion in CognitiveDistortion.values) {
        expect(distortion.example, isNotEmpty, reason: distortion.name);
        expect(distortion.challenge, contains('?'), reason: distortion.name);
      }
    });

    test('les valeurs enregistrées ne changent pas', () {
      expect(CognitiveDistortion.fromValue('all_or_nothing'),
          CognitiveDistortion.allOrNothing);
      expect(CognitiveDistortion.fromValue('catastrophising'),
          CognitiveDistortion.catastrophising);
    });
  });

  group('Recadrage : exploration issue des 5 Pourquoi', () {
    test('trois questions pour creuser, chacune avec un exemple', () {
      expect(ReframeDigging.questions, hasLength(3));
      for (final (question, hint) in ReframeDigging.questions) {
        expect(question, endsWith('?'));
        expect(hint, startsWith('Ex :'));
      }
    });

    test('chaque nature de cause a un libellé concret', () {
      final labels = BlockerType.values.map(ReframeDigging.causeLabel).toSet();
      expect(labels, hasLength(BlockerType.values.length));
    });

    test('l\'exploration est une chaîne de pourquoi complète', () {
      final chain = WhyChain(
        id: 'r1',
        userId: 'u1',
        problem: 'Je suis nul en maths',
        answers: const ['Bloqué sur un exercice', 'Partiel proche',
            'Cours de base jamais revu'],
        rootCause: 'Cours de base jamais revu',
        blockerType: BlockerType.cognitive,
        actionPlan: 'Refaire 3 exercices corrigés',
        createdAt: DateTime(2026, 10, 15),
      );
      expect(chain.depth, 3);
      expect(chain.isComplete, isTrue);
    });
  });
}
