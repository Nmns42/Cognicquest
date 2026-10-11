import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/flashcard_model.dart';

class FlashcardDraft {
  const FlashcardDraft({required this.front, required this.back, this.deck});

  final String front;
  final String back;
  final String? deck;
}

/// Création / édition d'une carte.
class FlashcardEditorSheet extends StatefulWidget {
  const FlashcardEditorSheet({super.key, this.card, this.suggestedDeck});

  final Flashcard? card;
  final String? suggestedDeck;

  static Future<FlashcardDraft?> show(
    BuildContext context, {
    Flashcard? card,
    String? suggestedDeck,
  }) {
    return showModalBottomSheet<FlashcardDraft>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          FlashcardEditorSheet(card: card, suggestedDeck: suggestedDeck),
    );
  }

  @override
  State<FlashcardEditorSheet> createState() => _FlashcardEditorSheetState();
}

class _FlashcardEditorSheetState extends State<FlashcardEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontController =
      TextEditingController(text: widget.card?.front ?? '');
  late final TextEditingController _backController =
      TextEditingController(text: widget.card?.back ?? '');
  late final TextEditingController _deckController = TextEditingController(
    text: widget.card?.deck ?? widget.suggestedDeck ?? '',
  );

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _deckController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final deck = _deckController.text.trim();
    Navigator.pop(
      context,
      FlashcardDraft(
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        deck: deck.isEmpty ? null : deck,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.card != null;

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
                Text(isEditing ? 'Modifier la carte' : 'Nouvelle carte',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                 Text(
                  'Une carte = une seule idée. Si tu hésites à la couper '
                  'en deux, coupe-la.',
                  style: TextStyle(fontSize: 11.5, color: context.cq.textMuted),
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _frontController,
                  autofocus: !isEditing,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'Ce que tu dois pouvoir retrouver',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Écris la question.'
                      : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _backController,
                  minLines: 2,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Réponse'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Écris la réponse.'
                      : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _deckController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Paquet (facultatif)',
                    hintText: 'Ex : Physique',
                    prefixIcon: Icon(Icons.folder_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Enregistrer' : 'Créer la carte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
