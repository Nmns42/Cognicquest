import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/micro_animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/flashcard_model.dart';
import '../domain/spaced_repetition.dart';
import '../providers/review_provider.dart';
import '../../../core/theme/tokens.dart';

/// Session de révision : une carte à la fois, réponse cachée, puis jugement.
///
/// C'est le **rappel actif** du CdC : « se tester sans relire pour stimuler la
/// mémoire à long terme ». La réponse ne s'affiche jamais avant que
/// l'utilisateur ait tenté de la retrouver.
class ReviewSessionPage extends ConsumerStatefulWidget {
  const ReviewSessionPage({super.key});

  @override
  ConsumerState<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends ConsumerState<ReviewSessionPage> {
  bool _isRevealed = false;
  int _gradedCount = 0;

  /// File figée au démarrage.
  ///
  /// Sans cela, juger une carte « à revoir » la replacerait aussitôt dans la
  /// liste observée et la session ne se terminerait jamais. On travaille sur
  /// l'instantané, et les cartes ratées sont réinjectées en fin de file.
  List<Flashcard>? _queue;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final queue = _queue ??= List<Flashcard>.from(ref.read(dueCardsProvider));

    if (queue.isEmpty) {
      return _SessionScaffold(
        child: _Finished(gradedCount: _gradedCount, hadNothing: true),
      );
    }
    if (_index >= queue.length) {
      return _SessionScaffold(child: _Finished(gradedCount: _gradedCount));
    }

    final card = queue[_index];
    final preview = SpacedRepetition.preview(card.schedule);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} / ${queue.length}'),
        actions: [
          IconButton(
            tooltip: 'Terminer la session',
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: queue.isEmpty ? 0 : _index / queue.length,
            minHeight: 3,
            backgroundColor: context.cq.beigeDark,
            color: context.cq.vert,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    if (card.isNew)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.cq.vert.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        child:  Text(
                          'Nouvelle carte',
                          style: TextStyle(
                              fontSize: TypeScale.caption,
                              fontWeight: FontWeight.w600,
                              color: context.cq.vertDark),
                        ),
                      ),
                    _Face(
                      label: 'Question',
                      content: card.front,
                      isEmphasised: true,
                    ),
                    const SizedBox(height: 16),
                    // Micro-animation n° 6 : la carte se retourne, le
                    // « moment de vérité » du rappel actif. Une clé par
                    // position dans la file : passer à la carte suivante ne
                    // la retourne pas à l'envers (la réponse suivante ne
                    // doit jamais apparaître, même une frame).
                    FlipReveal(
                      key: ValueKey('carte-$_index'),
                      revealed: _isRevealed,
                      front: _HiddenAnswer(
                        onReveal: () => setState(() => _isRevealed = true),
                      ),
                      back: _Face(label: 'Réponse', content: card.back),
                    ),
                  ],
                ),
              ),
            ),
            if (_isRevealed)
              _GradeBar(
                preview: preview,
                onGrade: (grade) => _grade(card, grade, queue),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _grade(
    Flashcard card,
    ReviewGrade grade,
    List<Flashcard> queue,
  ) async {
    await ref.read(reviewActionsProvider).grade(card, grade);
    if (!mounted) return;

    setState(() {
      _gradedCount++;
      // Une carte ratée revient en fin de session : le CdC vise le rappel
      // actif, pas le simple passage en revue.
      if (grade == ReviewGrade.again) queue.add(card);
      _index++;
      _isRevealed = false;
    });
  }
}

class _SessionScaffold extends StatelessWidget {
  const _SessionScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: SafeArea(child: child),
      );
}

class _Face extends StatelessWidget {
  const _Face({
    required this.label,
    required this.content,
    this.isEmphasised = false,
  });

  final String label;
  final String content;
  final bool isEmphasised;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cq.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: context.cq.beigeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style:  TextStyle(
              fontSize: TypeScale.caption,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: context.cq.textHint,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: isEmphasised ? 19 : 16,
              height: 1.45,
              fontWeight: isEmphasised ? FontWeight.w600 : FontWeight.normal,
              color: context.cq.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenAnswer extends StatelessWidget {
  const _HiddenAnswer({required this.onReveal});

  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: BoxDecoration(
            color: context.cq.beigeDark.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child:  Text(
            'Formule la réponse dans ta tête avant de l\'afficher.\n'
            'C\'est l\'effort de rappel qui ancre la mémoire.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: TypeScale.body, color: context.cq.textMuted, height: 1.45),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onReveal,
            child: const Text('Afficher la réponse'),
          ),
        ),
      ],
    );
  }
}

class _GradeBar extends StatelessWidget {
  const _GradeBar({required this.preview, required this.onGrade});

  final Map<ReviewGrade, int> preview;
  final ValueChanged<ReviewGrade> onGrade;

  static Color _colorFor(BuildContext context, ReviewGrade grade) =>
      switch (grade) {
        ReviewGrade.again => context.cq.errorColor,
        ReviewGrade.hard => context.cq.warning,
        ReviewGrade.good => context.cq.vertDark,
        ReviewGrade.easy => context.cq.vert,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration:  BoxDecoration(
        border: Border(top: BorderSide(color: context.cq.beigeDark)),
      ),
      child: Column(
        children: [
           Text(
            'Sois honnête : c\'est ce qui règle ton planning.',
            style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textHint),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final grade in ReviewGrade.values) ...[
                if (grade != ReviewGrade.values.first)
                  const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: grade.hint,
                    child: OutlinedButton(
                      onPressed: () => onGrade(grade),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _colorFor(context, grade),
                        side: BorderSide(
                            color: _colorFor(context, grade)
                                .withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 58),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            child: Text(
                              grade.label,
                              style: const TextStyle(
                                  fontSize: TypeScale.caption, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // L'effet du jugement est annoncé avant le clic :
                          // l'utilisateur sait ce qu'il déclenche.
                          FittedBox(
                            child: Text(
                              SpacedRepetition.describeInterval(
                                  preview[grade] ?? 0),
                              style:  TextStyle(
                                  fontSize: TypeScale.caption, color: context.cq.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.gradedCount, this.hadNothing = false});

  final int gradedCount;
  final bool hadNothing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hadNothing ? Icons.inbox_outlined : Icons.celebration_outlined,
              size: 48,
              color: hadNothing ? context.cq.textHint : context.cq.vert,
            ),
            const SizedBox(height: 16),
            Text(
              hadNothing ? 'Rien à revoir' : 'Session terminée',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hadNothing
                  ? 'Aucune carte n\'est échue. Reviens quand le planning '
                      'te rappellera.'
                  : '$gradedCount carte${gradedCount > 1 ? 's' : ''} '
                      'travaillée${gradedCount > 1 ? 's' : ''}. '
                      'Le rythme des révisions s\'est ajusté tout seul.',
              textAlign: TextAlign.center,
              style:  TextStyle(
                  color: context.cq.textMuted, fontSize: TypeScale.body, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
