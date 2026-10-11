import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_model.dart';
import '../data/note_repository.dart';
import '../providers/note_provider.dart';
import '../widgets/note_block_editor.dart';
import '../widgets/note_meta_sheet.dart';

/// Éditeur de fiche, avec **sauvegarde automatique** — « Sauvegarde automatique
/// en local » (CdC). Aucun bouton « Enregistrer » : l'écriture part en SQLite
/// après une courte inactivité, puis vers Supabase.
class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Timer? _autosave;
  bool _initialised = false;
  bool _isPreview = false;
  bool _hasUnsavedEdits = false;

  /// Version de travail : elle porte les blocs et les métadonnées pendant que
  /// l'utilisateur édite, sans dépendre d'un aller-retour par la base.
  Note? _draft;

  @override
  void dispose() {
    // Un départ d'écran ne doit jamais perdre la frappe des dernières
    // secondes : on force l'écriture avant de libérer les contrôleurs.
    if (_hasUnsavedEdits) _persist();
    _autosave?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _hydrate(Note note) {
    if (_initialised) return;
    _initialised = true;
    _draft = note;
    _titleController.text = note.title;
    _contentController.text = note.content;
  }

  void _scheduleSave() {
    _hasUnsavedEdits = true;
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 600), _persist);
  }

  void _persist() {
    final draft = _draft;
    if (draft == null) return;

    _hasUnsavedEdits = false;
    ref.read(noteActionsProvider).save(
          draft.copyWith(
            title: _titleController.text,
            content: _contentController.text,
          ),
        );
  }

  void _updateDraft(Note Function(Note) transform) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = transform(draft));
    _scheduleSave();
  }

  void _addBlock(NoteBlockType type) {
    _updateDraft((draft) => draft.copyWith(
          blocks: [
            ...draft.blocks,
            NoteBlock(
              id: LocalFirstNoteRepository.newId(),
              noteId: draft.id,
              type: type,
              content: '',
              position: draft.blocks.length,
            ),
          ],
        ));
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: Text(
          '${note.displayTitle}\n\nCette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text('Supprimer',
                style: TextStyle(color: context.cq.errorColor)),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      // On annule la sauvegarde en attente : réécrire une fiche qu'on vient
      // de supprimer la ferait réapparaître.
      _autosave?.cancel();
      _hasUnsavedEdits = false;
      await ref.read(noteActionsProvider).delete(note.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stored = ref.watch(noteByIdProvider(widget.noteId));

    if (stored == null && !_initialised) {
      return  Scaffold(
        body: Center(child: CircularProgressIndicator(color: context.cq.vert)),
      );
    }
    if (stored != null) _hydrate(stored);

    final draft = _draft;
    if (draft == null) {
      return  Scaffold(
        body: Center(child: CircularProgressIndicator(color: context.cq.vert)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPreview ? 'Aperçu' : 'Fiche'),
        actions: [
          IconButton(
            tooltip: draft.isFavorite
                ? 'Retirer des favorites'
                : 'Ajouter aux favorites',
            icon: Icon(
              draft.isFavorite ? Icons.star : Icons.star_border,
              color: draft.isFavorite
                  ? const Color(0xFFE39A3B)
                  : context.cq.textMuted,
            ),
            onPressed: () => _updateDraft(
                (d) => d.copyWith(isFavorite: !d.isFavorite)),
          ),
          IconButton(
            tooltip: _isPreview ? 'Éditer' : 'Aperçu Markdown',
            icon: Icon(_isPreview ? Icons.edit_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _isPreview = !_isPreview),
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (value) async {
              switch (value) {
                case 'meta':
                  final updated =
                      await NoteMetaSheet.show(context, note: draft);
                  if (updated != null) _updateDraft((_) => updated);
                case 'archive':
                  _updateDraft((d) => d.copyWith(isArchived: !d.isArchived));
                case 'delete':
                  await _confirmDelete(draft);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'meta',
                child: Text('Sujet, tags, importance'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(draft.isArchived ? 'Désarchiver' : 'Archiver'),
              ),
               PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer',
                    style: TextStyle(color: context.cq.errorColor)),
              ),
            ],
          ),
        ],
      ),
      body: _isPreview
          ? _MarkdownPreview(
              note: draft.copyWith(
                title: _titleController.text,
                content: _contentController.text,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                TextField(
                  controller: _titleController,
                  onChanged: (_) => _scheduleSave(),
                  textCapitalization: TextCapitalization.sentences,
                  style:  TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.cq.textPrimary,
                  ),
                  decoration:  InputDecoration(
                    hintText: 'Titre de la fiche',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.cq.textHint,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _MetaSummary(note: draft),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  onChanged: (_) => _scheduleSave(),
                  minLines: 6,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style:  TextStyle(
                      fontSize: 15, height: 1.5, color: context.cq.textPrimary),
                  decoration: const InputDecoration(
                    hintText:
                        'Écris ici. Le Markdown est accepté (**gras**, # titre, - liste).',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 20),
                NoteBlockEditor(
                  blocks: draft.blocks,
                  onChanged: (blocks) =>
                      _updateDraft((d) => d.copyWith(blocks: blocks)),
                ),
                const SizedBox(height: 16),
                _AddBlockBar(onAdd: _addBlock),
              ],
            ),
      bottomNavigationBar: _SaveIndicator(
        isSynced: draft.isSynced && !_hasUnsavedEdits,
      ),
    );
  }
}

class _MetaSummary extends StatelessWidget {
  const _MetaSummary({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final importance = NoteImportance.fromLevel(note.importance);
    final hasMeta = note.subject != null ||
        note.tags.isNotEmpty ||
        importance != NoteImportance.review;

    if (!hasMeta) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (note.subject != null)
          Chip(
            label: Text(note.subject!, style: const TextStyle(fontSize: 11)),
            avatar: const Icon(Icons.folder_outlined, size: 13),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        for (final tag in note.tags)
          Chip(
            label: Text('#$tag', style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        if (importance != NoteImportance.review)
          Chip(
            label: Text(importance.label, style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

class _AddBlockBar extends StatelessWidget {
  const _AddBlockBar({required this.onAdd});

  final ValueChanged<NoteBlockType> onAdd;

  static const List<(NoteBlockType, IconData)> _options = [
    (NoteBlockType.todo, Icons.check_box_outlined),
    (NoteBlockType.bulleted, Icons.format_list_bulleted),
    (NoteBlockType.heading, Icons.title),
    (NoteBlockType.quote, Icons.format_quote),
    (NoteBlockType.code, Icons.code),
    (NoteBlockType.link, Icons.link),
    (NoteBlockType.image, Icons.image_outlined),
    (NoteBlockType.divider, Icons.horizontal_rule),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          'Ajouter un bloc',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.cq.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (type, icon) in _options)
              ActionChip(
                avatar: Icon(icon, size: 15),
                label: Text(type.label, style: const TextStyle(fontSize: 12)),
                onPressed: () => onAdd(type),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: note.toMarkdown(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
      styleSheet: MarkdownStyleSheet(
        h1:  TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: context.cq.textPrimary),
        h2:  TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: context.cq.textPrimary),
        p:  TextStyle(fontSize: 15, height: 1.5, color: context.cq.textPrimary),
        blockquoteDecoration: BoxDecoration(
          color: context.cq.beigeDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        code: const TextStyle(
            fontSize: 13, backgroundColor: Colors.transparent),
        codeblockDecoration: BoxDecoration(
          color: context.cq.beigeDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// État de sauvegarde. La sauvegarde étant automatique, l'utilisateur doit
/// pouvoir vérifier d'un coup d'œil que son travail est bien enregistré.
class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.isSynced});

  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSynced ? Icons.cloud_done_outlined : Icons.save_outlined,
            size: 14,
            color: context.cq.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            isSynced
                ? 'Enregistrée et synchronisée'
                : 'Enregistrée sur cet appareil',
            style:  TextStyle(fontSize: 12, color: context.cq.textHint),
          ),
        ],
      ),
    );
  }
}
