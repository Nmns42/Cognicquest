import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../notes/providers/note_provider.dart';
import '../domain/spaced_repetition.dart';
import '../providers/review_provider.dart';

/// Lecture guidée SQ3R sur une fiche — « outil de lecture guidée avec étapes
/// interactives » (CdC).
class Sq3rPage extends ConsumerStatefulWidget {
  const Sq3rPage({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<Sq3rPage> createState() => _Sq3rPageState();
}

class _Sq3rPageState extends ConsumerState<Sq3rPage> {
  Sq3rSession? _session;
  final _textController = TextEditingController();
  final _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session =
        await ref.read(reviewActionsProvider).sessionForNote(widget.noteId);
    if (!mounted || session == null) return;
    setState(() {
      _session = session;
      _textController.text = _textFor(session, session.currentStep);
    });
  }

  String _textFor(Sq3rSession session, Sq3rStep step) => switch (step) {
        Sq3rStep.survey => session.surveyNotes,
        Sq3rStep.recite => session.reciteNotes,
        Sq3rStep.review => session.reviewNotes,
        _ => '',
      };

  Sq3rSession _withText(Sq3rSession session, Sq3rStep step, String text) =>
      switch (step) {
        Sq3rStep.survey => session.copyWith(surveyNotes: text),
        Sq3rStep.recite => session.copyWith(reciteNotes: text),
        Sq3rStep.review => session.copyWith(reviewNotes: text),
        _ => session,
      };

  Future<void> _goTo(Sq3rStep step) async {
    final session = _session;
    if (session == null) return;

    // On enregistre la saisie de l'étape courante avant de changer d'écran.
    final saved = _withText(session, session.currentStep, _textController.text)
        .copyWith(
      currentStep: step,
      completedAt: step == Sq3rStep.review && session.currentStep.isLast
          ? DateTime.now()
          : null,
    );

    await ref.read(reviewActionsProvider).saveSession(saved);
    if (!mounted) return;

    setState(() {
      _session = saved;
      _textController.text = _textFor(saved, step);
    });
  }

  Future<void> _complete() async {
    final session = _session;
    if (session == null) return;

    final saved = _withText(session, session.currentStep, _textController.text)
        .copyWith(completedAt: DateTime.now());
    await ref.read(reviewActionsProvider).saveSession(saved);
    if (mounted) context.pop();
  }

  void _addQuestion() {
    final session = _session;
    final text = _questionController.text.trim();
    if (session == null || text.isEmpty) return;

    final updated = session.copyWith(questions: [...session.questions, text]);
    _questionController.clear();
    setState(() => _session = updated);
    ref.read(reviewActionsProvider).saveSession(updated);
  }

  void _removeQuestion(int index) {
    final session = _session;
    if (session == null) return;

    final questions = [...session.questions]..removeAt(index);
    final updated = session.copyWith(questions: questions);
    setState(() => _session = updated);
    ref.read(reviewActionsProvider).saveSession(updated);
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(noteByIdProvider(widget.noteId));
    final session = _session;

    if (session == null || note == null) {
      return  Scaffold(
        body: Center(child: CircularProgressIndicator(color: context.cq.vert)),
      );
    }

    final step = session.currentStep;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture guidée'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: session.progress,
            minHeight: 3,
            backgroundColor: context.cq.beigeDark,
            color: context.cq.vert,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepBar(current: step, onSelect: _goTo),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Text(note.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.cq.vert.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: context.cq.vert.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Icon(Icons.lightbulb_outline,
                            size: 17, color: context.cq.vertDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.instruction,
                            style:  TextStyle(
                                fontSize: 13,
                                color: context.cq.vertDark,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (step == Sq3rStep.question)
                    _QuestionsStep(
                      questions: session.questions,
                      controller: _questionController,
                      onAdd: _addQuestion,
                      onRemove: _removeQuestion,
                    )
                  else if (step == Sq3rStep.read)
                    _ReadStep(
                      noteContent: note.content.trim().isEmpty
                          ? note.excerpt
                          : note.content,
                      questions: session.questions,
                    )
                  else
                    TextField(
                      controller: _textController,
                      minLines: 8,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: switch (step) {
                          Sq3rStep.survey =>
                            'De quoi ce texte va-t-il parler ?',
                          Sq3rStep.recite =>
                            'Réponds à tes questions, sans regarder.',
                          _ => 'Que retiens-tu ? Que dois-tu revoir ?',
                        },
                        alignLabelWithHint: true,
                      ),
                    ),

                  if (step == Sq3rStep.recite && session.questions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                     Text('Tes questions',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.cq.textMuted)),
                    const SizedBox(height: 8),
                    for (final question in session.questions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $question',
                            style:  TextStyle(
                                fontSize: 13,
                                color: context.cq.textMuted,
                                height: 1.4)),
                      ),
                  ],
                ],
              ),
            ),
            _NavBar(
              step: step,
              onBack: step.index == 0
                  ? null
                  : () => _goTo(Sq3rStep.fromIndex(step.index - 1)),
              onNext: step.isLast
                  ? _complete
                  : () => _goTo(Sq3rStep.fromIndex(step.index + 1)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current, required this.onSelect});

  final Sq3rStep current;
  final ValueChanged<Sq3rStep> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final step in Sq3rStep.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(step.label, style: const TextStyle(fontSize: 12)),
                selected: step == current,
                onSelected: (_) => onSelect(step),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionsStep extends StatelessWidget {
  const _QuestionsStep({
    required this.questions,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> questions;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onAdd(),
          decoration: InputDecoration(
            hintText: 'Ex : Pourquoi l\'entropie augmente-t-elle ?',
            prefixIcon: const Icon(Icons.help_outline, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'Ajouter la question',
              onPressed: onAdd,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (questions.isEmpty)
           Text(
            'Aucune question pour l\'instant. Transforme chaque titre du '
            'cours en question : c\'est ce qui rend la lecture active.',
            style: TextStyle(
                fontSize: 12, color: context.cq.textHint, height: 1.4),
          )
        else
          for (var i = 0; i < questions.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text(questions[i],
                    style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon:  Icon(Icons.close, size: 16,
                      color: context.cq.textHint),
                  onPressed: () => onRemove(i),
                ),
              ),
            ),
      ],
    );
  }
}

class _ReadStep extends StatelessWidget {
  const _ReadStep({required this.noteContent, required this.questions});

  final String noteContent;
  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (questions.isNotEmpty) ...[
           Text('Garde ces questions en tête',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.cq.textMuted)),
          const SizedBox(height: 8),
          for (final question in questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $question',
                  style:  TextStyle(
                      fontSize: 13, color: context.cq.vertDark, height: 1.4)),
            ),
          const SizedBox(height: 18),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cq.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: context.cq.beigeDark),
          ),
          child: Text(
            noteContent.isEmpty
                ? 'Cette fiche est vide. Ajoute son contenu pour la lire ici.'
                : noteContent,
            style:  TextStyle(
                fontSize: 14, height: 1.55, color: context.cq.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.step, required this.onBack, required this.onNext});

  final Sq3rStep step;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration:  BoxDecoration(
        border: Border(top: BorderSide(color: context.cq.beigeDark)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Précédent'),
              ),
            ),
          if (onBack != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              child: Text(step.isLast ? 'Terminer' : 'Étape suivante'),
            ),
          ),
        ],
      ),
    );
  }
}
