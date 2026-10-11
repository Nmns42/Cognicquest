import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/planning_model.dart';
import '../data/planning_repository.dart';
import '../domain/gantt_timeline.dart';
import '../providers/planning_provider.dart';

/// Création / édition d'une barre du Gantt.
class PlanItemSheet extends ConsumerStatefulWidget {
  const PlanItemSheet({super.key, this.item});

  final PlanItem? item;

  static Future<PlanItem?> show(BuildContext context, {PlanItem? item}) {
    return showModalBottomSheet<PlanItem>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanItemSheet(item: item),
    );
  }

  @override
  ConsumerState<PlanItemSheet> createState() => _PlanItemSheetState();
}

class _PlanItemSheetState extends ConsumerState<PlanItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.item?.title ?? '');
  late final TextEditingController _subjectController =
      TextEditingController(text: widget.item?.subject ?? '');

  late DateTime _start = widget.item?.startDate ?? DateTime.now();
  late DateTime _end =
      widget.item?.endDate ?? DateTime.now().add(const Duration(days: 2));
  late bool _isMilestone = widget.item?.isMilestone ?? false;
  late double _progress = widget.item?.progress ?? 0;
  late String? _dependsOnId = widget.item?.dependsOnId;

  String? _dependencyError;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = picked;
        // Une fin antérieure au début produirait une barre de durée négative.
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked.isBefore(_start) ? _start : picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.item;
    final subject = _subjectController.text.trim();

    Navigator.pop(
      context,
      PlanItem(
        id: existing?.id ?? newPlanningId(),
        userId: existing?.userId ?? '',
        goalId: existing?.goalId,
        taskId: existing?.taskId,
        title: _titleController.text.trim(),
        subject: subject.isEmpty ? null : subject,
        startDate: _start,
        endDate: _isMilestone ? _start : _end,
        progress: _progress,
        isMilestone: _isMilestone,
        dependsOnId: _dependsOnId,
        createdAt: existing?.createdAt ?? DateTime.now(),
        isSynced: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.item;
    final allItems =
        ref.watch(planItemsProvider).valueOrNull ?? const <PlanItem>[];

    // Candidats à la dépendance : tout sauf soi-même et ce qui créerait un
    // cycle. On les filtre en amont plutôt que de refuser après coup.
    final candidates = existing == null
        ? allItems
        : allItems
            .where((i) =>
                i.id != existing.id &&
                !GanttTimeline.wouldCreateCycle(allItems, existing.id, i.id))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration:  BoxDecoration(
          color: context.cq.beige,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(existing == null ? 'Nouvelle étape' : 'Modifier l\'étape',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _titleController,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Intitulé'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Donne un intitulé.'
                      : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Matière (facultatif)',
                    prefixIcon: Icon(Icons.folder_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isMilestone,
                  onChanged: (value) => setState(() => _isMilestone = value),
                  title: const Text('Jalon', style: TextStyle(fontSize: 14)),
                  subtitle:  Text(
                    'Une date sans durée : examen, rendu…',
                    style: TextStyle(fontSize: 12, color: context.cq.textMuted),
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: _isMilestone ? 'Date' : 'Début',
                        date: _start,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    if (!_isMilestone) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateField(
                          label: 'Fin',
                          date: _end,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                     Text('Avancement',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.cq.textPrimary)),
                    const Spacer(),
                    Text('${(_progress * 100).round()} %',
                        style:  TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.cq.vertDark)),
                  ],
                ),
                Slider(
                  value: _progress,
                  divisions: 10,
                  activeColor: context.cq.vert,
                  onChanged: (value) => setState(() => _progress = value),
                ),
                const SizedBox(height: 8),

                if (candidates.isNotEmpty) ...[
                   Text('Dépend de (facultatif)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.cq.textMuted)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _dependsOnId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aucune dépendance',
                            style: TextStyle(fontSize: 13)),
                      ),
                      for (final candidate in candidates)
                        DropdownMenuItem<String?>(
                          value: candidate.id,
                          child: Text(candidate.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _dependsOnId = value;
                      _dependencyError = null;
                    }),
                  ),
                  if (_dependencyError != null) ...[
                    const SizedBox(height: 6),
                    Text(_dependencyError!,
                        style:  TextStyle(
                            fontSize: 12, color: context.cq.errorColor)),
                  ],
                  const SizedBox(height: 18),
                ],

                ElevatedButton(
                  onPressed: _submit,
                  child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
                ),

                if (existing != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(planningActionsProvider)
                          .deletePlanItem(existing.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child:  Text('Supprimer cette étape',
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined, size: 20),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}',
          style:  TextStyle(fontSize: 14, color: context.cq.textPrimary),
        ),
      ),
    );
  }
}
