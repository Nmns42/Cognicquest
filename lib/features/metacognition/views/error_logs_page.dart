import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/metacognition_model.dart';
import '../data/metacognition_repository.dart';
import '../domain/metacognition_insights.dart';
import '../providers/metacognition_provider.dart';
import '../../../core/theme/tokens.dart';

/// Analyse des erreurs — « regroupe les types d'erreurs commises par l'élève
/// (erreurs d'inattention vs erreurs de compréhension) » (CdC).
class ErrorLogsPage extends ConsumerStatefulWidget {
  const ErrorLogsPage({super.key});

  @override
  ConsumerState<ErrorLogsPage> createState() => _ErrorLogsPageState();
}

class _ErrorLogsPageState extends ConsumerState<ErrorLogsPage> {
  String? _subjectFilter;

  Future<void> _addError() async {
    await showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      builder: (_) => const _ErrorEditorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errors = ref.watch(errorLogsProvider).valueOrNull ?? const <ErrorLog>[];
    final subjects = ref.watch(errorSubjectsProvider);

    final pattern = _subjectFilter == null
        ? ref.watch(errorPatternProvider)
        : ref.watch(errorPatternBySubjectProvider(_subjectFilter!));

    final visible = _subjectFilter == null
        ? errors
        : errors.where((e) => e.subject == _subjectFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Analyse des erreurs')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          if (errors.isEmpty)
            const _EmptyState()
          else ...[
            if (subjects.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Toutes',
                        style: TextStyle(fontSize: TypeScale.caption)),
                    selected: _subjectFilter == null,
                    onSelected: (_) => setState(() => _subjectFilter = null),
                  ),
                  for (final subject in subjects)
                    FilterChip(
                      label:
                          Text(subject, style: const TextStyle(fontSize: TypeScale.caption)),
                      selected: _subjectFilter == subject,
                      onSelected: (selected) => setState(
                          () => _subjectFilter = selected ? subject : null),
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            _PatternBreakdown(pattern: pattern),
            const SizedBox(height: 22),

            Text(
              '${visible.length} erreur${visible.length > 1 ? 's' : ''} '
              'consignée${visible.length > 1 ? 's' : ''}',
              style:  TextStyle(
                fontSize: TypeScale.body,
                fontWeight: FontWeight.w600,
                color: context.cq.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            for (final error in visible) _ErrorRow(error: error),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addError,
        backgroundColor: context.cq.vert,
        tooltip: 'Consigner une erreur',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

/// Répartition par type d'erreur.
///
/// Barres horizontales et non un camembert : comparer cinq parts proches est
/// beaucoup plus facile en longueur qu'en angle. Série unique → une seule
/// teinte, avec les valeurs affichées et non réservées au survol.
class _PatternBreakdown extends StatelessWidget {
  const _PatternBreakdown({required this.pattern});

  final ErrorPattern pattern;

  @override
  Widget build(BuildContext context) {
    if (pattern.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Répartition de tes erreurs',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            for (final type in ErrorType.values)
              if ((pattern.countsByType[type] ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TypeBar(
                    type: type,
                    count: pattern.countsByType[type]!,
                    share: pattern.shareOf(type),
                    isDominant: pattern.dominant == type,
                  ),
                ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cq.vert.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Icon(Icons.lightbulb_outline,
                      size: 16, color: context.cq.vertDark),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      pattern.summary,
                      style:  TextStyle(
                          fontSize: TypeScale.caption,
                          color: context.cq.vertDark,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBar extends StatelessWidget {
  const _TypeBar({
    required this.type,
    required this.count,
    required this.share,
    required this.isDominant,
  });

  final ErrorType type;
  final int count;
  final double share;
  final bool isDominant;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${type.label} : $count erreur${count > 1 ? 's' : ''}, '
          '${(share * 100).round()} %',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: TypeScale.caption,
                    fontWeight:
                        isDominant ? FontWeight.w700 : FontWeight.w500,
                    color: context.cq.textPrimary,
                  ),
                ),
              ),
              Text(
                '$count · ${(share * 100).round()} %',
                style:  TextStyle(
                    fontSize: TypeScale.caption, color: context.cq.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: share),
              duration: Motion.duration(context, const Duration(milliseconds: 420)),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: context.cq.beigeDark,
                color: context.cq.vertDark
                    .withValues(alpha: isDominant ? 1 : 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.error});

  final ErrorLog error;

  static const List<String> _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  @override
  Widget build(BuildContext context) {
    final date = error.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.cq.vertDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    error.errorType.label,
                    style:  TextStyle(
                        fontSize: TypeScale.caption,
                        fontWeight: FontWeight.w600,
                        color: context.cq.vertDark),
                  ),
                ),
                if (error.subject != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      error.subject!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                          fontSize: TypeScale.caption, color: context.cq.textHint),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${date.day} ${_months[date.month - 1]}',
                  style:  TextStyle(
                      fontSize: TypeScale.caption, color: context.cq.textHint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error.description,
              style:  TextStyle(
                  fontSize: TypeScale.body, color: context.cq.textPrimary, height: 1.4),
            ),
            if (error.isCorrected) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Icon(Icons.check_circle_outline,
                      size: 14, color: context.cq.vertDark),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      error.correction,
                      style:  TextStyle(
                          fontSize: TypeScale.caption,
                          color: context.cq.textMuted,
                          height: 1.35),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
           Icon(Icons.rule_outlined, size: 48, color: context.cq.textHint),
          const SizedBox(height: 16),
          Text('Aucune erreur consignée',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
           Text(
            'Consigner une erreur n\'est pas s\'auto-flageller : c\'est le '
            'seul moyen de voir si tu rates par inattention ou par '
            'incompréhension. Les deux appellent des réponses opposées.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.cq.textMuted, fontSize: TypeScale.body, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Saisie d'une erreur.
class _ErrorEditorSheet extends ConsumerStatefulWidget {
  const _ErrorEditorSheet();

  @override
  ConsumerState<_ErrorEditorSheet> createState() => _ErrorEditorSheetState();
}

class _ErrorEditorSheetState extends ConsumerState<_ErrorEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _correctionController = TextEditingController();

  ErrorType _type = ErrorType.comprehension;

  @override
  void dispose() {
    _descriptionController.dispose();
    _subjectController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final subject = _subjectController.text.trim();
    await ref.read(metacognitionActionsProvider).saveError(
          ErrorLog(
            id: newMetacognitionId(),
            userId: '',
            subject: subject.isEmpty ? null : subject,
            description: _descriptionController.text.trim(),
            errorType: _type,
            correction: _correctionController.text.trim(),
            createdAt: DateTime.now(),
            isSynced: false,
          ),
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
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
                Text('Consigner une erreur',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _descriptionController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Qu\'est-ce qui a été raté ?',
                    hintText: 'Ex : signe oublié dans le développement',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Décris l\'erreur.'
                      : null,
                ),
                const SizedBox(height: 16),

                 Text(
                  'De quel type ?',
                  style: TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: context.cq.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                for (final type in ErrorType.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => setState(() => _type = type),
                      borderRadius: BorderRadius.circular(Radii.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == type
                              ? context.cq.vert.withValues(alpha: 0.1)
                              : context.cq.cardColor,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(
                            color: _type == type
                                ? context.cq.vert
                                : context.cq.beigeDark,
                            width: _type == type ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _type == type
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 17,
                              color: _type == type
                                  ? context.cq.vert
                                  : context.cq.textHint,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(type.label,
                                      style:  TextStyle(
                                          fontSize: TypeScale.body,
                                          fontWeight: FontWeight.w600,
                                          color: context.cq.textPrimary)),
                                  const SizedBox(height: 1),
                                  Text(type.description,
                                      style:  TextStyle(
                                          fontSize: TypeScale.caption,
                                          color: context.cq.textMuted,
                                          height: 1.3)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: context.cq.beigeDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    _type.remedy,
                    style:  TextStyle(
                        fontSize: TypeScale.caption, color: context.cq.textMuted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Matière (facultatif)',
                    prefixIcon: Icon(Icons.folder_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _correctionController,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Correction (facultatif)',
                    hintText: 'Ce qu\'il fallait faire',
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
