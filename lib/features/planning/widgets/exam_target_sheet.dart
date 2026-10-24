import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/planning_model.dart';
import '../data/planning_repository.dart';
import '../domain/revision_priority.dart';
import '../providers/planning_provider.dart';

/// Nombre décimal saisi librement (« 2,5 » ou « 2.5 »), `null` sinon.
double? parseDecimalInput(String raw) {
  final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  return value == null || !value.isFinite ? null : value;
}

/// Déclaration d'un chapitre à réviser, avec de quoi calculer sa
/// rentabilité : coefficient libre, notes, longueur en pages et en heures,
/// difficulté ressentie.
class ExamTargetSheet extends ConsumerStatefulWidget {
  const ExamTargetSheet({super.key, this.target});

  final ExamTarget? target;

  static Future<ExamTarget?> show(BuildContext context, {ExamTarget? target}) {
    return showModalBottomSheet<ExamTarget>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ExamTargetSheet(target: target),
    );
  }

  @override
  ConsumerState<ExamTargetSheet> createState() => _ExamTargetSheetState();
}

class _ExamTargetSheetState extends ConsumerState<ExamTargetSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _title = TextEditingController(text: widget.target?.title ?? '');
  late final _subject =
      TextEditingController(text: widget.target?.subject ?? '');
  late final _coefficient = TextEditingController(
      text: widget.target == null ? '' : widget.target!.coefficientLabel);
  late final _current = TextEditingController(
      text: widget.target == null
          ? ''
          : formatDecimal(widget.target!.currentGrade));
  late final _reachable = TextEditingController(
      text: widget.target == null
          ? ''
          : formatDecimal(widget.target!.reachableGrade));
  late final _pages = TextEditingController(
      text: widget.target?.lengthPages == null
          ? ''
          : formatDecimal(widget.target!.lengthPages!));
  late final _hours = TextEditingController(
      text: widget.target == null
          ? ''
          : formatDecimal(widget.target!.lengthHours));

  late int _difficulty = widget.target?.difficulty ?? 3;
  late DateTime? _examDate = widget.target?.examDate;

  static const List<String> _difficultyLabels = [
    'Très facile',
    'Facile',
    'Moyenne',
    'Difficile',
    'Très difficile',
  ];

  @override
  void dispose() {
    for (final c in [
      _title,
      _subject,
      _coefficient,
      _current,
      _reachable,
      _pages,
      _hours,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _value(TextEditingController c) => parseDecimalInput(c.text);

  /// Chapitre tel que saisi (aperçu ou enregistrement) ; `null` tant qu'un
  /// champ obligatoire manque.
  ExamTarget? _build({required double? pagesPerHour}) {
    final coefficient = _value(_coefficient);
    final current = _value(_current);
    final reachable = _value(_reachable);
    final pages = _value(_pages);
    var hours = _value(_hours);
    if (coefficient == null || current == null || reachable == null) {
      return null;
    }
    if (hours == null) {
      if (pages == null) return null;
      // Heures non saisies : déduites des pages (vitesse mesurée), sinon une
      // page = 5 minutes, ordre de grandeur d'une lecture de cours active.
      hours = pagesPerHour != null && pagesPerHour > 0
          ? pages / pagesPerHour
          : pages / 12;
    }
    final existing = widget.target;
    final subject = _subject.text.trim();
    return ExamTarget(
      id: existing?.id ?? newPlanningId(),
      userId: existing?.userId ?? '',
      noteId: existing?.noteId,
      title: _title.text.trim(),
      subject: subject.isEmpty ? null : subject,
      examWeight: coefficient,
      currentGrade: current,
      reachableGrade: reachable,
      lengthHours: hours,
      lengthPages: pages,
      difficulty: _difficulty,
      examDate: _examDate,
      createdAt: existing?.createdAt ?? DateTime.now(),
      isSynced: false,
    );
  }

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

  void _submit(double? pagesPerHour) {
    if (!_formKey.currentState!.validate()) return;
    final target = _build(pagesPerHour: pagesPerHour);
    if (target != null) Navigator.pop(context, target);
  }

  // ── Validations ──────────────────────────────────────────────────────

  String? _coefficientRule(String? raw) {
    final v = parseDecimalInput(raw ?? '');
    if (v == null) return 'Saisis le coefficient (ex : 3 ou 2,5).';
    if (v <= 0) return 'Le coefficient doit être positif.';
    return null;
  }

  String? _gradeRule(String? raw) {
    final v = parseDecimalInput(raw ?? '');
    if (v == null) return 'Saisis une note sur 20.';
    if (v < 0 || v > 20) return 'Entre 0 et 20.';
    return null;
  }

  String? _reachableRule(String? raw) {
    final error = _gradeRule(raw);
    if (error != null) return error;
    final current = _value(_current);
    final v = parseDecimalInput(raw ?? '')!;
    if (current != null && v < current) {
      return 'Au moins ta note actuelle (${formatDecimal(current)}).';
    }
    return null;
  }

  String? _lengthRule(String? _) {
    final pages = _value(_pages);
    final hours = _value(_hours);
    if (pages == null && hours == null) {
      return 'Indique la longueur en pages ou en heures.';
    }
    if ((pages != null && pages <= 0) || (hours != null && hours <= 0)) {
      return 'La longueur doit être positive.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final existing = widget.target;
    final pagesPerHour = ref.watch(readingSpeedProvider);
    final preview = _build(pagesPerHour: pagesPerHour);

    Widget number(
      TextEditingController controller,
      String label, {
      String? suffix,
      String? helper,
      FormFieldValidator<String>? validator,
    }) =>
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontFeatures: TypeScale.tabular),
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            helperText: helper,
            helperMaxLines: 2,
          ),
          validator: validator,
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(existing == null ? 'Nouveau chapitre' : 'Modifier',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Space.lg),
                TextFormField(
                  controller: _title,
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
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _subject,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Matière (facultatif)',
                    prefixIcon: Icon(Icons.folder_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: Space.md),
                number(_coefficient, 'Coefficient',
                    helper: 'Libre : 1, 3, 12, 2,5…',
                    validator: _coefficientRule),
                const SizedBox(height: Space.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: number(_current, 'Note actuelle',
                          suffix: '/20', validator: _gradeRule),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: number(_reachable, 'Note atteignable',
                          suffix: '/20', validator: _reachableRule),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: number(_pages, 'Longueur en pages',
                          suffix: 'p.', validator: _lengthRule),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: number(_hours, 'Longueur en heures',
                          suffix: 'h', validator: _lengthRule),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text(
                  pagesPerHour == null
                      ? 'Mesure ta vitesse de lecture (onglet Vitesse) : les '
                          'pages seront converties en temps réel de travail.'
                      : 'Ta vitesse de lecture : '
                          '${formatDecimal(pagesPerHour, maxDigits: 1)} '
                          'pages / h — les pages priment sur les heures.',
                  style: TextStyle(
                      fontSize: TypeScale.caption, color: cq.textMuted),
                ),
                const SizedBox(height: Space.lg),
                Text('Difficulté ressentie',
                    style: TextStyle(
                        fontSize: TypeScale.body, color: cq.textPrimary)),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (var level = 1; level <= 5; level++)
                      ChoiceChip(
                        label: Text('$level · ${_difficultyLabels[level - 1]}'),
                        selected: _difficulty == level,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _difficulty = level),
                      ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                InkWell(
                  onTap: _pickExamDate,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de l\'examen (facultatif)',
                      prefixIcon: const Icon(Icons.event_outlined, size: 20),
                      suffixIcon: _examDate == null
                          ? null
                          : IconButton(
                              tooltip: 'Effacer la date',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _examDate = null),
                            ),
                    ),
                    child: Text(
                      _examDate == null
                          ? 'Non renseignée'
                          : '${_examDate!.day.toString().padLeft(2, '0')}/'
                              '${_examDate!.month.toString().padLeft(2, '0')}/'
                              '${_examDate!.year}',
                      style: TextStyle(
                          fontSize: TypeScale.body, color: cq.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: Space.lg),
                _ProfitPreview(target: preview, pagesPerHour: pagesPerHour),
                const SizedBox(height: Space.lg),
                FilledButton(
                  onPressed: () => _submit(pagesPerHour),
                  child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
                ),
                if (existing != null) ...[
                  const SizedBox(height: Space.sm),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(planningActionsProvider)
                          .deleteExamTarget(existing.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text('Supprimer ce chapitre',
                        style: TextStyle(color: cq.errorColor)),
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

/// Rentabilité estimée, recalculée à chaque saisie : on voit l'effet de ses
/// réponses plutôt que de découvrir un classement opaque.
class _ProfitPreview extends StatelessWidget {
  const _ProfitPreview({required this.target, required this.pagesPerHour});

  final ExamTarget? target;
  final double? pagesPerHour;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final t = target;
    final String text;
    if (t == null) {
      text = 'Coefficient, notes et longueur suffisent à estimer la '
          'rentabilité de ce chapitre.';
    } else {
      final cost = t.costWith(pagesPerHour: pagesPerHour);
      final gap = (t.reachableGrade - t.currentGrade).clamp(0.0, 20.0);
      final time = formatHoursMinutes(Duration(seconds: (cost * 3600).round()));
      text = '+${formatDecimal(gap)} pts × coeff. ${t.coefficientLabel} = '
          '${formatDecimal(t.gainablePoints)} points pondérés pour ~$time '
          '→ ${formatDecimal(RevisionPriority.scoreFor(t, pagesPerHour: pagesPerHour), maxDigits: 1)} '
          'pts / h';
    }
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rentabilité estimée',
              style: TextStyle(
                  fontSize: TypeScale.caption,
                  fontWeight: FontWeight.w600,
                  color: cq.terre)),
          const SizedBox(height: Space.xs),
          Text(text,
              style: TextStyle(
                fontSize: TypeScale.caption,
                color: cq.textPrimary,
                height: TypeScale.bodyHeight,
                fontFeatures: TypeScale.tabular,
              )),
        ],
      ),
    );
  }
}
