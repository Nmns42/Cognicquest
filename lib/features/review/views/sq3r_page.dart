import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/note_model.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/providers/note_provider.dart';
import '../domain/spaced_repetition.dart';
import '../../quiz/providers/quiz_provider.dart';
import '../providers/review_provider.dart';
import 'explain_page.dart';

/// Les trois temps de l'étude guidée : SQ3R et « Explique-moi » réunis en un
/// seul parcours, court et peu coûteux en énergie.
enum StudyStage {
  preview(
    'Survol & questions',
    'Parcours la fiche en diagonale, puis note 2 ou 3 questions auxquelles '
        'tu veux savoir répondre.',
    Sq3rStep.survey,
  ),
  read(
    'Lecture ciblée',
    'Lis pour répondre à tes questions, pas pour tout retenir. Une ou deux '
        'phrases par réponse suffisent.',
    Sq3rStep.read,
  ),
  explain(
    'Explication',
    'Fiche masquée : explique la notion avec tes mots, comme à un ami. Puis '
        'dis à quel point tu la maîtrises.',
    Sq3rStep.review,
  );

  const StudyStage(this.label, this.instruction, this.step);

  final String label;
  final String instruction;

  /// Étape SQ3R enregistrée (les données restent celles des sessions SQ3R).
  final Sq3rStep step;

  bool get isLast => this == StudyStage.explain;

  static StudyStage of(Sq3rStep step) => switch (step) {
        Sq3rStep.survey || Sq3rStep.question => StudyStage.preview,
        Sq3rStep.read || Sq3rStep.recite => StudyStage.read,
        Sq3rStep.review => StudyStage.explain,
      };
}

/// Titres Markdown d'une fiche, transformés en questions toutes prêtes : un
/// appui suffit à les ajouter (« Qu'est-ce que la glycolyse ? »).
List<String> suggestedQuestions(Note note) {
  final headings = RegExp(r'^#{1,6}\s+(.+)$', multiLine: true)
      .allMatches(note.content)
      .map((m) => m.group(1)!.trim())
      .where((h) => h.isNotEmpty);
  return [
    for (final heading in headings.take(6))
      heading.endsWith('?') ? heading : 'Que faut-il retenir sur « $heading » ?',
  ];
}

/// Étude guidée d'une fiche — « outil de lecture guidée avec étapes
/// interactives » et « expliquer avec ses propres mots » (CdC), réunis.
///
/// 1. Survol & questions clés → 2. Lecture ciblée (une réponse par question)
/// → 3. Explication sans la fiche, avec son niveau de maîtrise. La fin du
/// parcours ouvre la fiche de révision.
class Sq3rPage extends ConsumerStatefulWidget {
  const Sq3rPage({super.key, required this.noteId, this.initialStage});

  final String noteId;

  /// Étape d'ouverture ; à défaut, celle où l'étude s'était arrêtée.
  final StudyStage? initialStage;

  @override
  ConsumerState<Sq3rPage> createState() => _Sq3rPageState();
}

class _Sq3rPageState extends ConsumerState<Sq3rPage> {
  Sq3rSession? _session;
  StudyStage _stage = StudyStage.preview;

  final _survey = TextEditingController();
  final _question = TextEditingController();
  final _explanation = TextEditingController();
  final _toReview = TextEditingController();
  final List<TextEditingController> _answers = [];
  int _confidence = 3;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_survey, _question, _explanation, _toReview, ..._answers]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final session =
        await ref.read(reviewActionsProvider).sessionForNote(widget.noteId);
    if (!mounted || session == null) return;
    setState(() {
      _session = session;
      _stage = widget.initialStage ?? StudyStage.of(session.currentStep);
      _survey.text = session.surveyNotes;
      _toReview.text = session.reviewNotes;
      _syncAnswerFields(session);
    });
  }

  /// Un champ de réponse par question, dans l'ordre.
  void _syncAnswerFields(Sq3rSession session) {
    final answers = session.answers;
    while (_answers.length > answers.length) {
      _answers.removeLast().dispose();
    }
    for (var i = 0; i < answers.length; i++) {
      if (i < _answers.length) continue;
      _answers.add(TextEditingController(text: answers[i]));
    }
  }

  /// Session avec la saisie en cours (survol, réponses, à revoir).
  Sq3rSession _current(Sq3rSession session) => session
      .copyWith(surveyNotes: _survey.text, reviewNotes: _toReview.text)
      .withAnswers([for (final c in _answers) c.text]);

  Future<void> _goTo(StudyStage stage) async {
    final session = _session;
    if (session == null) return;
    final saved = _current(session).copyWith(currentStep: stage.step);
    setState(() {
      _session = saved;
      _stage = stage;
    });
    await ref.read(reviewActionsProvider).saveSession(saved);
  }

  void _addQuestion(String text) {
    final session = _session;
    final question = text.trim();
    if (session == null || question.isEmpty) return;
    if (session.questions.contains(question)) return;
    final updated = _current(session)
        .copyWith(questions: [...session.questions, question]);
    _answers.add(TextEditingController());
    _question.clear();
    setState(() => _session = _current(updated));
    ref.read(reviewActionsProvider).saveSession(_session!);
  }

  void _removeQuestion(int index) {
    final session = _session;
    if (session == null) return;
    final questions = [...session.questions]..removeAt(index);
    _answers.removeAt(index).dispose();
    final updated = _current(session.copyWith(questions: questions));
    setState(() => _session = updated);
    ref.read(reviewActionsProvider).saveSession(updated);
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null || _saving) return;
    setState(() => _saving = true);
    final actions = ref.read(reviewActionsProvider);
    final text = _explanation.text.trim();
    if (text.isNotEmpty) {
      await actions.saveExplanation(Explanation(
        id: LocalFirstNoteRepository.newId(),
        userId: '',
        noteId: widget.noteId,
        content: text,
        confidence: _confidence,
        createdAt: DateTime.now(),
        isSynced: false,
      ));
    }
    await actions.saveSession(_current(session).copyWith(
      currentStep: StudyStage.explain.step,
      completedAt: DateTime.now(),
    ));
    if (!mounted) return;
    // La fiche de révision remplace le parcours : « retour » ramène à
    // l'espace Réviser.
    context.pushReplacement(AppRoute.studySheetFor(widget.noteId));
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(noteByIdProvider(widget.noteId));
    final session = _session;
    if (session == null || note == null) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: context.cq.vertDark)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Étude guidée'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_stage.index + 1) / StudyStage.values.length,
            minHeight: 3,
            backgroundColor: context.cq.beigeDark,
            color: context.cq.vertDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StageBar(current: _stage, onSelect: _goTo),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    Space.xl, Space.xs, Space.xl, Space.xl),
                children: [
                  Text(note.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: Space.sm),
                  Text(_stage.instruction,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: Space.lg),
                  _FuzzyHeadings(
                      headings:
                          ref.watch(fuzzyHeadingsForNoteProvider(widget.noteId))),
                  ...switch (_stage) {
                    StudyStage.preview => _preview(context, note, session),
                    StudyStage.read => _read(context, note, session),
                    StudyStage.explain => _explain(context, session),
                  },
                ],
              ),
            ),
            _NavBar(
              stage: _stage,
              busy: _saving,
              onBack: _stage.index == 0
                  ? null
                  : () => _goTo(StudyStage.values[_stage.index - 1]),
              onNext: _stage.isLast
                  ? _finish
                  : () => _goTo(StudyStage.values[_stage.index + 1]),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _preview(BuildContext context, Note note, Sq3rSession session) {
    final suggestions = [
      for (final q in suggestedQuestions(note))
        if (!session.questions.contains(q)) q,
    ];
    return [
      TextField(
        controller: _survey,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'En une phrase, de quoi parle cette fiche ?',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: Space.xl),
      Text('Questions clés', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: Space.sm),
      TextField(
        controller: _question,
        textInputAction: TextInputAction.done,
        onSubmitted: _addQuestion,
        decoration: InputDecoration(
          hintText: 'Ex : Pourquoi l’entropie augmente-t-elle ?',
          prefixIcon: const Icon(Icons.help_outline, size: Sizes.iconMd),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add, size: Sizes.iconMd),
            tooltip: 'Ajouter la question',
            onPressed: () => _addQuestion(_question.text),
          ),
        ),
      ),
      if (suggestions.isNotEmpty) ...[
        const SizedBox(height: Space.md),
        Text('Tirées des titres de la fiche — un appui pour ajouter :',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final q in suggestions)
              ActionChip(
                avatar: const Icon(Icons.add, size: Sizes.iconSm),
                label: Text(q),
                onPressed: () => _addQuestion(q),
              ),
          ],
        ),
      ],
      const SizedBox(height: Space.md),
      for (var i = 0; i < session.questions.length; i++)
        CqListRow(
          title: session.questions[i],
          leadingIcon: Icons.help_outline,
          trailing: IconButton(
            tooltip: 'Retirer la question',
            icon: Icon(Icons.close, size: Sizes.iconSm,
                color: context.cq.textHint),
            onPressed: () => _removeQuestion(i),
          ),
        ),
    ];
  }

  List<Widget> _read(BuildContext context, Note note, Sq3rSession session) {
    final content = note.content.trim().isEmpty ? note.excerpt : note.content;
    return [
      CqCard(
        child: Text(
          content.isEmpty
              ? 'Cette fiche est vide. Ajoute son contenu pour la lire ici.'
              : content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      const SizedBox(height: Space.xl),
      if (session.questions.isEmpty)
        Text('Pas de question : reviens au survol pour en noter une ou deux.',
            style: Theme.of(context).textTheme.bodySmall)
      else
        for (var i = 0; i < session.questions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.lg),
            child: TextField(
              controller: _answers[i],
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: session.questions[i],
                alignLabelWithHint: true,
              ),
            ),
          ),
      if (session.legacyRecite.isNotEmpty) ...[
        Text('Récitation précédente',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Space.xs),
        Text(session.legacyRecite,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    ];
  }

  List<Widget> _explain(BuildContext context, Sq3rSession session) {
    return [
      if (session.questions.isNotEmpty) ...[
        Text('Pour t’aider, tes questions :',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Space.xs),
        for (final q in session.questions)
          Text('• $q', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Space.lg),
      ],
      TextField(
        controller: _explanation,
        minLines: 6,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Avec tes mots, sans jargon…',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: Space.xl),
      Text('Ta maîtrise', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: Space.sm),
      ConfidencePicker(
        value: _confidence,
        onChanged: (value) => setState(() => _confidence = value),
      ),
      const SizedBox(height: Space.xl),
      TextField(
        controller: _toReview,
        minLines: 1,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'À revoir (facultatif)',
          hintText: 'Ce qui a résisté',
        ),
      ),
    ];
  }
}

/// Titres de la fiche ratés aux quiz : la lecture et l'explication s'y
/// attardent d'abord (boucle quiz → étude guidée).
class _FuzzyHeadings extends StatelessWidget {
  const _FuzzyHeadings({required this.headings});

  final Set<String> headings;

  @override
  Widget build(BuildContext context) {
    if (headings.isEmpty) return const SizedBox.shrink();
    final cq = context.cq;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.lg),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: Sizes.iconMd, color: cq.terre),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À reprendre en priorité (d’après tes quiz)',
                    style: TextStyle(
                        fontSize: TypeScale.caption,
                        fontWeight: FontWeight.w600,
                        color: cq.terre)),
                const SizedBox(height: Space.xs),
                for (final heading in headings)
                  Text('• $heading',
                      style: TextStyle(
                          fontSize: TypeScale.body, color: cq.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageBar extends StatelessWidget {
  const _StageBar({required this.current, required this.onSelect});

  final StudyStage current;
  final ValueChanged<StudyStage> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: Space.xl, vertical: Space.sm),
      child: Row(
        children: [
          for (final stage in StudyStage.values)
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: ChoiceChip(
                label: Text('${stage.index + 1}. ${stage.label}'),
                selected: stage == current,
                onSelected: (_) => onSelect(stage),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.stage,
    required this.busy,
    required this.onBack,
    required this.onNext,
  });

  final StudyStage stage;
  final bool busy;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Space.xl, Space.md, Space.xl, Space.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.cq.beigeDark)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Précédent'),
              ),
            ),
            const SizedBox(width: Space.md),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: busy ? null : onNext,
              child: Text(stage.isLast ? 'Terminer' : 'Étape suivante'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fiche de révision ──────────────────────────────────────────────────────

/// Fiche de révision : tout ce que l'étude guidée a produit sur une fiche,
/// ouvert comme une fiche de cours — propriétés, questions et réponses,
/// explications, maîtrise — et l'accès direct à l'étude ou à la révision.
class StudySheetPage extends ConsumerWidget {
  const StudySheetPage({super.key, required this.noteId});

  final String noteId;

  static const List<String> _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteByIdProvider(noteId));
    final session = ref.watch(studySessionForNoteProvider(noteId));
    final explanations = ref.watch(explanationsForNoteProvider(noteId));
    final cards = ref.watch(cardsForNoteProvider(noteId));
    final text = Theme.of(context).textTheme;

    if (note == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const CqEmptyState(
          icon: Icons.description_outlined,
          message: 'Cette fiche n’existe plus.',
        ),
      );
    }

    final latest = explanations.firstOrNull;
    final dueCards = cards.where((c) => c.isDue).length;
    final answers = session?.answers ?? const <String>[];

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: CqCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                const SizedBox(height: Space.sm),
                ...children,
              ],
            ),
          ),
        );

    Widget property(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: Space.xxxl * 2.5,
                  child: Text(label, style: text.bodySmall)),
              Expanded(child: Text(value, style: text.bodyMedium)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche de révision'),
        actions: [
          IconButton(
            tooltip: 'Ouvrir la fiche de cours',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => context.push('${AppRoute.notes}/$noteId'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.xl, Space.sm, Space.xl, Space.xxxl),
        children: [
          Text(note.displayTitle, style: text.headlineSmall),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilledButton.icon(
                onPressed: () => context.push(AppRoute.sq3rFor(noteId)),
                icon: const Icon(Icons.school_outlined, size: Sizes.iconMd),
                label: Text(session?.isComplete ?? false
                    ? 'Réétudier'
                    : 'Reprendre l’étude'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoute.explainFor(noteId)),
                icon: const Icon(Icons.record_voice_over_outlined,
                    size: Sizes.iconMd),
                label: const Text('Réexpliquer'),
              ),
              if (cards.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AppRoute.reviewSessionFor(noteId)),
                  icon: const Icon(Icons.style_outlined, size: Sizes.iconMd),
                  label: Text('Réviser ses ${cards.length} carte'
                      '${cards.length > 1 ? 's' : ''}'),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          section('Maîtrise', [
            property(
                'Niveau',
                latest == null
                    ? 'Pas encore évalué'
                    : '${latest.confidence}/5 — '
                        '${ConfidencePicker.labels[latest.confidence - 1]}'),
            property('Explications', '${explanations.length}'),
            property(
                'Cartes',
                cards.isEmpty
                    ? 'Aucune'
                    : '${cards.length} dont $dueCards à revoir'),
            if (session != null)
              property(
                  'Étude',
                  session.isComplete
                      ? 'Terminée le ${_date(session.completedAt!)}'
                      : 'En cours : ${StudyStage.of(session.currentStep).label}'),
          ]),
          section('Propriétés', [
            property('Matière', note.subject ?? '—'),
            property('Tags',
                note.tags.isEmpty ? '—' : note.tags.map((t) => '#$t').join(' ')),
            property('Importance',
                NoteImportance.fromLevel(note.importance).label),
            property('Créée le', _date(note.createdAt)),
            property('Modifiée le', _date(note.updatedAt)),
          ]),
          if (session != null && session.surveyNotes.trim().isNotEmpty)
            section('Survol', [Text(session.surveyNotes, style: text.bodyMedium)]),
          if (session != null && session.questions.isNotEmpty)
            section('Questions et réponses', [
              for (var i = 0; i < session.questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.questions[i],
                          style: text.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        answers[i].trim().isEmpty
                            ? 'Pas encore de réponse.'
                            : answers[i],
                        style: answers[i].trim().isEmpty
                            ? text.bodySmall
                            : text.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ]),
          if (explanations.isNotEmpty)
            section('Mon explication', [
              Text(latest!.content, style: text.bodyMedium),
              const SizedBox(height: Space.xs),
              Text('${_date(latest.createdAt)} · maîtrise ${latest.confidence}/5',
                  style: text.bodySmall),
              if (explanations.length > 1)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                      'Explications précédentes (${explanations.length - 1})',
                      style: text.bodySmall),
                  children: [
                    for (final e in explanations.skip(1))
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.content, style: text.bodyMedium),
                            Text(
                                '${_date(e.createdAt)} · maîtrise '
                                '${e.confidence}/5',
                                style: text.bodySmall),
                          ],
                        ),
                      ),
                  ],
                ),
            ]),
          if (session != null && session.reviewNotes.trim().isNotEmpty)
            section('À revoir', [Text(session.reviewNotes, style: text.bodyMedium)]),
        ],
      ),
    );
  }
}
