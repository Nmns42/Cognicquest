import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/note_model.dart';
import '../../../shared/models/planning_model.dart';
import '../../../shared/models/task_model.dart';
import '../../planning/domain/revision_priority.dart';
import 'quiz_generator.dart';

/// Une réponse enregistrée (historique synchronisé).
class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.questionId,
    required this.kind,
    required this.correct,
    required this.answeredAt,
    this.noteId,
    this.cardId,
    this.heading,
  });

  final String id;
  final String questionId;
  final QuizKind kind;
  final bool correct;
  final DateTime answeredAt;
  final String? noteId;
  final String? cardId;
  final String? heading;
}

/// Carte à créer après une erreur sur une question de fiche.
class CardDraft {
  const CardDraft({required this.front, required this.back, this.noteId});

  final String front;
  final String back;
  final String? noteId;
}

/// Effets d'un quiz sur le reste de l'apprentissage — les boucles :
///
/// - **Quiz → Flashcards (méthode des J)** : une erreur sur une carte la
///   remet à J0 (révisée aujourd'hui) ; une erreur sur une fiche crée la
///   carte correspondante, à réviser aujourd'hui.
/// - **Quiz → Apprentissage guidé** : les titres de fiche où l'on se trompe
///   deviennent des titres flous, à reprendre en étude guidée.
class QuizOutcome {
  const QuizOutcome({
    required this.correct,
    required this.total,
    required this.cardsToRelearn,
    required this.cardsToCreate,
    required this.fuzzyHeadings,
  });

  final int correct;
  final int total;

  /// Cartes ratées : replanifiées à J0.
  final List<String> cardsToRelearn;

  /// Notions de fiche ratées, sans carte existante : cartes à créer.
  final List<CardDraft> cardsToCreate;

  /// Titres flous révélés par ce quiz : `noteId → {titre}`.
  final Map<String, Set<String>> fuzzyHeadings;

  double get rate => total == 0 ? 0 : correct / total;

  static QuizOutcome of(
    List<(QuizQuestion, bool)> answers, {
    Iterable<Flashcard> existingCards = const [],
  }) {
    final fronts = {
      for (final c in existingCards) CardSide.parse(c.front).text.trim().toLowerCase(),
    };
    final relearn = <String>[];
    final create = <CardDraft>[];
    final fuzzy = <String, Set<String>>{};
    var correct = 0;
    for (final (question, ok) in answers) {
      if (ok) {
        correct++;
        continue;
      }
      if (question.kind.fromCard && question.cardId != null) {
        if (!relearn.contains(question.cardId)) relearn.add(question.cardId!);
      } else {
        final front = _frontFor(question);
        if (fronts.add(front.toLowerCase())) {
          create.add(CardDraft(
            front: front,
            back: question.context ?? question.answer,
            noteId: question.noteId,
          ));
        }
      }
      if (question.noteId != null && question.heading != null) {
        fuzzy.putIfAbsent(question.noteId!, () => {}).add(question.heading!);
      }
    }
    return QuizOutcome(
      correct: correct,
      total: answers.length,
      cardsToRelearn: relearn,
      cardsToCreate: create,
      fuzzyHeadings: fuzzy,
    );
  }

  /// Recto d'une carte tirée d'une question de fiche, lisible seul.
  static String _frontFor(QuizQuestion q) => switch (q.kind) {
        QuizKind.section => 'Que retenir de « ${q.heading} » ?',
        QuizKind.cloze => q.prompt.replaceFirst('Complète : ', ''),
        _ => q.prompt,
      };
}

/// Titres flous d'après l'historique : on s'y est trompé plus qu'on n'y a
/// réussi depuis [window]. Une réussite pèse moitié moins qu'une erreur :
/// une notion floue doit être retrouvée deux fois pour être levée.
Map<String, Set<String>> fuzzyHeadingsFrom(
  Iterable<QuizAttempt> attempts, {
  Duration window = const Duration(days: 30),
  DateTime? now,
}) {
  final since = (now ?? DateTime.now()).subtract(window);
  final score = <(String, String), double>{};
  for (final a in attempts) {
    if (a.noteId == null || a.heading == null) continue;
    if (a.answeredAt.isBefore(since)) continue;
    final key = (a.noteId!, a.heading!);
    score[key] = (score[key] ?? 0) + (a.correct ? -0.5 : 1);
  }
  final out = <String, Set<String>>{};
  for (final MapEntry(key: (noteId, heading), value: s) in score.entries) {
    if (s > 0) out.putIfAbsent(noteId, () => {}).add(heading);
  }
  return out;
}

/// Un chapitre à réviser aujourd'hui, avec ce qui le fait remonter.
class RevisionFocusItem {
  const RevisionFocusItem({
    required this.note,
    required this.score,
    required this.reasons,
  });

  final Note note;
  final double score;
  final List<String> reasons;
}

/// Priorités de révision du jour : flou (quiz, oublis, cartes dues),
/// rentabilité (Ordre & vitesse), objectifs SMART et matrice
/// d'Eisenhower, réunis en un seul classement expliqué.
abstract final class RevisionEngine {
  static List<RevisionFocusItem> rank({
    required List<Note> notes,
    required List<Flashcard> cards,
    required List<QuizAttempt> attempts,
    List<ExamTarget> targets = const [],
    List<StudyGoal> goals = const [],
    List<Task> tasks = const [],
    double? pagesPerHour,
    DateTime? now,
    int limit = 5,
  }) {
    final today = now ?? DateTime.now();
    final since = today.subtract(const Duration(days: 30));
    String norm(String? s) => (s ?? '').trim().toLowerCase();

    final scores = <String, double>{};
    final reasons = <String, List<String>>{};
    void add(String noteId, double value, String reason) {
      if (value <= 0) return;
      scores[noteId] = (scores[noteId] ?? 0) + value;
      reasons.putIfAbsent(noteId, () => []).add(reason);
    }

    final byId = {for (final n in notes) n.id: n};

    // Flou : erreurs de quiz récentes.
    final errors = <String, int>{};
    for (final a in attempts) {
      if (!a.correct && a.noteId != null && !a.answeredAt.isBefore(since)) {
        errors[a.noteId!] = (errors[a.noteId!] ?? 0) + 1;
      }
    }
    for (final MapEntry(key: id, value: n) in errors.entries) {
      add(id, n * 2.0, '$n erreur${n > 1 ? 's' : ''} au quiz');
    }

    // Flou : oublis et cartes dues.
    final lapses = <String, int>{};
    final due = <String, int>{};
    for (final c in cards) {
      final id = c.noteId;
      if (id == null) continue;
      lapses[id] = (lapses[id] ?? 0) + c.schedule.lapses;
      if (!c.schedule.dueAt.isAfter(today)) due[id] = (due[id] ?? 0) + 1;
    }
    for (final MapEntry(key: id, value: n) in lapses.entries) {
      if (n >= 2) add(id, n.toDouble(), 'cartes oubliées $n fois');
    }
    for (final MapEntry(key: id, value: n) in due.entries) {
      add(id, n * 0.5, '$n carte${n > 1 ? 's' : ''} à réviser (méthode des J)');
    }

    // Rentabilité : chapitres d'Ordre & vitesse liés à la fiche.
    final ranked = RevisionPriority.rank(targets, pagesPerHour: pagesPerHour);
    final best = ranked.isEmpty ? 0.0 : ranked.first.score;
    for (final entry in ranked) {
      final target = entry.target;
      final note = target.noteId != null
          ? byId[target.noteId]
          : notes.where((n) => norm(n.displayTitle) == norm(target.title)).firstOrNull;
      if (note == null) continue;
      add(note.id, best == 0 ? 0 : 4 * entry.score / best,
          'rentabilité ${entry.score.toStringAsFixed(1).replaceAll('.', ',')} pts/h');
      final days = target.daysUntilExam;
      if (days != null && days >= 0 && days <= 7) {
        add(note.id, 3, 'examen dans $days j');
      }
    }

    // Objectifs SMART en cours sur la matière ou le titre.
    for (final goal in goals.where((g) => !g.isCompleted)) {
      for (final note in notes) {
        final matches = (goal.subject != null && norm(goal.subject) == norm(note.subject)) ||
            norm(goal.title).contains(norm(note.displayTitle));
        if (!matches || note.displayTitle.trim().isEmpty) continue;
        final days = goal.daysRemaining;
        add(note.id, days != null && days <= 7 ? 4 : 2,
            'objectif « ${goal.title} »${days != null && days <= 7 ? ' (J-$days)' : ''}');
      }
    }

    // Eisenhower : tâches ouvertes qui citent la fiche ou sa matière.
    for (final task in tasks.where((t) => !t.isDone)) {
      final text = norm('${task.title} ${task.description}');
      for (final note in notes) {
        final title = norm(note.displayTitle);
        final subject = norm(note.subject);
        final cited = (title.length >= 4 && text.contains(title)) ||
            (subject.length >= 4 && text.contains(subject));
        if (!cited) continue;
        switch (task.quadrant) {
          case EisenhowerQuadrant.doNow:
            add(note.id, 3, 'tâche urgente et importante');
          case EisenhowerQuadrant.schedule:
            add(note.id, 1.5, 'tâche importante à planifier');
          default:
            break;
        }
      }
    }

    final out = [
      for (final MapEntry(key: id, value: score) in scores.entries)
        if (byId[id] case final note? when !note.isArchived)
          RevisionFocusItem(note: note, score: score, reasons: reasons[id]!),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return out.take(limit).toList();
  }
}
