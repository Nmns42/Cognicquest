import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../router/app_router.dart';
import '../../notes/providers/note_provider.dart';
import '../domain/quiz_generator.dart';
import '../domain/quiz_loops.dart';
import '../providers/quiz_provider.dart';

/// Quiz génératif : questions à choix multiple tirées des fiches et des
/// cartes, correction immédiate, puis bilan qui relie le quiz au reste
/// (cartes remises à J0 ou créées, titres flous à reprendre en étude
/// guidée).
class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key, this.mode = QuizMode.focus, this.noteId});

  final QuizMode mode;
  final String? noteId;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _index = 0;
  int? _chosen;
  final List<(QuizQuestion, bool)> _answers = [];
  QuizOutcome? _outcome;
  bool _finishing = false;

  late final List<QuizQuestion> _questions = ref.read(
      quizQuestionsProvider((mode: widget.mode, noteId: widget.noteId)));

  void _choose(int option) {
    if (_chosen != null) return;
    final question = _questions[_index];
    final correct = option == question.answerIndex;
    setState(() {
      _chosen = option;
      _answers.add((question, correct));
    });
    ref.read(quizActionsProvider).record(question, correct: correct);
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _chosen = null;
      });
      return;
    }
    setState(() => _finishing = true);
    final outcome = await ref.read(quizActionsProvider).finish(_answers);
    if (mounted) setState(() => _outcome = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode.label;
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const _EmptyQuiz(),
      );
    }
    final outcome = _outcome;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: outcome != null
                ? 1
                : (_index + (_chosen == null ? 0 : 1)) / _questions.length,
            minHeight: 3,
            backgroundColor: context.cq.beigeDark,
            color: context.cq.vertSauge,
          ),
        ),
      ),
      body: SafeArea(
        child: outcome != null
            ? _Summary(outcome: outcome, answers: _answers)
            : _QuestionView(
                index: _index,
                total: _questions.length,
                question: _questions[_index],
                chosen: _chosen,
                busy: _finishing,
                onChoose: _choose,
                onNext: _next,
              ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.index,
    required this.total,
    required this.question,
    required this.chosen,
    required this.busy,
    required this.onChoose,
    required this.onNext,
  });

  final int index;
  final int total;
  final QuizQuestion question;
  final int? chosen;
  final bool busy;
  final ValueChanged<int> onChoose;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final answered = chosen != null;
    final right = answered && chosen == question.answerIndex;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Space.lg, Space.lg, Space.lg, Space.xxl),
      children: [
        Row(
          children: [
            Text(
              '${index + 1} / $total',
              style: TextStyle(
                fontSize: TypeScale.caption,
                fontWeight: FontWeight.w600,
                color: cq.textMuted,
                fontFeatures: TypeScale.tabular,
              ),
            ),
            const SizedBox(width: Space.sm),
            Text('· ${question.kind.label}',
                style: TextStyle(fontSize: TypeScale.caption, color: cq.terre)),
            if (question.heading != null) ...[
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('· ${question.heading}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: TypeScale.caption, color: cq.textMuted)),
              ),
            ],
          ],
        ),
        const SizedBox(height: Space.md),
        Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: Space.lg),
        for (final (i, option) in question.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: _Option(
              text: option,
              state: !answered
                  ? _OptionState.idle
                  : i == question.answerIndex
                      ? _OptionState.right
                      : i == chosen
                          ? _OptionState.wrong
                          : _OptionState.dimmed,
              onTap: () => onChoose(i),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: Space.sm),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: cq.parchemin,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: cq.beigeDark),
            ),
            child: Text(
              right
                  ? 'Bien vu.${question.context == null ? '' : ' ${question.context}'}'
                  : question.kind.fromCard
                      ? 'Réponse : ${question.answer}. La carte revient '
                          'aujourd’hui dans tes révisions (méthode des J).'
                      : 'Réponse : ${question.context ?? question.answer}. '
                          'Une carte sera créée, et '
                          '« ${question.heading ?? 'cette partie'} » '
                          'marquée à reprendre.',
              style: TextStyle(
                fontSize: TypeScale.body,
                color: cq.textPrimary,
                height: TypeScale.bodyHeight,
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: busy ? null : onNext,
            child: Text(index == total - 1 ? 'Voir le bilan' : 'Question suivante'),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, right, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({required this.text, required this.state, required this.onTap});

  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final (background, border, foreground, icon) = switch (state) {
      _OptionState.idle => (cq.cardColor, cq.beigeDark, cq.textPrimary, null),
      _OptionState.right => (
          cq.vertSauge.withValues(alpha: 0.14),
          cq.vertSauge,
          cq.textPrimary,
          Icons.check_circle
        ),
      _OptionState.wrong => (
          cq.terre.withValues(alpha: 0.12),
          cq.terre,
          cq.textPrimary,
          Icons.cancel
        ),
      _OptionState.dimmed => (cq.cardColor, cq.beigeDark, cq.textMuted, null),
    };
    return Semantics(
      button: state == _OptionState.idle,
      label: switch (state) {
        _OptionState.right => 'Bonne réponse : $text',
        _OptionState.wrong => 'Ta réponse, fausse : $text',
        _ => text,
      },
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: state == _OptionState.idle ? onTap : null,
          borderRadius: BorderRadius.circular(Radii.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.md, vertical: Space.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(text,
                        style: TextStyle(
                            fontSize: TypeScale.body, color: foreground)),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: Space.sm),
                    Icon(icon,
                        size: Sizes.iconMd,
                        color: state == _OptionState.right
                            ? cq.vertSauge
                            : cq.terre),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bilan : score, effets sur les cartes, titres flous et suites possibles.
class _Summary extends ConsumerWidget {
  const _Summary({required this.outcome, required this.answers});

  final QuizOutcome outcome;
  final List<(QuizQuestion, bool)> answers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final percent = (outcome.rate * 100).round();
    final fuzzy = outcome.fuzzyHeadings;

    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: Sizes.iconMd, color: cq.vertSauge),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: TypeScale.body, color: cq.textPrimary)),
              ),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.xxl),
      children: [
        Text(
          '${outcome.correct} / ${outcome.total}',
          style: TextStyle(
            fontFamily: appSerifFamily,
            fontSize: TypeScale.display,
            color: cq.textPrimary,
            fontFeatures: TypeScale.tabular,
          ),
        ),
        Text(
          percent >= 80
              ? '$percent % : notions solides. L’approfondissement t’attend.'
              : percent >= 50
                  ? '$percent % : en bonne voie, quelques points à consolider.'
                  : '$percent % : reprends les points flous avant de continuer.',
          style: TextStyle(fontSize: TypeScale.body, color: cq.textMuted),
        ),
        const SizedBox(height: Space.xl),
        if (outcome.cardsToRelearn.isNotEmpty)
          line(Icons.replay_outlined,
              '${outcome.cardsToRelearn.length} carte${outcome.cardsToRelearn.length > 1 ? 's' : ''} '
              'remise${outcome.cardsToRelearn.length > 1 ? 's' : ''} à J0 : '
              'à revoir aujourd’hui (méthode des J).'),
        if (outcome.cardsToCreate.isNotEmpty)
          line(Icons.add_card_outlined,
              '${outcome.cardsToCreate.length} carte${outcome.cardsToCreate.length > 1 ? 's' : ''} '
              'créée${outcome.cardsToCreate.length > 1 ? 's' : ''} '
              'à partir des notions ratées.'),
        if (outcome.cardsToRelearn.isEmpty && outcome.cardsToCreate.isEmpty)
          line(Icons.check_circle_outline,
              'Aucune notion à reprendre : tes cartes gardent leur rythme.'),
        if (fuzzy.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Text('Titres encore flous',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Space.sm),
          for (final MapEntry(key: noteId, value: headings) in fuzzy.entries)
            _FuzzyNote(noteId: noteId, headings: headings),
        ],
        const SizedBox(height: Space.xl),
        if (outcome.cardsToRelearn.isNotEmpty || outcome.cardsToCreate.isNotEmpty)
          FilledButton.icon(
            onPressed: () => context.pushReplacement(AppRoute.reviewSession),
            icon: const Icon(Icons.style_outlined),
            label: const Text('Réviser les cartes maintenant'),
          ),
        const SizedBox(height: Space.sm),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Terminer'),
        ),
      ],
    );
  }
}

class _FuzzyNote extends ConsumerWidget {
  const _FuzzyNote({required this.noteId, required this.headings});

  final String noteId;
  final Set<String> headings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final note = ref.watch(noteByIdProvider(noteId));
    if (note == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: cq.cardColor,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.displayTitle,
              style: TextStyle(
                  fontSize: TypeScale.body,
                  fontWeight: FontWeight.w600,
                  color: cq.textPrimary)),
          const SizedBox(height: Space.xs),
          Text(headings.join(' · '),
              style: TextStyle(fontSize: TypeScale.caption, color: cq.terre)),
          const SizedBox(height: Space.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => context.push(AppRoute.sq3rFor(noteId)),
              icon: const Icon(Icons.school_outlined, size: Sizes.iconSm),
              label: const Text('Reprendre en étude guidée'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQuiz extends StatelessWidget {
  const _EmptyQuiz();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Text(
            'Pas encore assez de matière pour un quiz : ajoute des cartes, '
            'ou des fiches avec des titres, des termes en **gras**, des '
            'définitions « terme : sens », des valeurs chiffrées, des listes, '
            'des tableaux, des flèches « cause → effet » ou des encadrés '
            '« > [!important] ».',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: TypeScale.body, color: context.cq.textMuted),
          ),
        ),
      );
}
