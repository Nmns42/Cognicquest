import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/planning_model.dart';
import '../data/planning_repository.dart';
import '../providers/planning_provider.dart';
import '../../../core/theme/tokens.dart';

/// Objectifs SMART — « définir des objectifs précis, atteignables et
/// mesurables » (CdC).
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(studyGoalsProvider).valueOrNull ?? const <StudyGoal>[];
    final active = ref.watch(activeGoalsProvider);
    final done = goals.where((g) => g.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs SMART')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          if (goals.isEmpty)
            const _EmptyState()
          else ...[
            if (active.isNotEmpty) ...[
              for (final goal in active) _GoalCard(goal: goal),
            ],
            if (done.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Atteints (${done.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final goal in done) _GoalCard(goal: goal),
            ],
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final draft = await _GoalSheet.show(context);
          if (draft == null) return;
          await ref.read(planningActionsProvider).saveGoal(draft);
        },
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvel objectif',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final StudyGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = goal.requiredPacePerDay;
    final days = goal.daysRemaining;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final draft = await _GoalSheet.show(context, goal: goal);
          if (draft == null) return;
          await ref.read(planningActionsProvider).saveGoal(draft);
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: TypeScale.bodyLarge,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: goal.isCompleted
                            ? context.cq.textMuted
                            : context.cq.textPrimary,
                        decoration:
                            goal.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: context.cq.textMuted,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: goal.isCompleted
                        ? 'Rouvrir l\'objectif'
                        : 'Marquer comme atteint',
                    icon: Icon(
                      goal.isCompleted
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      size: 21,
                      color: goal.isCompleted
                          ? context.cq.vert
                          : context.cq.textHint,
                    ),
                    onPressed: () => ref
                        .read(planningActionsProvider)
                        .toggleGoalCompleted(goal),
                  ),
                ],
              ),

              if (goal.targetValue > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 7,
                    backgroundColor: context.cq.beigeDark,
                    color: goal.isCompleted
                        ? context.cq.textMuted
                        : context.cq.vertDark,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${goal.currentValue.toStringAsFixed(0)} / '
                  '${goal.targetValue.toStringAsFixed(0)} ${goal.metricLabel}',
                  style:  TextStyle(
                      fontSize: TypeScale.caption, color: context.cq.textMuted),
                ),
              ],

              if (!goal.isCompleted && days != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      goal.isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.schedule,
                      size: 14,
                      color: goal.isOverdue
                          ? context.cq.errorColor
                          : context.cq.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        goal.isOverdue
                            ? 'Échéance dépassée de ${-days} j'
                            : (days == 0
                                ? 'Échéance aujourd\'hui'
                                : '$days jour${days > 1 ? 's' : ''} restant'
                                    '${days > 1 ? 's' : ''}'
                                    '${pace != null && pace > 0 ? ' · ${pace.toStringAsFixed(1)} ${goal.metricLabel}/jour' : ''}'),
                        style: TextStyle(
                          fontSize: TypeScale.caption,
                          color: goal.isOverdue
                              ? context.cq.errorColor
                              : context.cq.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (!goal.isFullySmart && !goal.isCompleted) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final criterion in goal.missingCriteria)
                      Tooltip(
                        message: criterion.hint,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.cq.warning
                                .withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          child: Text(
                            criterion.label,
                            style: TextStyle(
                                fontSize: TypeScale.caption, color: context.cq.warning),
                          ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
           Icon(Icons.flag_outlined, size: 48, color: context.cq.textHint),
          const SizedBox(height: 16),
          Text('Aucun objectif',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
           Text(
            '« Travailler les maths » n\'est pas un objectif. '
            '« Faire 20 exercices de dérivées avant le 12 mai » en est un.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.cq.textMuted, fontSize: TypeScale.body, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Saisie d'un objectif, guidée par les cinq critères.
class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({this.goal});

  final StudyGoal? goal;

  static Future<StudyGoal?> show(BuildContext context, {StudyGoal? goal}) {
    return showModalBottomSheet<StudyGoal>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      builder: (_) => _GoalSheet(goal: goal),
    );
  }

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController =
      TextEditingController(text: widget.goal?.title ?? '');
  late final _metricController =
      TextEditingController(text: widget.goal?.metricLabel ?? '');
  late final _targetController = TextEditingController(
      text: (widget.goal?.targetValue ?? 0) > 0
          ? widget.goal!.targetValue.toStringAsFixed(0)
          : '');
  late final _currentController = TextEditingController(
      text: (widget.goal?.currentValue ?? 0) > 0
          ? widget.goal!.currentValue.toStringAsFixed(0)
          : '');
  late final _achievableController =
      TextEditingController(text: widget.goal?.achievablePlan ?? '');
  late final _relevanceController =
      TextEditingController(text: widget.goal?.relevance ?? '');

  late DateTime? _deadline = widget.goal?.deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _metricController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    _achievableController.dispose();
    _relevanceController.dispose();
    super.dispose();
  }

  StudyGoal get _draft {
    final existing = widget.goal;
    return StudyGoal(
      id: existing?.id ?? newPlanningId(),
      userId: existing?.userId ?? '',
      title: _titleController.text.trim(),
      metricLabel: _metricController.text.trim(),
      targetValue:
          double.tryParse(_targetController.text.replaceAll(',', '.')) ?? 0,
      currentValue:
          double.tryParse(_currentController.text.replaceAll(',', '.')) ?? 0,
      achievablePlan: _achievableController.text.trim(),
      relevance: _relevanceController.text.trim(),
      deadline: _deadline,
      createdAt: existing?.createdAt ?? DateTime.now(),
      completedAt: existing?.completedAt,
      isSynced: false,
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: DateTime(now.year + 3),
      helpText: 'Échéance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.goal;
    final draft = _draft;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration:  BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.md)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.cq.beigeDark,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(existing == null ? 'Nouvel objectif' : 'Modifier',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 14),

                // Diagnostic SMART en direct : l'utilisateur voit ce qui
                // manque au lieu d'être bloqué après coup.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final criterion in SmartCriterion.values)
                      _CriterionChip(
                        criterion: criterion,
                        satisfied:
                            draft.satisfiedCriteria.contains(criterion),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _titleController,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'S — Objectif précis',
                    hintText: 'Ex : Faire 20 exercices de dérivées',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Formule ton objectif.'
                      : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _metricController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'M — Unité',
                          hintText: 'exercices',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Cible'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _currentController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Fait'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _achievableController,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'A — Comment tu vas y arriver',
                    hintText: 'Ex : 2 exercices par jour, le matin',
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _relevanceController,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'R — Pourquoi ça compte',
                    hintText: 'Ex : les dérivées pèsent 30 % du partiel',
                  ),
                ),
                const SizedBox(height: 14),

                InkWell(
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'T — Échéance',
                      prefixIcon: const Icon(Icons.event_outlined, size: 20),
                      suffixIcon: _deadline == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _deadline = null),
                            ),
                    ),
                    child: Text(
                      _deadline == null
                          ? 'Non définie'
                          : '${_deadline!.day.toString().padLeft(2, '0')}/'
                              '${_deadline!.month.toString().padLeft(2, '0')}/'
                              '${_deadline!.year}',
                      style:  TextStyle(
                          fontSize: TypeScale.body, color: context.cq.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, _draft);
                  },
                  child: Text(existing == null ? 'Créer' : 'Enregistrer'),
                ),

                if (existing != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(planningActionsProvider)
                          .deleteGoal(existing.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child:  Text('Supprimer cet objectif',
                        style: TextStyle(color: context.cq.errorColor)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CriterionChip extends StatelessWidget {
  const _CriterionChip({required this.criterion, required this.satisfied});

  final SmartCriterion criterion;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: criterion.hint,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: satisfied
              ? context.cq.vert.withValues(alpha: 0.13)
              : context.cq.beigeDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              satisfied ? Icons.check : Icons.remove,
              size: 12,
              color: satisfied ? context.cq.vertDark : context.cq.textHint,
            ),
            const SizedBox(width: 5),
            Text(
              criterion.label,
              style: TextStyle(
                fontSize: TypeScale.caption,
                fontWeight: FontWeight.w600,
                color: satisfied ? context.cq.vertDark : context.cq.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
