import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/planning_model.dart';
import '../data/planning_repository.dart';
import '../domain/study_speed.dart';
import '../providers/planning_provider.dart';

/// Estimation de la vitesse de travail — « estimation/pronostic de la vitesse
/// de lecture/rédaction/rétention/compréhension » (CdC).
class StudySpeedPage extends ConsumerStatefulWidget {
  const StudySpeedPage({super.key});

  @override
  ConsumerState<StudySpeedPage> createState() => _StudySpeedPageState();
}

class _StudySpeedPageState extends ConsumerState<StudySpeedPage> {
  final _forecastController = TextEditingController(text: '30');

  @override
  void dispose() {
    _forecastController.dispose();
    super.dispose();
  }

  Future<void> _addSample() async {
    await showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SampleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimates = ref.watch(speedEstimatesProvider);
    final subjects = ref.watch(speedSubjectsProvider);
    final selected = ref.watch(speedSubjectProvider);
    final forecastUnits = double.tryParse(_forecastController.text) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Ma vitesse de travail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
           Text(
            'Mesure quelques séances, et CognicQuest saura estimer le temps '
            'qu\'il te faut — au lieu de te fier à une intuition qui se '
            'trompe presque toujours.',
            style: TextStyle(
                fontSize: 12.5, color: context.cq.textMuted, height: 1.45),
          ),
          const SizedBox(height: 18),

          if (subjects.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Toutes matières',
                      style: TextStyle(fontSize: 12)),
                  selected: selected == null,
                  onSelected: (_) =>
                      ref.read(speedSubjectProvider.notifier).state = null,
                ),
                for (final subject in subjects)
                  FilterChip(
                    label: Text(subject, style: const TextStyle(fontSize: 12)),
                    selected: selected == subject,
                    onSelected: (isSelected) => ref
                        .read(speedSubjectProvider.notifier)
                        .state = isSelected ? subject : null,
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],

          if (estimates.isEmpty)
            const _EmptyState()
          else ...[
            TextField(
              controller: _forecastController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Combien en as-tu à traiter ?',
                helperText: 'Pages, mots, cartes ou exercices selon l\'activité',
                prefixIcon: Icon(Icons.calculate_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 18),
            for (final estimate in estimates)
              _EstimateCard(estimate: estimate, forecastUnits: forecastUnits),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSample,
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle mesure',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.estimate, required this.forecastUnits});

  final SpeedEstimate estimate;
  final double forecastUnits;

  @override
  Widget build(BuildContext context) {
    final forecast = estimate.forecast(forecastUnits);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(estimate.activity.label,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estimate.isReliable
                        ? context.cq.vert.withValues(alpha: 0.12)
                        : context.cq.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    estimate.confidenceLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: estimate.isReliable
                          ? context.cq.vertDark
                          : context.cq.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  estimate.unitsPerHour.toStringAsFixed(1),
                  style:  TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: context.cq.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${estimate.activity.unit} / heure',
                    style:  TextStyle(
                        fontSize: 12.5, color: context.cq.textMuted),
                  ),
                ),
              ],
            ),
            if (forecast != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cq.beigeDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${forecastUnits.toStringAsFixed(0)} ${estimate.activity.unit} '
                  '→ environ ${StudySpeed.formatForecast(forecast)}'
                  '${estimate.isReliable ? '' : ' (à confirmer)'}',
                  style:  TextStyle(
                      fontSize: 12.5,
                      color: context.cq.textPrimary,
                      height: 1.4),
                ),
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
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
           Icon(Icons.speed_outlined, size: 48, color: context.cq.textHint),
          const SizedBox(height: 16),
          Text('Aucune mesure',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
           Text(
            'Après une séance, note ce que tu as traité et en combien de '
            'temps. Trois mesures suffisent pour une estimation fiable.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.cq.textMuted, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Saisie d'une mesure.
class _SampleSheet extends ConsumerStatefulWidget {
  const _SampleSheet();

  @override
  ConsumerState<_SampleSheet> createState() => _SampleSheetState();
}

class _SampleSheetState extends ConsumerState<_SampleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController();
  final _minutesController = TextEditingController();
  final _subjectController = TextEditingController();

  StudyActivity _activity = StudyActivity.reading;

  @override
  void dispose() {
    _unitsController.dispose();
    _minutesController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return 'Entre un nombre supérieur à 0.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final units =
        double.parse(_unitsController.text.replaceAll(',', '.'));
    final minutes =
        double.parse(_minutesController.text.replaceAll(',', '.'));
    final subject = _subjectController.text.trim();

    await ref.read(planningActionsProvider).saveSpeedSample(
          SpeedSample(
            id: newPlanningId(),
            userId: '',
            activity: _activity,
            subject: subject.isEmpty ? null : subject,
            units: units,
            durationSeconds: (minutes * 60).round(),
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
                Text('Nouvelle mesure',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 18),

                SegmentedButton<StudyActivity>(
                  segments: [
                    for (final activity in StudyActivity.values)
                      ButtonSegment(
                        value: activity,
                        label: Text(activity.label,
                            style: const TextStyle(fontSize: 11)),
                      ),
                  ],
                  selected: {_activity},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) =>
                      setState(() => _activity = values.first),
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _unitsController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantité (${_activity.unit})',
                  ),
                  validator: _positiveNumber,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durée (minutes)',
                    prefixIcon: Icon(Icons.timer_outlined, size: 20),
                  ),
                  validator: _positiveNumber,
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
