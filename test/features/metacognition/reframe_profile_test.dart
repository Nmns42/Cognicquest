import 'package:cognicquest/features/metacognition/domain/learning_profile.dart';
import 'package:cognicquest/features/metacognition/domain/profile_playbook.dart';
import 'package:cognicquest/features/metacognition/domain/reframe_summary.dart';
import 'package:cognicquest/shared/models/metacognition_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bilan du recadrage', () {
    test('vide tant que rien n’est écrit', () {
      final summary =
          ReframeSummary.build(thought: '  ', digging: const ['', '', '']);
      expect(summary.isEmpty, isTrue);
      expect(summary.completeness, 0);
    });

    test('synthèse et plan adaptés à la cause et au piège', () {
      final summary = ReframeSummary.build(
        thought: 'Je suis nul en maths',
        digging: const ['', '', 'Je n’ai jamais revu les limites'],
        cause: BlockerType.cognitive,
        distortion: CognitiveDistortion.labelling,
        evidence: '14 au dernier contrôle',
        reframed: 'Les limites me résistent, le reste non',
        goal: 'Refaire 3 exercices sur les limites demain',
      );
      expect(summary.completeness, 1);
      expect(summary.synthesis.join(' '), contains('Je n’ai jamais revu'));
      expect(summary.synthesis.join(' '), contains('Piège repéré'));
      expect(summary.plan.first.text, contains('Refaire 3 exercices'));
      // Cause cognitive : étude guidée puis quiz ciblé.
      expect(summary.plan.map((s) => s.route),
          containsAll(['/review/sq3r', '/review/quiz']));
      // Piège « étiquette » : décrire l'action, pas la personne.
      expect(summary.plan.last.text, contains('pas la personne'));
      expect(summary.firstStep, 'Refaire 3 exercices sur les limites demain');
    });

    test('cause émotionnelle : respiration, Pomodoro court, journal', () {
      final summary = ReframeSummary.build(
        thought: 'Je vais rater',
        digging: const ['', '', ''],
        cause: BlockerType.emotional,
      );
      expect(summary.plan.map((s) => s.route),
          containsAll(['/pomodoro', '/journal/entry']));
      expect(summary.completeness, closeTo(2 / 6, 1e-9));
    });
  });

  group('mode d’emploi du profil', () {
    test('global + visuel : graphe regroupé, sessions longues, couleurs', () {
      const profile = LearningProfile(
        answers: {},
        processingStyle: ProcessingStyle.global,
        preferredChannel: PreferredChannel.visual,
      );
      final advice = ProfilePlaybook.of(profile);
      final actions = advice.map((a) => a.action).toList();
      expect(actions.whereType<GraphOverviewPreset>(), hasLength(1));
      final pomodoro = actions.whereType<PomodoroPreset>().single;
      expect(pomodoro.work, 45);
      expect(advice.map((a) => a.title), contains('Rends tes fiches visuelles'));
      // Conseil commun à tous : se tester plutôt que relire.
      expect(advice.last.title, 'Teste-toi plutôt que relire');
    });

    test('séquentiel + kinesthésique : rythme court, deux préréglages', () {
      const profile = LearningProfile(
        answers: {},
        processingStyle: ProcessingStyle.sequential,
        preferredChannel: PreferredChannel.kinesthetic,
      );
      final presets = ProfilePlaybook.of(profile)
          .map((a) => a.action)
          .whereType<PomodoroPreset>()
          .map((p) => p.work)
          .toList();
      expect(presets, [25, 20]);
    });

    test('auditif : rappel quotidien proposé', () {
      const profile =
          LearningProfile(
          answers: {}, preferredChannel: PreferredChannel.auditory);
      final reminder = ProfilePlaybook.of(profile)
          .map((a) => a.action)
          .whereType<DailyReminderPreset>()
          .single;
      expect(reminder.minutes, 18 * 60);
    });

    test('chaque conseil a au moins deux étapes et un pourquoi', () {
      for (final style in [...ProcessingStyle.values, null]) {
        for (final channel in [...PreferredChannel.values, null]) {
          final profile = LearningProfile(
              answers: const {},
              processingStyle: style,
              preferredChannel: channel);
          for (final advice in ProfilePlaybook.of(profile)) {
            expect(advice.steps.length, greaterThanOrEqualTo(2),
                reason: advice.title);
            expect(advice.why, isNotEmpty);
          }
        }
      }
    });
  });
}
