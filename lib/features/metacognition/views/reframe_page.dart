import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/metacognition_model.dart';
import '../data/metacognition_repository.dart';
import '../providers/metacognition_provider.dart';
import '../../../core/theme/tokens.dart';

/// Recadrage cognitif — « identifier et transformer les pensées bloquantes
/// (ex : "Je suis nul en maths") en objectifs de croissance » (CdC).
///
/// Le parcours est volontairement séquentiel : nommer la pensée, repérer la
/// distorsion, chercher les faits qui la contredisent, puis seulement
/// reformuler. Sauter à la reformulation produit un slogan, pas un recadrage.
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

  CognitiveDistortion? _distortion;
  Reframe? _editing;

  @override
  void dispose() {
    _thoughtController.dispose();
    _evidenceController.dispose();
    _reframedController.dispose();
    _goalController.dispose();
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
    });
  }

  void _reset() {
    setState(() {
      _editing = null;
      _thoughtController.clear();
      _evidenceController.clear();
      _reframedController.clear();
      _goalController.clear();
      _distortion = null;
    });
  }

  Future<void> _save() async {
    final thought = _thoughtController.text.trim();
    if (thought.isEmpty) return;

    final editing = _editing;
    await ref.read(metacognitionActionsProvider).saveReframe(
          Reframe(
            id: editing?.id ?? newMetacognitionId(),
            userId: editing?.userId ?? '',
            limitingThought: thought,
            distortion: _distortion,
            evidenceAgainst: _evidenceController.text.trim(),
            reframedThought: _reframedController.text.trim(),
            growthGoal: _goalController.text.trim(),
            createdAt: editing?.createdAt ?? DateTime.now(),
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

            const _Step(2, 'Quelle distorsion reconnais-tu ?'),
            const SizedBox(height: 4),
             Text(
              'Nommer le mécanisme le désamorce en partie.',
              style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final distortion in CognitiveDistortion.values)
                  Tooltip(
                    message: distortion.example,
                    child: FilterChip(
                      label: Text(distortion.label,
                          style: const TextStyle(fontSize: TypeScale.caption)),
                      selected: _distortion == distortion,
                      onSelected: (selected) => setState(
                          () => _distortion = selected ? distortion : null),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            const _Step(3, 'Qu\'est-ce qui contredit cette pensée ?'),
            const SizedBox(height: 4),
             Text(
              'Des faits, pas des encouragements. Une note correcte, un '
              'exercice réussi, un progrès mesurable.',
              style: TextStyle(
                  fontSize: TypeScale.caption, color: context.cq.textMuted, height: 1.4),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _evidenceController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex : « J\'ai eu 14 au dernier contrôle de géométrie »',
              ),
            ),
            const SizedBox(height: 22),

            const _Step(4, 'Reformule, sans te mentir'),
            const SizedBox(height: 8),
            TextField(
              controller: _reframedController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Ex : « Les démonstrations me résistent, la géométrie non »',
              ),
            ),
            const SizedBox(height: 22),

            const _Step(5, 'L\'objectif de croissance'),
            const SizedBox(height: 4),
             Text(
              'Ce que tu vas faire, pas ce que tu voudrais être.',
              style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _goalController,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex : « Faire une démonstration guidée par jour »',
              ),
            ),
            const SizedBox(height: 26),

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
            color: context.cq.vert,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: TextStyle(
                color: context.onAccent, fontSize: TypeScale.caption, fontWeight: FontWeight.w700),
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
