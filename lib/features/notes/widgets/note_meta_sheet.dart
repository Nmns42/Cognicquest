import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_model.dart';
import '../../../core/theme/tokens.dart';

/// Métadonnées d'une fiche : sujet, tags, importance.
///
/// Ce sont elles qui alimentent les filtres et, au Lot 5, les arêtes du graphe
/// de connaissances.
class NoteMetaSheet extends StatefulWidget {
  const NoteMetaSheet({super.key, required this.note});

  final Note note;

  static Future<Note?> show(BuildContext context, {required Note note}) {
    return showModalBottomSheet<Note>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteMetaSheet(note: note),
    );
  }

  @override
  State<NoteMetaSheet> createState() => _NoteMetaSheetState();
}

class _NoteMetaSheetState extends State<NoteMetaSheet> {
  late final TextEditingController _subjectController =
      TextEditingController(text: widget.note.subject ?? '');
  final _tagController = TextEditingController();

  late List<String> _tags = List<String>.from(widget.note.tags);
  late NoteImportance _importance =
      NoteImportance.fromLevel(widget.note.importance);

  @override
  void dispose() {
    _subjectController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final raw = _tagController.text.trim().replaceAll('#', '');
    if (raw.isEmpty) return;

    // Comparaison insensible à la casse : « Maths » et « maths » ne doivent
    // pas produire deux tags distincts dans les filtres.
    final exists = _tags.any((t) => t.toLowerCase() == raw.toLowerCase());
    if (!exists) setState(() => _tags = [..._tags, raw]);
    _tagController.clear();
  }

  void _submit() {
    final subject = _subjectController.text.trim();
    Navigator.pop(
      context,
      widget.note.copyWith(
        subject: subject.isEmpty ? null : subject,
        clearSubject: subject.isEmpty,
        tags: _tags,
        importance: _importance.level,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration:  BoxDecoration(
          color: context.cq.beige,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.md)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
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
              Text('Classer la fiche',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 18),

              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Sujet / matière',
                  hintText: 'Ex : Physique',
                  prefixIcon: Icon(Icons.folder_outlined, size: 20),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  labelText: 'Tags',
                  hintText: 'Ex : à-revoir',
                  prefixIcon: const Icon(Icons.tag, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Ajouter le tag',
                    onPressed: _addTag,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTag(),
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _tags)
                      InputChip(
                        label: Text('#$tag',
                            style: const TextStyle(fontSize: TypeScale.caption)),
                        onDeleted: () => setState(
                            () => _tags = _tags.where((t) => t != tag).toList()),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

               Text(
                'Importance',
                style: TextStyle(
                  fontSize: TypeScale.body,
                  fontWeight: FontWeight.w600,
                  color: context.cq.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<NoteImportance>(
                segments: [
                  for (final importance in NoteImportance.values)
                    ButtonSegment(
                      value: importance,
                      label: Text(importance.label),
                    ),
                ],
                selected: {_importance},
                showSelectedIcon: false,
                onSelectionChanged: (values) =>
                    setState(() => _importance = values.first),
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
    );
  }
}
