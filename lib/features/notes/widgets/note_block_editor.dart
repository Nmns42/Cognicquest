import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_model.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
import 'slash_commands.dart';

/// Édition des blocs structurés d'une fiche.
///
/// Les blocs sont réordonnables et supprimables ; chaque type a son rendu de
/// saisie (case à cocher, puce, citation, code…).
class NoteBlockEditor extends StatefulWidget {
  const NoteBlockEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
    this.noteId,
    this.linkableNotes = const [],
  });

  final List<NoteBlock> blocks;
  final ValueChanged<List<NoteBlock>> onChanged;

  /// Fiche éditée : exclue des fiches proposées par « [[ ».
  final String? noteId;

  /// Fiches proposées quand on tape « [[ » ou « / Lien vers une fiche ».
  final List<Note> linkableNotes;

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

  /// Frappe dans un bloc : « / » dans un bloc vide ouvre le menu des types,
  /// « [[ » ouvre le choix d'une fiche à lier.
  void _onContentChanged(BuildContext rowContext, NoteBlock block,
      String previous, String value) {
    _update(block, block.copyWith(content: value));
    final controller = _controllers[block.id];
    if (controller == null) return;
    final trigger = detectTrigger(previous, controller.value);
    if (trigger == Trigger.wikiLink) {
      unawaited(_insertNoteLink(block, controller));
    } else if (trigger == Trigger.slash && value == '/') {
      unawaited(_openSlashMenu(rowContext, block, controller));
    }
  }

  Future<void> _openSlashMenu(BuildContext rowContext, NoteBlock block,
      TextEditingController controller) async {
    final box = rowContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final command = await showSlashMenu(
      context,
      anchor: Rect.fromLTWH(anchor.left, anchor.top, 1, anchor.height),
      commands: SlashCommand.forBlocks,
    );
    if (command == null || !mounted) return;
    controller.text = '';
    final current = widget.blocks.firstWhere((b) => b.id == block.id,
        orElse: () => block);
    if (command == SlashCommand.noteLink) {
      _update(current, current.copyWith(content: ''));
      await _insertNoteLink(current, controller, replaceTyped: false);
      return;
    }
    _update(current,
        current.copyWith(type: command.blockType, content: ''));
  }

  Future<void> _insertNoteLink(NoteBlock block,
      TextEditingController controller, {bool replaceTyped = true}) async {
    final target = await showNotePicker(context,
        notes: widget.linkableNotes, excludeId: widget.noteId);
    if (target == null || !mounted) return;
    final value = controller.value;
    final caret = value.selection.isValid
        ? value.selection.baseOffset
        : value.text.length;
    final start = replaceTyped &&
            caret >= 2 &&
            value.text.substring(caret - 2, caret) == '[['
        ? caret - 2
        : caret;
    final insert = '[[${target.displayTitle}]]';
    final text = value.text.replaceRange(start, caret, insert);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    final current = widget.blocks.firstWhere((b) => b.id == block.id,
        orElse: () => block);
    _update(current, current.copyWith(content: text));
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
            onContentChanged: (rowContext, value) => _onContentChanged(
                rowContext, block, block.content, value),
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
  final void Function(BuildContext rowContext, String value)
      onContentChanged;
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
      onChanged: (value) => onContentChanged(context, value),
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
              left: BorderSide(color: context.cq.vertDark, width: 3),
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
