import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/planning_model.dart';
import '../data/planning_repository.dart';
import '../domain/goal_feasibility.dart';
import '../providers/planning_provider.dart';
import 'exam_target_sheet.dart' show parseDecimalInput;

/// Sous-questions métacognitives de chaque lettre : elles guident la
/// formulation au lieu de seulement la vérifier.
const Map<SmartCriterion, List<String>> smartQuestions = {
  SmartCriterion.specific: [
    'Quelle notion, quel chapitre exactement ?',
    'Quelle action concrète : lire, rédiger, t’entraîner, mémoriser ?',
    'À quoi reconnaîtras-tu, sans ambiguïté, que c’est fait ?',
  ],
  SmartCriterion.measurable: [
    'Quel chiffre prouvera ton progrès ?',
    'Où en es-tu aujourd’hui (ton point de départ) ?',
    'Quand vas-tu mesurer : après chaque séance, chaque semaine ?',
  ],
  SmartCriterion.achievable: [
    'As-tu déjà réussi quelque chose de comparable ? Qu’est-ce qui avait '
        'marché ?',
    'Quel obstacle prévois-tu, et quelle sera ta parade ?',
    'De combien de temps disposes-tu vraiment chaque jour ?',
  ],
  SmartCriterion.relevant: [
    'Quel examen, quelle compétence cet objectif sert-il ?',
    'Pèse-t-il lourd (coefficient, rentabilité) ou te rassure-t-il '
        'seulement ?',
    'Qu’est-ce que tu ne feras pas pour lui faire de la place ?',
  ],
  SmartCriterion.timeBound: [
    'Pour quand, au plus tard ? Une date, pas « bientôt ».',
    'Quelle étape intermédiaire, et à quelle date ?',
  ],
};

/// Indicateurs chiffrés proposés pour le M : (unité, exemple de cible).
const List<(String, String)> measurableIndicators = [
  ('% de réussite aux quiz', 'Ex : 80 % au quiz de thermo'),
  ('cartes maîtrisées', 'Ex : 150 cartes maîtrisées'),
  ('pages lues', 'Ex : 120 pages lues'),
  ('exercices réussis', 'Ex : 30 exercices réussis'),
  ('fiches rédigées', 'Ex : 8 fiches rédigées'),
  ('heures de travail', 'Ex : 12 heures de travail'),
];

/// Formulaire d'objectif SMART métacognitif.
class SmartGoalSheet extends ConsumerStatefulWidget {
  const SmartGoalSheet({super.key, this.goal});

  final StudyGoal? goal;

  static Future<StudyGoal?> show(BuildContext context, {StudyGoal? goal}) =>
      showModalBottomSheet<StudyGoal>(
        context: context,
        sheetAnimationStyle: Motion.style(context),
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => SmartGoalSheet(goal: goal),
      );

  @override
  ConsumerState<SmartGoalSheet> createState() => _SmartGoalSheetState();
}

class _SmartGoalSheetState extends ConsumerState<SmartGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.goal?.title ?? '');
  late final _subject =
      TextEditingController(text: widget.goal?.subject ?? '');
  late final _metric =
      TextEditingController(text: widget.goal?.metricLabel ?? '');
  late final _target = TextEditingController(
      text: (widget.goal?.targetValue ?? 0) > 0
          ? formatDecimal(widget.goal!.targetValue)
          : '');
  late final _current = TextEditingController(
      text: (widget.goal?.currentValue ?? 0) > 0
          ? formatDecimal(widget.goal!.currentValue)
          : '');
  late final _plan =
      TextEditingController(text: widget.goal?.achievablePlan ?? '');
  late final _relevance =
      TextEditingController(text: widget.goal?.relevance ?? '');
  late DateTime? _deadline = widget.goal?.deadline;

  @override
  void dispose() {
    for (final c in [_title, _subject, _metric, _target, _current, _plan, _relevance]) {
      c.dispose();
    }
    super.dispose();
  }

  StudyGoal get _draft {
    final existing = widget.goal;
    final subject = _subject.text.trim();
    return StudyGoal(
      id: existing?.id ?? newPlanningId(),
      userId: existing?.userId ?? '',
      title: _title.text.trim(),
      subject: subject.isEmpty ? null : subject,
      metricLabel: _metric.text.trim(),
      targetValue: parseDecimalInput(_target.text) ?? 0,
      currentValue: parseDecimalInput(_current.text) ?? 0,
      achievablePlan: _plan.text.trim(),
      relevance: _relevance.text.trim(),
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
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _linkTarget(ExamTarget target) {
    final date = target.examDate;
    final line = 'Sert « ${target.title} » (coeff. ${target.coefficientLabel}'
        '${date == null ? '' : ', examen le ${_date(date)}'}).';
    setState(() {
      final text = _relevance.text.trim();
      _relevance.text = text.isEmpty ? line : '$text\n$line';
      if (_subject.text.trim().isEmpty && target.subject != null) {
        _subject.text = target.subject!;
      }
      // L'échéance la plus naturelle : la veille de l'examen.
      if (_deadline == null && date != null && date.isAfter(DateTime.now())) {
        _deadline = date.subtract(const Duration(days: 1));
      }
    });
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final existing = widget.goal;
    final draft = _draft;
    final satisfied = draft.satisfiedCriteria;
    final estimates = ref.watch(allSpeedEstimatesProvider);
    final feasibility = GoalFeasibility.of(draft, estimates);
    final ranked = ref.watch(rankedTargetsProvider);
    final upcomingExams = [
      for (final entry in ranked)
        if (entry.target.examDate case final date?
            when date.isAfter(DateTime.now()))
          entry.target,
    ];

    Widget field(
      TextEditingController controller,
      String label, {
      String? hint,
      int maxLines = 1,
      bool number = false,
      FormFieldValidator<String>? validator,
      bool autofocus = false,
    }) =>
        TextFormField(
          controller: controller,
          autofocus: autofocus,
          minLines: maxLines > 1 ? 2 : 1,
          maxLines: maxLines,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: number
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
              : null,
          textCapitalization:
              number ? TextCapitalization.none : TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          style: number ? const TextStyle(fontFeatures: TypeScale.tabular) : null,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: validator,
        );

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(existing == null ? 'Nouvel objectif SMART' : 'Modifier',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Space.xs),
                Text(
                  'Réponds aux questions sous chaque lettre : c’est en les '
                  'formulant que l’objectif devient tenable.',
                  style: TextStyle(fontSize: TypeScale.caption, color: cq.textMuted),
                ),
                const SizedBox(height: Space.lg),

                // ── S ──────────────────────────────────────────────────
                _LetterSection(
                  criterion: SmartCriterion.specific,
                  satisfied: satisfied.contains(SmartCriterion.specific),
                  children: [
                    field(_title, 'Objectif précis',
                        hint: 'Ex : Maîtriser les cycles de Carnot (chap. 3)',
                        autofocus: existing == null,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Formule ton objectif.'
                            : null),
                    const SizedBox(height: Space.sm),
                    field(_subject, 'Matière (facultatif)'),
                  ],
                ),

                // ── M ──────────────────────────────────────────────────
                _LetterSection(
                  criterion: SmartCriterion.measurable,
                  satisfied: satisfied.contains(SmartCriterion.measurable),
                  children: [
                    Text('Choisis un indicateur chiffré :',
                        style: TextStyle(
                            fontSize: TypeScale.caption, color: cq.textMuted)),
                    const SizedBox(height: Space.xs),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        for (final (unit, example) in measurableIndicators)
                          Tooltip(
                            message: example,
                            child: ChoiceChip(
                              label: Text(unit),
                              selected: _metric.text.trim() == unit,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _metric.text = unit),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                    field(_metric, 'Indicateur (unité)',
                        hint: 'Ex : cartes maîtrisées'),
                    const SizedBox(height: Space.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: field(_current, 'Point de départ',
                                number: true)),
                        const SizedBox(width: Space.md),
                        Expanded(
                            child: field(_target, 'Cible', number: true)),
                      ],
                    ),
                  ],
                ),

                // ── A ──────────────────────────────────────────────────
                _LetterSection(
                  criterion: SmartCriterion.achievable,
                  satisfied: satisfied.contains(SmartCriterion.achievable),
                  children: [
                    field(_plan, 'Ton plan concret', maxLines: 4,
                        hint: 'Ex : 20 cartes chaque matin avant les cours ; '
                            'si je bloque, je relis la fiche.'),
                    const SizedBox(height: Space.sm),
                    _FeasibilityNote(goal: draft, feasibility: feasibility),
                  ],
                ),

                // ── R ──────────────────────────────────────────────────
                _LetterSection(
                  criterion: SmartCriterion.relevant,
                  satisfied: satisfied.contains(SmartCriterion.relevant),
                  children: [
                    if (ranked.isNotEmpty) ...[
                      Text('Relier à un chapitre (Ordre & rentabilité) :',
                          style: TextStyle(
                              fontSize: TypeScale.caption,
                              color: cq.textMuted)),
                      const SizedBox(height: Space.xs),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.sm,
                        children: [
                          for (final entry in ranked.take(4))
                            ActionChip(
                              avatar: Icon(Icons.trending_up,
                                  size: Sizes.iconSm, color: cq.vertSauge),
                              label: Text(entry.target.title,
                                  overflow: TextOverflow.ellipsis),
                              onPressed: () => _linkTarget(entry.target),
                            ),
                        ],
                      ),
                      const SizedBox(height: Space.md),
                    ],
                    field(_relevance, 'Pourquoi ça compte', maxLines: 4,
                        hint: 'Ex : la thermo pèse coeff. 4 au partiel '
                            'du 12/12.'),
                  ],
                ),

                // ── T ──────────────────────────────────────────────────
                _LetterSection(
                  criterion: SmartCriterion.timeBound,
                  satisfied: satisfied.contains(SmartCriterion.timeBound),
                  children: [
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        for (final target in upcomingExams.take(3))
                          ActionChip(
                            avatar: Icon(Icons.event_outlined,
                                size: Sizes.iconSm, color: cq.terre),
                            label: Text(
                                'Veille de l’examen · ${target.title}',
                                overflow: TextOverflow.ellipsis),
                            onPressed: () => setState(() => _deadline =
                                target.examDate!
                                    .subtract(const Duration(days: 1))),
                          ),
                        for (final (label, days) in const [
                          ('Dans 1 semaine', 7),
                          ('Dans 1 mois', 30),
                        ])
                          ActionChip(
                            label: Text(label),
                            onPressed: () => setState(() => _deadline =
                                DateTime.now().add(Duration(days: days))),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    InkWell(
                      onTap: _pickDeadline,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Échéance',
                          prefixIcon: const Icon(Icons.event_outlined, size: 20),
                          suffixIcon: _deadline == null
                              ? null
                              : IconButton(
                                  tooltip: 'Effacer l’échéance',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () =>
                                      setState(() => _deadline = null),
                                ),
                        ),
                        child: Text(
                          _deadline == null ? 'Non définie' : _date(_deadline!),
                          style: TextStyle(
                              fontSize: TypeScale.body, color: cq.textPrimary),
                        ),
                      ),
                    ),
                    if (draft.requiredPacePerDay case final pace?
                        when pace > 0) ...[
                      const SizedBox(height: Space.sm),
                      Text(
                        'Rythme requis : ${formatDecimal(pace, maxDigits: 1)} '
                        '${draft.metricLabel} par jour '
                        '(${draft.daysRemaining} j restants).',
                        style: TextStyle(
                            fontSize: TypeScale.caption,
                            color: cq.textMuted,
                            fontFeatures: TypeScale.tabular),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Space.lg),
                FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, _draft);
                  },
                  child: Text(existing == null ? 'Créer' : 'Enregistrer'),
                ),
                if (existing != null) ...[
                  const SizedBox(height: Space.sm),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(planningActionsProvider)
                          .deleteGoal(existing.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text('Supprimer cet objectif',
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

/// Une lettre SMART : pastille, critère, sous-questions, puis les champs.
class _LetterSection extends StatelessWidget {
  const _LetterSection({
    required this.criterion,
    required this.satisfied,
    required this.children,
  });

  final SmartCriterion criterion;
  final bool satisfied;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final letter = criterion.letter;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.md),
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
              Container(
                width: Sizes.touchTarget * 0.75,
                height: Sizes.touchTarget * 0.75,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: satisfied ? cq.vertSauge : cq.parchemin,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(
                      color: satisfied ? cq.vertSauge : cq.beigeDark),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontFamily: appSerifFamily,
                    fontSize: TypeScale.title,
                    fontWeight: FontWeight.w600,
                    color: satisfied ? cq.beige : cq.terre,
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(criterion.label,
                        style: TextStyle(
                            fontSize: TypeScale.bodyLarge,
                            fontWeight: FontWeight.w600,
                            color: cq.textPrimary)),
                    Text(criterion.hint,
                        style: TextStyle(
                            fontSize: TypeScale.caption, color: cq.textMuted)),
                  ],
                ),
              ),
              Icon(satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: Sizes.iconMd,
                  color: satisfied ? cq.vertSauge : cq.textHint),
            ],
          ),
          const SizedBox(height: Space.sm),
          for (final question in smartQuestions[criterion]!)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.help_outline,
                        size: Sizes.iconSm, color: cq.vertSauge),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(question,
                        style: TextStyle(
                            fontSize: TypeScale.caption,
                            color: cq.textPrimary,
                            height: TypeScale.bodyHeight)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.sm),
          ...children,
        ],
      ),
    );
  }
}

/// Faisabilité d'après la vitesse de travail mesurée.
class _FeasibilityNote extends StatelessWidget {
  const _FeasibilityNote({required this.goal, required this.feasibility});

  final StudyGoal goal;
  final GoalFeasibility? feasibility;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final f = feasibility;
    final String text;
    var warm = false;
    if (goal.targetValue <= 0 || goal.metricLabel.trim().isEmpty) {
      text = 'Renseigne l’indicateur et la cible (M) : ta vitesse de '
          'travail dira combien de temps cela demande.';
    } else if (f == null) {
      text = 'Aucune vitesse mesurée en « ${goal.metricLabel} ». Mesure une '
          'séance (Ordre & vitesse › Vitesse) pour estimer le temps requis.';
    } else {
      final speed = '${formatDecimal(f.speed.unitsPerHour, maxDigits: 1)} '
          '${f.speed.unit} / h';
      final perDay = f.perDay;
      text = 'D’après ta vitesse ($speed) : ${formatHoursMinutes(f.totalTime)} '
          'pour les ${formatDecimal(f.remainingUnits)} ${goal.metricLabel} '
          'restants'
          '${perDay == null ? '.' : ', soit ${formatHoursMinutes(perDay)} par jour.'}'
          '${f.isStretched ? ' C’est beaucoup : allonge l’échéance ou réduis '
              'la cible.' : ''}';
      warm = f.isStretched;
    }
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.speed_outlined,
              size: Sizes.iconMd, color: warm ? cq.terre : cq.vertSauge),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: TypeScale.caption,
                    color: cq.textPrimary,
                    height: TypeScale.bodyHeight,
                    fontFeatures: TypeScale.tabular)),
          ),
        ],
      ),
    );
  }
}
