import 'package:cognicquest/features/coach/domain/tree_coach.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<CoachTopic> topics(CoachSignals s, {int limit = 10}) =>
      [for (final a in TreeCoach(s).advice(limit: limit)) a.topic];

  group('vitalité', () {
    test('sans aucune donnée : 0 et invitation à commencer', () {
      const coach = TreeCoach(CoachSignals());
      expect(coach.vitality, 0);
      expect(coach.headline, contains('premières données'));
    });

    test('moyenne pondérée des seuls signaux connus', () {
      // Régularité 1 (poids 0,4) et rétention 0,5 (poids 0,3).
      const coach = TreeCoach(CoachSignals(
        habitCount: 2,
        habitConsistency: 1,
        retentionRate: 0.5,
      ));
      expect(coach.vitality, closeTo((0.4 + 0.15) / 0.7, 1e-9));
    });

    test('humeur et énergie ramenées de 1–5 à 0–1', () {
      const coach = TreeCoach(CoachSignals(recentMood: 5, recentEnergy: 1));
      expect(coach.vitality, closeTo(0.5, 1e-9));
    });
  });

  group('conseils', () {
    test('épuisement : la pause passe en premier', () {
      final t = topics(const CoachSignals(
        recentEffort: 9,
        recentEnergy: 1.5,
        recentMood: 2,
        daysSinceLastEntry: 0,
        journalEntries: 5,
      ));
      expect(t.first, CoachTopic.rest);
      expect(t, contains(CoachTopic.mood));
    });

    test('notion floue : nommée, avec lien vers « Explique-moi »', () {
      final advice = TreeCoach(const CoachSignals(
        daysSinceLastEntry: 0,
        fuzzyChapters: [
          FuzzyChapter(noteId: 'n1', title: 'Cycle de Krebs', confidence: 1),
          FuzzyChapter(noteId: 'n2', title: 'Glycolyse', lapses: 3),
        ],
      )).advice();
      final fuzzy =
          advice.firstWhere((a) => a.topic == CoachTopic.understanding);
      expect(fuzzy.title, contains('Cycle de Krebs'));
      expect(fuzzy.body, contains('Glycolyse'));
      expect(fuzzy.route, '/review/explain/n1');
    });

    test('rétention basse : réviser les cartes dues', () {
      final advice = TreeCoach(const CoachSignals(
        retentionRate: 0.62,
        dueCards: 14,
        daysSinceLastEntry: 1,
      )).advice();
      final retention =
          advice.firstWhere((a) => a.topic == CoachTopic.retention);
      expect(retention.title, contains('62 %'));
      expect(retention.actionLabel, 'Réviser 14 cartes');
    });

    test('régularité faible et journal délaissé', () {
      final t = topics(const CoachSignals(
        habitCount: 3,
        habitConsistency: 0.2,
        daysSinceLastEntry: 5,
        journalEntries: 4,
      ));
      expect(t, containsAll([CoachTopic.habits, CoachTopic.journal]));
    });

    test('tout va bien : encouragements', () {
      final t = topics(const CoachSignals(
        habitCount: 3,
        habitConsistency: 0.85,
        retentionRate: 0.93,
        recentMood: 4,
        recentEnergy: 4,
        daysSinceLastEntry: 0,
        journalEntries: 10,
      ));
      expect(t, everyElement(CoachTopic.cheer));
      expect(t, hasLength(2));
    });

    test('limite respectée, et toujours au moins un conseil', () {
      expect(TreeCoach(const CoachSignals(daysSinceLastEntry: 0)).advice(),
          isNotEmpty);
      final many = TreeCoach(const CoachSignals(
        strainedDays: 4,
        recentMood: 1,
        retentionRate: 0.4,
        habitCount: 1,
        habitConsistency: 0.1,
      )).advice(limit: 2);
      expect(many, hasLength(2));
    });
  });

  test('flou d\'une fiche : confiance basse et oublis', () {
    expect(const FuzzyChapter(noteId: 'a', title: 'A', confidence: 4).fuzziness,
        0);
    expect(const FuzzyChapter(noteId: 'a', title: 'A', confidence: 1).fuzziness,
        4);
    expect(const FuzzyChapter(noteId: 'a', title: 'A', lapses: 1).fuzziness, 0);
    expect(const FuzzyChapter(noteId: 'a', title: 'A', lapses: 3).fuzziness, 3);
  });
}
