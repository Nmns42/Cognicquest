
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/media/media_store.dart';
import '../../../core/ui/media_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../../core/theme/tokens.dart';

/// Carte saisie. [front] et [back] sont le texte enregistré de chaque face,
/// image comprise (cf. [CardSide.encode]).
class FlashcardDraft {
  const FlashcardDraft({required this.front, required this.back, this.deck});

  final String front;
  final String back;
  final String? deck;
}

/// Poids maximal d'une image de carte (limite du bucket Storage).
const int maxCardImageBytes = MediaStore.maxBytes;

/// Choisit une image sur l'appareil, la dépose dans Storage et renvoie sa
/// référence (`media://…`), ou `null` (annulé, trop lourde, impossible).
Future<String?> pickCardImage(BuildContext context) async {
  void tell(String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)),
        snackBarAnimationStyle: Motion.style(context));
  }

  try {
    final file = (await FilePicker.pickFiles(type: FileType.image)).firstOrNull;
    if (file == null) return null;
    if ((await file.length() ?? 0) > maxCardImageBytes) {
      tell('Image trop lourde (5 Mo au plus).');
      return null;
    }
    final bytes = await file.readAsBytes();
    if (!context.mounted) return null;
    return storeImage(context, bytes, extension: file.extension);
  } catch (_) {
    tell('Impossible d’ouvrir le sélecteur d’images ici.');
    return null;
  }
}

/// Image d'une face de carte (Storage, encodée ou lien), cadrée sans
/// déformation.
class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.source, this.maxHeight = 260});

  final String source;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    Widget broken(BuildContext context, Object _, StackTrace? __) => Container(
          height: Sizes.control,
          alignment: Alignment.center,
          color: context.cq.beige,
          child: Icon(Icons.broken_image_outlined, color: context.cq.textHint),
        );
    final image = MediaImage(
      source: source,
      broken: (context) => broken(context, '', null),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.sm),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Semantics(image: true, label: 'Image de la carte', child: image),
      ),
    );
  }
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
      builder: (_) =>
          FlashcardEditorSheet(card: card, suggestedDeck: suggestedDeck),
    );
  }

  @override
  State<FlashcardEditorSheet> createState() => _FlashcardEditorSheetState();
}

class _FlashcardEditorSheetState extends State<FlashcardEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final CardSide? _initialFront = widget.card?.frontSide;
  late final CardSide? _initialBack = widget.card?.backSide;
  late final TextEditingController _frontController =
      TextEditingController(text: _initialFront?.text ?? '');
  late final TextEditingController _backController =
      TextEditingController(text: _initialBack?.text ?? '');
  late String? _frontImage = _initialFront?.image;
  late String? _backImage = _initialBack?.image;
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
        front: CardSide(_frontController.text, _frontImage).encode(),
        back: CardSide(_backController.text, _backImage).encode(),
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
                Text(isEditing ? 'Modifier la carte' : 'Nouvelle carte',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                 Text(
                  'Une carte = une seule idée. Si tu hésites à la couper '
                  'en deux, coupe-la.',
                  style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
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
                  // Une image seule suffit (schéma à légender, carte…).
                  validator: (value) =>
                      (value ?? '').trim().isEmpty && _frontImage == null
                          ? 'Écris la question ou ajoute une image.'
                          : null,
                ),
                _ImageField(
                  image: _frontImage,
                  label: 'Image de la question',
                  onChanged: (image) => setState(() => _frontImage = image),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _backController,
                  minLines: 2,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Réponse'),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty && _backImage == null
                          ? 'Écris la réponse ou ajoute une image.'
                          : null,
                ),
                _ImageField(
                  image: _backImage,
                  label: 'Image de la réponse',
                  onChanged: (image) => setState(() => _backImage = image),
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

/// Ajout, aperçu et retrait de l'image d'une face.
class _ImageField extends StatelessWidget {
  const _ImageField({
    required this.image,
    required this.label,
    required this.onChanged,
  });

  final String? image;
  final String label;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = image;
    if (current == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () async {
            final picked = await pickCardImage(context);
            if (picked != null) onChanged(picked);
          },
          icon: const Icon(Icons.add_photo_alternate_outlined,
              size: Sizes.iconMd),
          label: Text('Ajouter une image'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: Stack(
        children: [
          CardImage(source: current, maxHeight: 180),
          Positioned(
            top: Space.xs,
            right: Space.xs,
            child: Material(
              color: context.cq.cardColor,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Retirer : $label',
                icon: Icon(Icons.close,
                    size: Sizes.iconSm, color: context.cq.textMuted),
                onPressed: () => onChanged(null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
