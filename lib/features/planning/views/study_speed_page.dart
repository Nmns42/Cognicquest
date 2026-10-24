import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/planning_model.dart';
import '../data/planning_repository.dart';
import '../domain/study_speed.dart';
import '../providers/planning_provider.dart';
import '../widgets/exam_target_sheet.dart' show parseDecimalInput;

/// Volet « Vitesse de travail » du module Ordre & vitesse : mesures par
/// activité et unité, estimations, pronostics en « X h Y min ».
class StudySpeedView extends ConsumerStatefulWidget {
  const StudySpeedView({super.key});

  /// Ouvre la saisie d'une mesure.
  static Future<void> addSample(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        sheetAnimationStyle: Motion.style(context),
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const SpeedSampleSheet(),
      );

  @override
  ConsumerState<StudySpeedView> createState() => _StudySpeedViewState();
}

class _StudySpeedViewState extends ConsumerState<StudySpeedView> {
  final _forecastController = TextEditingController(text: '30');

  @override
  void dispose() {
    _forecastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final estimates = ref.watch(speedEstimatesProvider);
    final subjects = ref.watch(speedSubjectsProvider);
    final selected = ref.watch(speedSubjectProvider);
    final forecastUnits = parseDecimalInput(_forecastController.text) ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Space.lg, Space.md, Space.lg, Space.xxxl * 2),
      children: [
        Text(
          'Mesure quelques séances, et CognicQuest saura estimer le temps '
          'qu\'il te faut — au lieu de te fier à une intuition qui se '
          'trompe presque toujours.',
          style: TextStyle(
              fontSize: TypeScale.caption,
              color: cq.textMuted,
              height: TypeScale.bodyHeight),
        ),
        const SizedBox(height: Space.lg),
        if (subjects.isNotEmpty) ...[
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              ChoiceChip(
                label: const Text('Toutes matières'),
                selected: selected == null,
                showCheckmark: false,
                onSelected: (_) =>
                    ref.read(speedSubjectProvider.notifier).state = null,
              ),
              for (final subject in subjects)
                ChoiceChip(
                  label: Text(subject),
                  selected: selected == subject,
                  showCheckmark: false,
                  onSelected: (isSelected) => ref
                      .read(speedSubjectProvider.notifier)
                      .state = isSelected ? subject : null,
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
        ],
        if (estimates.isEmpty)
          const _EmptyState()
        else ...[
          TextField(
            controller: _forecastController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFeatures: TypeScale.tabular),
            decoration: const InputDecoration(
              labelText: 'Combien en as-tu à traiter ?',
              helperText: 'Dans l\'unité de chaque estimation ci-dessous',
              prefixIcon: Icon(Icons.calculate_outlined, size: 20),
            ),
          ),
          const SizedBox(height: Space.lg),
          for (final estimate in estimates)
            _EstimateCard(estimate: estimate, forecastUnits: forecastUnits),
        ],
      ],
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.estimate, required this.forecastUnits});

  final SpeedEstimate estimate;
  final double forecastUnits;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final forecast = estimate.forecast(forecastUnits);
    // Temps pour une unité : plus parlant que « 0,4 mot / s ».
    final perUnit = estimate.forecast(1);

    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.lg),
      decoration:
          context.chrome.decoration(color: cq.cardColor, radius: Radii.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${estimate.activity.label} · ${estimate.unit}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                estimate.confidenceLabel,
                style: TextStyle(
                  fontSize: TypeScale.caption,
                  fontWeight: FontWeight.w600,
                  color: estimate.isReliable ? cq.vertSauge : cq.terre,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: formatDecimal(estimate.unitsPerHour, maxDigits: 1),
                style: TextStyle(
                  fontSize: TypeScale.headline,
                  fontWeight: FontWeight.w700,
                  color: cq.textPrimary,
                  fontFeatures: TypeScale.tabular,
                ),
              ),
              TextSpan(
                text: '  ${estimate.unit} / heure'
                    '${perUnit == null ? '' : ' · ${_perUnitLabel(perUnit, estimate.unit)}'}',
                style:
                    TextStyle(fontSize: TypeScale.caption, color: cq.textMuted),
              ),
            ]),
          ),
          if (forecast != null) ...[
            const SizedBox(height: Space.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: cq.parchemin,
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(color: cq.beigeDark),
              ),
              child: Text(
                '${formatDecimal(forecastUnits)} ${estimate.unit} '
                '→ environ ${formatHoursMinutes(forecast)}'
                '${estimate.isReliable ? '' : ' (à confirmer)'}',
                style: TextStyle(
                  fontSize: TypeScale.body,
                  color: cq.textPrimary,
                  fontFeatures: TypeScale.tabular,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// « 3 min par page », « 25 s par mot ».
  static String _perUnitLabel(Duration perUnit, String unit) {
    final singular =
        unit == 'quiz' ? 'quiz' : unit.replaceFirst(RegExp(r's$'), '');
    final seconds = perUnit.inSeconds;
    if (seconds < 60) return '$seconds s par $singular';
    return '${formatHoursMinutes(perUnit)} par $singular';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xxl),
      child: Column(
        children: [
          Icon(Icons.speed_outlined,
              size: Sizes.iconXl, color: context.cq.textHint),
          const SizedBox(height: Space.lg),
          Text('Aucune mesure', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Space.sm),
          Text(
            'Après une séance, note ce que tu as traité et en combien de '
            'temps. Trois mesures suffisent pour une estimation fiable.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.cq.textMuted,
                fontSize: TypeScale.body,
                height: TypeScale.bodyHeight),
          ),
        ],
      ),
    );
  }
}

/// Saisie d'une mesure : activité, quantité et unité, durée au cadran
/// (H:M:S pour la lecture, H:M sinon).
class SpeedSampleSheet extends ConsumerStatefulWidget {
  const SpeedSampleSheet({super.key});

  @override
  ConsumerState<SpeedSampleSheet> createState() => _SpeedSampleSheetState();
}

class _SpeedSampleSheetState extends ConsumerState<SpeedSampleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController();
  final _subjectController = TextEditingController();

  StudyActivity _activity = StudyActivity.reading;
  String _unit = StudyActivity.reading.unit;
  Duration _duration = const Duration(minutes: 30);
  String? _durationError;

  @override
  void dispose() {
    _unitsController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _selectActivity(StudyActivity activity) => setState(() {
        _activity = activity;
        _unit = activity.units.first;
        // Le cadran H:M ignore les secondes.
        if (!activity.timedToTheSecond) {
          _duration = Duration(minutes: _duration.inMinutes);
        }
      });

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _durationError =
        _duration.inSeconds <= 0 ? 'Règle une durée sur le cadran.' : null);
    if (!formOk || _durationError != null) return;

    final subject = _subjectController.text.trim();
    await ref.read(planningActionsProvider).saveSpeedSample(
          SpeedSample(
            id: newPlanningId(),
            userId: '',
            activity: _activity,
            unit: _unit,
            subject: subject.isEmpty ? null : subject,
            units: parseDecimalInput(_unitsController.text)!,
            durationSeconds: _duration.inSeconds,
            createdAt: DateTime.now(),
            isSynced: false,
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final units = _activity.units;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nouvelle mesure',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final activity in StudyActivity.values)
                    ChoiceChip(
                      label: Text(activity.label),
                      selected: activity == _activity,
                      showCheckmark: false,
                      onSelected: (_) => _selectActivity(activity),
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitsController,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: const TextStyle(fontFeatures: TypeScale.tabular),
                      decoration: InputDecoration(
                        labelText: 'Quantité',
                        suffixText: units.length == 1 ? _unit : null,
                      ),
                      validator: (value) {
                        final v = parseDecimalInput(value ?? '');
                        return v == null || v <= 0
                            ? 'Un nombre supérieur à 0.'
                            : null;
                      },
                    ),
                  ),
                  if (units.length > 1) ...[
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // Clé : l'unité change avec l'activité.
                        key: ValueKey(_activity),
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: 'Unité'),
                        items: [
                          for (final unit in units)
                            DropdownMenuItem(
                              value: unit,
                              child: Text(
                                  '${unit[0].toUpperCase()}${unit.substring(1)}'),
                            ),
                        ],
                        onChanged: (unit) =>
                            setState(() => _unit = unit ?? _unit),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Space.lg),
              Text(
                _activity.timedToTheSecond
                    ? 'Durée (heures : minutes : secondes)'
                    : 'Durée (heures : minutes)',
                style:
                    TextStyle(fontSize: TypeScale.body, color: cq.textPrimary),
              ),
              const SizedBox(height: Space.sm),
              DurationDial(
                key: ValueKey(_activity.timedToTheSecond),
                value: _duration,
                withSeconds: _activity.timedToTheSecond,
                onChanged: (d) => setState(() {
                  _duration = d;
                  _durationError = null;
                }),
              ),
              const SizedBox(height: Space.xs),
              Text(
                _durationError ?? '= ${formatHoursMinutes(_duration)}',
                style: TextStyle(
                  fontSize: TypeScale.caption,
                  color: _durationError == null ? cq.textMuted : cq.errorColor,
                  fontFeatures: TypeScale.tabular,
                ),
              ),
              const SizedBox(height: Space.lg),
              TextFormField(
                controller: _subjectController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Matière (facultatif)',
                  prefixIcon: Icon(Icons.folder_outlined, size: 20),
                ),
              ),
              const SizedBox(height: Space.xl),
              FilledButton(
                  onPressed: _submit, child: const Text('Enregistrer')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cadran de durée à roues (heures, minutes, secondes facultatives), aux
/// couleurs du thème clair comme sombre. Une roue par unité, libellé fixe à
/// côté : le minuteur Cupertino plaçait ses libellés d'après la police
/// système d'iOS, et les chiffres de l'app les chevauchaient.
class DurationDial extends StatelessWidget {
  const DurationDial({
    super.key,
    required this.value,
    required this.onChanged,
    this.withSeconds = true,
  });

  final Duration value;
  final ValueChanged<Duration> onChanged;
  final bool withSeconds;

  static const double _itemExtent = 36;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final hours = value.inHours.clamp(0, 23);
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);

    Widget wheel({
      required String label,
      required String semantic,
      required int count,
      required int selected,
      required ValueChanged<int> onSelected,
    }) =>
        Expanded(
          child: Semantics(
            label: semantic,
            value: '$selected',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: Space.xxxl + Space.md,
                  child: CupertinoPicker(
                    itemExtent: _itemExtent,
                    scrollController:
                        FixedExtentScrollController(initialItem: selected),
                    selectionOverlay: const SizedBox.shrink(),
                    onSelectedItemChanged: onSelected,
                    children: [
                      for (var i = 0; i < count; i++)
                        Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontFamily: appFontFamily,
                              fontSize: TypeScale.title,
                              color: cq.textPrimary,
                              fontFeatures: TypeScale.tabular,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.xs),
                SizedBox(
                  width: Space.xxl,
                  child: Text(label,
                      style: TextStyle(
                          fontFamily: appFontFamily,
                          fontSize: TypeScale.body,
                          color: cq.textMuted)),
                ),
              ],
            ),
          ),
        );

    return Container(
      height: Sizes.control * 3.5,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bandeau de sélection commun aux roues.
          Container(
            height: _itemExtent,
            decoration: BoxDecoration(
              color: cq.beigeDark,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
          ),
          Row(
            children: [
              wheel(
                label: 'h',
                semantic: 'Heures',
                count: 24,
                selected: hours,
                onSelected: (h) => onChanged(
                    Duration(hours: h, minutes: minutes, seconds: seconds)),
              ),
              wheel(
                label: 'min',
                semantic: 'Minutes',
                count: 60,
                selected: minutes,
                onSelected: (m) => onChanged(
                    Duration(hours: hours, minutes: m, seconds: seconds)),
              ),
              if (withSeconds)
                wheel(
                  label: 's',
                  semantic: 'Secondes',
                  count: 60,
                  selected: seconds,
                  onSelected: (sec) => onChanged(
                      Duration(hours: hours, minutes: minutes, seconds: sec)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
