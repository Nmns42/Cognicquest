import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/metacognition_model.dart';
import '../data/metacognition_repository.dart';
import '../providers/metacognition_provider.dart';
import '../widgets/scale_picker.dart';
import '../../../core/theme/tokens.dart';

/// Bilan de session — « bilan de fin de session avec questions guidées » (CdC),
/// avec tracker d'humeur, d'énergie et de RPE.
class JournalEntryPage extends ConsumerStatefulWidget {
  const JournalEntryPage({super.key});

  @override
  ConsumerState<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends ConsumerState<JournalEntryPage> {
  final _learnedController = TextEditingController();
  final _workedController = TextEditingController();
  final _blockedController = TextEditingController();
  final _nextController = TextEditingController();

  int _mood = 3;
  int _energy = 3;
  int _rpe = 5;

  /// Entrée du jour reprise en édition, le cas échéant : un deuxième bilan le
  /// même jour écraserait le premier plutôt que d'en créer un doublon.
  JournalEntry? _existing;
  bool _hydrated = false;

  @override
  void dispose() {
    _learnedController.dispose();
    _workedController.dispose();
    _blockedController.dispose();
    _nextController.dispose();
    super.dispose();
  }

  void _hydrate(JournalEntry? entry) {
    if (_hydrated) return;
    _hydrated = true;
    if (entry == null) return;

    _existing = entry;
    _mood = entry.mood;
    _energy = entry.energy;
    _rpe = entry.rpe;
    _learnedController.text = entry.whatLearned;
    _workedController.text = entry.whatWorked;
    _blockedController.text = entry.whatBlocked;
    _nextController.text = entry.nextStep;
  }

  Future<void> _save() async {
    final existing = _existing;

    await ref.read(metacognitionActionsProvider).saveJournalEntry(
          JournalEntry(
            id: existing?.id ?? newMetacognitionId(),
            userId: existing?.userId ?? '',
            noteId: existing?.noteId,
            mood: _mood,
            energy: _energy,
            rpe: _rpe,
            whatLearned: _learnedController.text.trim(),
            whatWorked: _workedController.text.trim(),
            whatBlocked: _blockedController.text.trim(),
            nextStep: _nextController.text.trim(),
            createdAt: existing?.createdAt ?? DateTime.now(),
            isSynced: false,
          ),
        );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    _hydrate(ref.watch(todayJournalEntryProvider));

    final isStrained = _rpe >= 8 && _mood <= 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Bilan de session' : 'Bilan du jour'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
             Text(
              'Trois curseurs, quatre questions. Deux minutes suffisent — '
              'c\'est la régularité qui rend les tendances lisibles.',
              style: TextStyle(
                  fontSize: TypeScale.caption, color: context.cq.textMuted, height: 1.45),
            ),
            const SizedBox(height: 22),

            ScalePicker(
              label: 'Humeur',
              hint: 'Comment tu te sens, là, maintenant',
              value: _mood,
              max: 5,
              onChanged: (value) => setState(() => _mood = value),
            ),
            const SizedBox(height: 18),
            ScalePicker(
              label: 'Énergie',
              hint: 'Ce qu\'il te reste dans le réservoir',
              value: _energy,
              max: 5,
              onChanged: (value) => setState(() => _energy = value),
            ),
            const SizedBox(height: 18),
            ScalePicker(
              label: 'Effort ressenti (RPE)',
              hint: 'À quel point cette session t\'a coûté',
              value: _rpe,
              max: 10,
              onChanged: (value) => setState(() => _rpe = value),
            ),

            if (isStrained) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: context.cq.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                      color: context.cq.errorColor.withValues(alpha: 0.3)),
                ),
                child:  Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: context.cq.errorColor),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Effort fort et moral bas : c\'est la combinaison qui '
                        'précède l\'épuisement. Prévois une vraie coupure.',
                        style: TextStyle(
                            fontSize: TypeScale.caption,
                            color: context.cq.errorColor,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 26),
            const _Question('Qu\'ai-je appris ?'),
            const SizedBox(height: 8),
            _Field(
              controller: _learnedController,
              hint: 'La notion, pas le chapitre. Sois précis.',
            ),
            const SizedBox(height: 18),

            const _Question('Qu\'est-ce qui a marché ?'),
            const SizedBox(height: 8),
            _Field(
              controller: _workedController,
              hint: 'La méthode, le lieu, le moment…',
            ),
            const SizedBox(height: 18),

            const _Question('Où ai-je bloqué ?'),
            const SizedBox(height: 8),
            _Field(
              controller: _blockedController,
              hint: 'Ce qui a résisté, et à quel moment',
            ),
            const SizedBox(height: 18),

            const _Question('Et maintenant ?'),
            const SizedBox(height: 8),
            _Field(
              controller: _nextController,
              hint: 'Une seule action concrète pour la prochaine fois',
            ),
            const SizedBox(height: 26),

            ElevatedButton(
              onPressed: _save,
              child: Text(_existing == null
                  ? 'Enregistrer le bilan'
                  : 'Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style:  TextStyle(
          fontSize: TypeScale.body,
          fontWeight: FontWeight.w600,
          color: context.cq.textPrimary,
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        minLines: 2,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
      );
}
