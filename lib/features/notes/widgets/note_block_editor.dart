import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_model.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';

/// Édition des blocs structurés d'une fiche.
///
/// Les blocs sont réordonnables et supprimables ; chaque type a son rendu de
/// saisie (case à cocher, puce, citation, code…).
class NoteBlockEditor extends StatefulWidget {
  const NoteBlockEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
  });

  final List<NoteBlock> blocks;
  final ValueChanged<List<NoteBlock>> onChanged;

  @override
  State<NoteBlockEditor> createState() => _NoteBlockEditorState();
}

class _NoteBlockEditorState extends State<NoteBlockEditor> {
  /// Un contrôleur par bloc, conservé entre les reconstructions : en recréer un
  /// à chaque build ferait sauter le curseur à chaque frappe.
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(NoteBlock block) {
    final existing = _controllers[block.id];
    if (existing != null) {
      if (existing.text != block.content && !existing.selection.isValid) {
        existing.text = block.content;
      }
      return existing;
    }
    final controller = TextEditingController(text: block.content);
    _controllers[block.id] = controller;
    return controller;
  }

  void _update(NoteBlock block, NoteBlock updated) {
    widget.onChanged([
      for (final b in widget.blocks)
        if (b.id == block.id) updated else b,
    ]);
  }

  void _remove(NoteBlock block) {
    _controllers.remove(block.id)?.dispose();
    final remaining = widget.blocks.where((b) => b.id != block.id).toList();
    widget.onChanged([
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(position: i),
    ]);
  }

  void _reorder(int oldIndex, int newIndex) {
    final blocks = List<NoteBlock>.from(widget.blocks);
    blocks.insert(
        newIndex.clamp(0, blocks.length - 1), blocks.removeAt(oldIndex));
    widget.onChanged([
      for (var i = 0; i < blocks.length; i++) blocks[i].copyWith(position: i),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.blocks.isEmpty) return const SizedBox.shrink();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: widget.blocks.length,
      onReorderItem: _reorder,
      itemBuilder: (context, index) {
        final block = widget.blocks[index];
        return Padding(
          key: ValueKey(block.id),
          padding: const EdgeInsets.only(bottom: 6),
          child: _BlockRow(
            index: index,
            block: block,
            controller: block.type == NoteBlockType.divider
                ? null
                : _controllerFor(block),
            onContentChanged: (value) =>
                _update(block, block.copyWith(content: value)),
            onToggleCheck: () =>
                _update(block, block.copyWith(isChecked: !block.isChecked)),
            onRemove: () => _remove(block),
          ),
        );
      },
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({
    required this.index,
    required this.block,
    required this.controller,
    required this.onContentChanged,
    required this.onToggleCheck,
    required this.onRemove,
  });

  final int index;
  final NoteBlock block;
  final TextEditingController? controller;
  final ValueChanged<String> onContentChanged;
  final VoidCallback onToggleCheck;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // L'appui long sert à sélectionner du texte : seule la poignée, visible
    // au survol, déplace le bloc.
    return CqReorderableItem(
      index: index,
      gripLeading: true,
      longPressAnywhere: false,
      semanticLabel: 'Déplacer ce bloc',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _content(context)),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            tooltip: 'Supprimer ce bloc',
            icon: Icon(Icons.close, size: 16, color: context.cq.textHint),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (block.type == NoteBlockType.divider) {
      return const Divider(height: 20);
    }

    final field = TextField(
      controller: controller,
      onChanged: onContentChanged,
      minLines: 1,
      maxLines: block.type == NoteBlockType.code ? 8 : 4,
      keyboardType: block.type == NoteBlockType.link
          ? TextInputType.url
          : TextInputType.multiline,
      style: _textStyle(context),
      decoration: InputDecoration(
        hintText: _hint,
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
      ),
    );

    return switch (block.type) {
      NoteBlockType.todo => Row(
          children: [
            InkWell(
              onTap: onToggleCheck,
              borderRadius: BorderRadius.circular(Radii.md),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color:
                        block.isChecked ? context.cq.vert : Colors.transparent,
                    border: Border.all(
                      color: block.isChecked
                          ? context.cq.vert
                          : context.cq.beigeDark,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: block.isChecked
                      ? Icon(Icons.check, size: 12, color: context.onAccent)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: field),
          ],
        ),
      NoteBlockType.bulleted => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 8, left: 4),
              child: SizedBox(
                width: 5,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.cq.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Expanded(child: field),
          ],
        ),
      NoteBlockType.quote => Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: context.cq.vert, width: 3),
            ),
          ),
          child: field,
        ),
      NoteBlockType.code => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: context.cq.beigeDark.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: field,
        ),
      _ => field,
    };
  }

  TextStyle _textStyle(BuildContext context) => switch (block.type) {
        NoteBlockType.heading => TextStyle(
            fontSize: TypeScale.title,
            fontWeight: FontWeight.w600,
            color: context.cq.textPrimary,
          ),
        NoteBlockType.quote => TextStyle(
            fontSize: TypeScale.body,
            fontStyle: FontStyle.italic,
            color: context.cq.textMuted,
          ),
        NoteBlockType.code => TextStyle(
            fontSize: TypeScale.body,
            fontFamily: 'monospace',
            color: context.cq.textPrimary,
          ),
        NoteBlockType.todo => TextStyle(
            fontSize: TypeScale.body,
            color:
                block.isChecked ? context.cq.textMuted : context.cq.textPrimary,
            decoration: block.isChecked ? TextDecoration.lineThrough : null,
            decorationColor: context.cq.textMuted,
          ),
        _ => TextStyle(fontSize: TypeScale.body, color: context.cq.textPrimary),
      };

  String get _hint => switch (block.type) {
        NoteBlockType.heading => 'Titre de section',
        NoteBlockType.todo => 'Ce qu\'il reste à faire',
        NoteBlockType.bulleted => 'Élément de liste',
        NoteBlockType.quote => 'Citation ou définition',
        NoteBlockType.code => 'Extrait de code',
        NoteBlockType.link => 'https://…',
        NoteBlockType.image => 'URL de l\'image',
        _ => 'Texte',
      };
}
