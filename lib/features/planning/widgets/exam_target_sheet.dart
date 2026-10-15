import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/planning_model.dart';
import '../data/planning_repository.dart';
import '../domain/revision_priority.dart';
import '../providers/planning_provider.dart';
import '../../../core/theme/tokens.dart';

/// Déclaration d'un chapitre à réviser, avec de quoi calculer sa rentabilité.
class ExamTargetSheet extends ConsumerStatefulWidget {
  const ExamTargetSheet({super.key, this.target});

  final ExamTarget? target;

  static Future<ExamTarget?> show(BuildContext context, {ExamTarget? target}) {
    return showModalBottomSheet<ExamTarget>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      builder: (_) => ExamTargetSheet(target: target),
    );
  }

  @override
  ConsumerState<ExamTargetSheet> createState() => _ExamTargetSheetState();
}

class _ExamTargetSheetState extends ConsumerState<ExamTargetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.target?.title ?? '');
  late final TextEditingController _subjectController =
      TextEditingController(text: widget.target?.subject ?? '');

  /// Coefficient de 1 à 10 (une ancienne saisie en points est ramenée dans
  /// ces bornes).
  late double _weight = (widget.target?.coefficient ?? 2)
      .clamp(ExamTarget.minCoefficient, ExamTarget.maxCoefficient)
      .toDouble();
  late double _current = widget.target?.currentGrade ?? 8;
  late double _reachable = widget.target?.reachableGrade ?? 16;
  late double _length = widget.target?.lengthHours ?? 3;
  late int _difficulty = widget.target?.difficulty ?? 3;
  late DateTime? _examDate = widget.target?.examDate;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  /// Aperçu du calcul, mis à jour à chaque réglage : l'utilisateur voit
  /// l'effet de ses réponses plutôt que de découvrir un classement opaque.
  ExamTarget get _preview => ExamTarget(
        id: widget.target?.id ?? 'preview',
        userId: '',
        title: _titleController.text,
        examWeight: _weight,
        currentGrade: _current,
        reachableGrade: _reachable,
        lengthHours: _length,
        difficulty: _difficulty,
        examDate: _examDate,
        createdAt: DateTime.now(),
      );

  Future<void> _pickExamDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: DateTime(now.year + 2),
      helpText: 'Date de l\'examen',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.target;
    final subject = _subjectController.text.trim();

    Navigator.pop(
      context,
      ExamTarget(
        id: existing?.id ?? newPlanningId(),
        userId: existing?.userId ?? '',
        noteId: existing?.noteId,
        title: _titleController.text.trim(),
        subject: subject.isEmpty ? null : subject,
        examWeight: _weight,
        currentGrade: _current,
        reachableGrade: _reachable,
        lengthHours: _length,
        difficulty: _difficulty,
        examDate: _examDate,
        createdAt: existing?.createdAt ?? DateTime.now(),
        isSynced: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.target;
    final preview = _preview;

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
                Text(existing == null ? 'Nouveau chapitre' : 'Modifier',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _titleController,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Chapitre',
                    hintText: 'Ex : Thermodynamique — 2e principe',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Nomme le chapitre.'
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
                const SizedBox(height: 20),

                _Slider(
                  label: 'Coefficient à l\'examen',
                  valueLabel: 'Coeff. ${_weight.toStringAsFixed(0)}',
                  value: _weight,
                  min: ExamTarget.minCoefficient.toDouble(),
                  max: ExamTarget.maxCoefficient.toDouble(),
                  divisions:
                      ExamTarget.maxCoefficient - ExamTarget.minCoefficient,
                  onChanged: (v) => setState(() => _weight = v),
                ),
                _Slider(
                  label: 'Ma note actuelle',
                  valueLabel: '${_current.toStringAsFixed(0)}/20',
                  value: _current,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  onChanged: (v) => setState(() {
                    _current = v;
                    // Une note atteignable inférieure à la note actuelle n'a
                    // pas de sens : on la remonte plutôt que de la refuser.
                    if (_reachable < _current) _reachable = _current;
                  }),
                ),
                _Slider(
                  label: 'Note atteignable',
                  valueLabel: '${_reachable.toStringAsFixed(0)}/20',
                  value: _reachable,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  onChanged: (v) => setState(
                      () => _reachable = v < _current ? _current : v),
                ),
                _Slider(
                  label: 'Longueur du cours',
                  valueLabel: '${_length.toStringAsFixed(1)} h',
                  value: _length,
                  min: 0.5,
                  max: 20,
                  divisions: 39,
                  onChanged: (v) => setState(() => _length = v),
                ),
                _Slider(
                  label: 'Difficulté ressentie',
                  valueLabel: '$_difficulty/5',
                  value: _difficulty.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (v) => setState(() => _difficulty = v.round()),
                ),
                const SizedBox(height: 10),

                InkWell(
                  onTap: _pickExamDate,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de l\'examen (facultatif)',
                      prefixIcon: const Icon(Icons.event_outlined, size: 20),
                      suffixIcon: _examDate == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  setState(() => _examDate = null),
                            ),
                    ),
                    child: Text(
                      _examDate == null
                          ? 'Non renseignée'
                          : '${_examDate!.day.toString().padLeft(2, '0')}/'
                              '${_examDate!.month.toString().padLeft(2, '0')}/'
                              '${_examDate!.year}',
                      style:  TextStyle(
                          fontSize: TypeScale.body, color: context.cq.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cq.vert.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                        color: context.cq.vert.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('Rentabilité estimée',
                          style: TextStyle(
                              fontSize: TypeScale.caption,
                              fontWeight: FontWeight.w600,
                              color: context.cq.vertDark)),
                      const SizedBox(height: 6),
                      Text(
                        '+${(_reachable - _current).toStringAsFixed(0)} pts '
                        '× coeff. ${_weight.toStringAsFixed(0)} = '
                        '${preview.gainablePoints.toStringAsFixed(0)} points '
                        'pondérés pour ~'
                        '${preview.estimatedCost.toStringAsFixed(1)} h '
                        '→ ${RevisionPriority.scoreFor(preview).toStringAsFixed(1)} '
                        'par heure',
                        style:  TextStyle(
                            fontSize: TypeScale.caption,
                            color: context.cq.textPrimary,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

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
                          .deleteExamTarget(existing.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child:  Text('Supprimer ce chapitre',
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

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style:  TextStyle(
                    fontSize: TypeScale.body, color: context.cq.textPrimary)),
            const Spacer(),
            Text(valueLabel,
                style:  TextStyle(
                    fontSize: TypeScale.caption,
                    fontWeight: FontWeight.w700,
                    color: context.cq.vertDark)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: context.cq.vertDark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
