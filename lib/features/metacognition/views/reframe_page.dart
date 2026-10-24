import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/metacognition_model.dart';
import '../../kanban/providers/task_provider.dart';
import '../data/metacognition_repository.dart';
import '../domain/reframe_summary.dart';
import '../providers/metacognition_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';

/// Recadrage cognitif — « identifier et transformer les pensées bloquantes
/// (ex : "Je suis nul en maths") en objectifs de croissance » (CdC).
///
/// Le parcours est volontairement séquentiel : nommer la pensée, creuser
/// d'où elle vient (les questions des 5 Pourquoi), repérer le piège, chercher
/// les faits qui la contredisent, puis seulement reformuler en un premier
/// pas. Sauter à la reformulation produit un slogan, pas un recadrage.
class ReframePage extends ConsumerStatefulWidget {
  const ReframePage({super.key});

  @override
  ConsumerState<ReframePage> createState() => _ReframePageState();
}

class _ReframePageState extends ConsumerState<ReframePage> {
  final _thoughtController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _reframedController = TextEditingController();
  final _goalController = TextEditingController();

  /// Réponses aux questions d'exploration (cf. [ReframeDigging]).
  final List<TextEditingController> _digControllers = [
    for (final _ in ReframeDigging.questions) TextEditingController(),
  ];
  BlockerType? _cause;

  CognitiveDistortion? _distortion;
  Reframe? _editing;

  @override
  void dispose() {
    _thoughtController.dispose();
    _evidenceController.dispose();
    _reframedController.dispose();
    _goalController.dispose();
    for (final controller in _digControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _load(Reframe reframe) {
    setState(() {
      _editing = reframe;
      _thoughtController.text = reframe.limitingThought;
      _evidenceController.text = reframe.evidenceAgainst;
      _reframedController.text = reframe.reframedThought;
      _goalController.text = reframe.growthGoal;
      _distortion = reframe.distortion;
      // L'exploration est enregistrée comme une chaîne de « pourquoi » qui
      // partage l'identifiant du recadrage.
      final chains =
          ref.read(whyChainsProvider).valueOrNull ?? const <WhyChain>[];
      final chain = chains.where((c) => c.id == reframe.id).firstOrNull;
      for (var i = 0; i < _digControllers.length; i++) {
        _digControllers[i].text =
            chain != null && i < chain.answers.length ? chain.answers[i] : '';
      }
      _cause = chain?.blockerType;
    });
  }

  void _reset() {
    setState(() {
      _editing = null;
      _thoughtController.clear();
      _evidenceController.clear();
      _reframedController.clear();
      _goalController.clear();
      for (final controller in _digControllers) {
        controller.clear();
      }
      _cause = null;
      _distortion = null;
    });
  }

  Future<void> _save() async {
    final thought = _thoughtController.text.trim();
    if (thought.isEmpty) return;

    final editing = _editing;
    final id = editing?.id ?? newMetacognitionId();
    final createdAt = editing?.createdAt ?? DateTime.now();
    final actions = ref.read(metacognitionActionsProvider);
    final answers = [for (final c in _digControllers) c.text.trim()];
    if (answers.any((a) => a.isNotEmpty) || _cause != null) {
      await actions.saveWhyChain(WhyChain(
        id: id,
        userId: editing?.userId ?? '',
        problem: thought,
        answers: answers,
        // La dernière réponse, la plus profonde, est la cause retenue.
        rootCause: answers.lastWhere((a) => a.isNotEmpty, orElse: () => ''),
        blockerType: _cause,
        actionPlan: _goalController.text.trim(),
        createdAt: createdAt,
        isSynced: false,
      ));
    }
    await actions.saveReframe(
          Reframe(
            id: id,
            userId: editing?.userId ?? '',
            limitingThought: thought,
            distortion: _distortion,
            evidenceAgainst: _evidenceController.text.trim(),
            reframedThought: _reframedController.text.trim(),
            growthGoal: _goalController.text.trim(),
            createdAt: createdAt,
            isSynced: false,
          ),
        );

    if (!mounted) return;
    _reset();
    ScaffoldMessenger.of(context).showSnackBar(
      snackBarAnimationStyle: Motion.style(context),
      const SnackBar(content: Text('Recadrage enregistré.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reframes = ref.watch(reframesProvider).valueOrNull ?? const <Reframe>[];
    // Garde les chaînes de « pourquoi » chargées : rouvrir un recadrage
    // retrouve ses réponses d'exploration.
    ref.watch(whyChainsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recadrage cognitif'),
        actions: [
          if (_editing != null)
            TextButton(onPressed: _reset, child: const Text('Nouveau')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const CqDismissibleBanner(
              bannerId: 'journal.recadrage.aide',
              message: 'Note la pensée qui te bloque, cherche d’où elle '
                  'vient, repère le piège, puis transforme-la en un premier '
                  'pas concret. Cinq minutes suffisent.',
            ),
            const SizedBox(height: Space.lg),
            const _Step(1, 'La pensée qui bloque'),
            const SizedBox(height: 8),
            TextField(
              controller: _thoughtController,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Ex : « Je suis nul en maths »',
              ),
            ),
            const SizedBox(height: 22),

            const _Step(2, 'Creuse : d’où vient cette pensée ?'),
            const SizedBox(height: Space.sm),
            for (final (i, (question, hint)) in ReframeDigging.questions.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: TextField(
                  controller: _digControllers[i],
                  onChanged: (_) => setState(() {}),
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: question,
                    hintText: hint,
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            Text('La vraie cause, c’est plutôt…',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cause in BlockerType.values)
                  ChoiceChip(
                    label: Text(ReframeDigging.causeLabel(cause)),
                    selected: _cause == cause,
                    onSelected: (selected) =>
                        setState(() => _cause = selected ? cause : null),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            const _Step(3, 'Dans quel piège tombe ta pensée ?'),
            const SizedBox(height: Space.sm),
            for (final distortion in CognitiveDistortion.values)
              _TrapOption(
                distortion: distortion,
                selected: _distortion == distortion,
                onTap: () => setState(() => _distortion =
                    _distortion == distortion ? null : distortion),
              ),
            const SizedBox(height: 22),

            const _Step(4, 'Qu\'est-ce qui contredit cette pensée ?'),
            const SizedBox(height: 4),
            Text(
              _distortion?.challenge ??
                  'Des faits, pas des encouragements : une note correcte, un '
                      'exercice réussi, un progrès mesurable.',
              style: TextStyle(
                  fontSize: TypeScale.caption, color: context.cq.textMuted, height: 1.4),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _evidenceController,
              onChanged: (_) => setState(() {}),
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex : « J\'ai eu 14 au dernier contrôle de géométrie »',
              ),
            ),
            const SizedBox(height: 22),

            const _Step(5, 'Reformule, sans te mentir'),
            const SizedBox(height: 8),
            TextField(
              controller: _reframedController,
              onChanged: (_) => setState(() {}),
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Ex : « Les limites me résistent, le reste du chapitre non »',
              ),
            ),
            const SizedBox(height: 22),

            const _Step(6, 'Ton premier pas'),
            const SizedBox(height: 4),
            Text(
              'Une action concrète qui s’attaque à la cause, pas ce que tu '
              'voudrais être.',
              style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _goalController,
              onChanged: (_) => setState(() {}),
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex : « Refaire 3 exercices corrigés sur les limites '
                    'demain matin »',
              ),
            ),
            const SizedBox(height: 26),

            // Bilan personnalisé : il se construit au fil des réponses.
            _SummaryCard(
              summary: ReframeSummary.build(
                thought: _thoughtController.text,
                digging: [for (final c in _digControllers) c.text],
                cause: _cause,
                distortion: _distortion,
                evidence: _evidenceController.text,
                reframed: _reframedController.text,
                goal: _goalController.text,
              ),
            ),
            const SizedBox(height: Space.lg),

            ElevatedButton(
              onPressed:
                  _thoughtController.text.trim().isEmpty ? null : _save,
              child: Text(_editing == null ? 'Enregistrer' : 'Mettre à jour'),
            ),

            if (reframes.isNotEmpty) ...[
              const SizedBox(height: 30),
               Text(
                'Tes recadrages',
                style: TextStyle(
                  fontSize: TypeScale.body,
                  fontWeight: FontWeight.w600,
                  color: context.cq.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              for (final reframe in reframes)
                _ReframeRow(reframe: reframe, onTap: () => _load(reframe)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un piège de pensée, dit en mots simples, avec sa phrase typique.
class _TrapOption extends StatelessWidget {
  const _TrapOption({
    required this.distortion,
    required this.selected,
    required this.onTap,
  });

  final CognitiveDistortion distortion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? cq.vertSauge.withValues(alpha: 0.1) : cq.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            side: BorderSide(color: selected ? cq.vertSauge : cq.beigeDark),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.md),
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: Sizes.iconMd,
                    color: selected ? cq.vertDark : cq.textHint,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(distortion.label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(distortion.example,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bilan du recadrage : synthèse, reformulation, plan d'action relié aux
/// outils de CognicQuest, et premier pas ajoutable aux tâches.
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.summary});

  final ReframeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (summary.isEmpty) return const SizedBox.shrink();
    final cq = context.cq;
    final percent = (summary.completeness * 100).round();
    final firstStep = summary.firstStep;

    TextStyle body() => TextStyle(
        fontSize: TypeScale.body,
        color: cq.textPrimary,
        height: TypeScale.bodyHeight);

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: cq.cardColor,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Ton bilan',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Text(
                '$percent % complété',
                style: TextStyle(
                  fontSize: TypeScale.caption,
                  color: cq.textMuted,
                  fontFeatures: TypeScale.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.xs),
            child: LinearProgressIndicator(
              value: summary.completeness,
              minHeight: Space.xs,
              backgroundColor: cq.beigeDark,
              color: cq.vertSauge,
            ),
          ),
          const SizedBox(height: Space.md),
          for (final line in summary.synthesis)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Text(line, style: body()),
            ),
          if (summary.reframed != null) ...[
            const SizedBox(height: Space.sm),
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: cq.parchemin,
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border(left: BorderSide(color: cq.vertSauge, width: 3)),
              ),
              child: Text(
                '« ${summary.reframed} »',
                style: TextStyle(
                  fontFamily: appSerifFamily,
                  fontSize: TypeScale.bodyLarge,
                  color: cq.textPrimary,
                  height: TypeScale.bodyHeight,
                ),
              ),
            ),
          ],
          if (summary.plan.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text('Ton plan d’action',
                style: TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: cq.terre)),
            const SizedBox(height: Space.sm),
            for (final (i, step) in summary.plan.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: Space.xl,
                      child: Text('${i + 1}.',
                          style: TextStyle(
                              fontSize: TypeScale.body,
                              fontWeight: FontWeight.w600,
                              color: cq.vertSauge,
                              fontFeatures: TypeScale.tabular)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.text, style: body()),
                          if (step.route != null && step.actionLabel != null)
                            TextButton(
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero),
                              onPressed: () => context.push(step.route!),
                              child: Text(step.actionLabel!),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (firstStep != null) ...[
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(taskProvider.notifier).addTask(
                      firstStep,
                      description: 'Premier pas issu d’un recadrage cognitif.',
                      isImportant: true,
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  snackBarAnimationStyle: Motion.style(context),
                  const SnackBar(
                      content: Text('Premier pas ajouté à tes tâches.')),
                );
              },
              icon: const Icon(Icons.add_task, size: Sizes.iconMd),
              label: const Text('Ajouter mon premier pas aux tâches'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.label);

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration:  BoxDecoration(
            color: context.cq.vertSauge,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: TextStyle(
                color: context.cq.beige, fontSize: TypeScale.caption, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style:  TextStyle(
              fontSize: TypeScale.body,
              fontWeight: FontWeight.w600,
              color: context.cq.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReframeRow extends StatelessWidget {
  const _ReframeRow({required this.reframe, required this.onTap});

  final Reframe reframe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '« ${reframe.limitingThought} »',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                        fontSize: TypeScale.body,
                        fontStyle: FontStyle.italic,
                        color: context.cq.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (!reframe.isComplete)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.cq.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Text(
                        'à finir',
                        style: TextStyle(
                            fontSize: TypeScale.caption, color: context.cq.warning),
                      ),
                    ),
                ],
              ),
              if (reframe.reframedThought.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Icon(Icons.arrow_forward,
                        size: 14, color: context.cq.vertDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reframe.reframedThought,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:  TextStyle(
                            fontSize: TypeScale.body,
                            color: context.cq.textPrimary,
                            height: 1.35),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
