import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/media/media_store.dart';
import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_model.dart';
import '../data/note_repository.dart';
import '../providers/note_provider.dart';
import '../widgets/note_block_editor.dart';
import '../widgets/note_meta_sheet.dart';
import '../../../core/theme/tokens.dart';
import '../../../router/app_router.dart';
import '../../graph/providers/graph_provider.dart';
import '../../../core/ui/media_image.dart';
import '../domain/note_pdf_export.dart';
import '../domain/wiki_links.dart';
import '../widgets/format_toolbar.dart';
import '../widgets/pdf_block.dart';
import '../widgets/rich_markdown.dart';
import '../widgets/slash_commands.dart';

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

  /// Champ du texte libre : sert à placer le menu « / » sous le curseur.
  final _contentKey = GlobalKey();

  /// Texte avant la dernière frappe, pour reconnaître « / » et « [[ ».
  String _lastContent = '';

  Timer? _autosave;
  bool _initialised = false;
  bool _isPreview = false;
  bool _hasUnsavedEdits = false;

  /// Version de travail : elle porte les blocs et les métadonnées pendant que
  /// l'utilisateur édite, sans dépendre d'un aller-retour par la base.
  Note? _draft;

  @override
  void deactivate() {
    // Un départ d'écran ne doit jamais perdre la frappe des dernières
    // secondes : on force l'écriture ici, car `ref` n'est plus utilisable
    // dans `dispose`.
    if (_hasUnsavedEdits) _persist();
    super.deactivate();
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _hydrate(Note note) {
    if (_initialised) return;
    _initialised = true;
    // Une fiche déjà remplie s'ouvre en lecture ; une fiche vide, en
    // édition (le crayon bascule de l'un à l'autre).
    _isPreview = note.content.trim().isNotEmpty || note.blocks.isNotEmpty;
    _draft = note;
    _titleController.text = note.title;
    _contentController.text = note.content;
    _lastContent = note.content;
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
    final note = draft.copyWith(
      title: _titleController.text,
      content: _contentController.text,
    );
    ref.read(noteActionsProvider).save(note);
    _linkCitedNotes(note);
  }

  /// Chaque `[[Titre]]` cité relie cette fiche à la fiche de ce titre (le
  /// dépôt ignore un lien déjà présent). Lu tout de suite : `_persist` peut
  /// tourner pendant la fermeture de l'écran.
  void _linkCitedNotes(Note note) {
    final notes = ref.read(notesProvider).valueOrNull ?? const <Note>[];
    final targets = WikiLinks.targetsOf(note, notes);
    if (targets.isEmpty) return;
    final actions = ref.read(graphActionsProvider);
    for (final target in targets) {
      unawaited(actions.link(sourceId: note.id, targetId: target.id));
    }
  }

  TextStyle _contentStyle(BuildContext context) => TextStyle(
      fontSize: TypeScale.bodyLarge,
      height: 1.5,
      color: context.cq.textPrimary);

  void _onContentChanged(String value) {
    final trigger = detectTrigger(_lastContent, _contentController.value);
    _lastContent = value;
    _scheduleSave();
    if (trigger != null) unawaited(_onTrigger(trigger));
  }

  Future<void> _onTrigger(Trigger trigger) async {
    final fieldContext = _contentKey.currentContext;
    if (fieldContext == null) return;
    if (trigger == Trigger.wikiLink) return _insertNoteLink();

    final anchor = caretRect(
        fieldContext, _contentController.value, _contentStyle(context));
    final command = await showSlashMenu(context, anchor: anchor);
    if (command == null || !mounted) return;

    final value = _contentController.value;
    final slash = value.selection.baseOffset - 1;
    if (slash < 0 || value.text[slash] != '/') return;

    // Image ou vidéo : le « / » disparaît et un bloc média s'ajoute, prêt à
    // recevoir un fichier ou un lien.
    final blockType = command.blockType;
    if (command.isMedia && blockType != null) {
      _replaceContent(slash, slash + 1, '');
      _addBlock(blockType);
      return;
    }

    // Le « / » tapé est remplacé par la syntaxe de la commande ; au milieu
    // d'une ligne, la commande commence une nouvelle ligne. Le curseur se
    // place entre l'ouverture et la fermeture (sous-titre, code).
    final atLineStart = slash == 0 || value.text[slash - 1] == '\n';
    final insert = '${atLineStart ? '' : '\n'}${command.markdown}';
    _replaceContent(slash, slash + 1, insert + command.suffix,
        caret: slash + insert.length);
    if (command == SlashCommand.noteLink) await _insertNoteLink();
  }

  /// Ouvre le choix d'une fiche et complète le « [[ » qui précède le curseur
  /// en `[[Titre]]`.
  Future<void> _insertNoteLink() async {
    final notes = ref.read(notesProvider).valueOrNull ?? const <Note>[];
    final target =
        await showNotePicker(context, notes: notes, excludeId: _draft?.id);
    if (target == null || !mounted) return;
    final value = _contentController.value;
    final caret = value.selection.baseOffset;
    final start = caret >= 2 && value.text.substring(caret - 2, caret) == '[['
        ? caret - 2
        : caret;
    _replaceContent(start, caret, '[[${target.displayTitle}]]');
  }

  void _replaceContent(int start, int end, String insert, {int? caret}) {
    final text = _contentController.text.replaceRange(start, end, insert);
    _contentController.value = TextEditingValue(
      text: text,
      selection:
          TextSelection.collapsed(offset: caret ?? start + insert.length),
    );
    _lastContent = text;
    _scheduleSave();
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

  /// Export PDF de la fiche telle qu'affichée (mise en forme, images,
  /// PDF annotés joints), puis partage ou téléchargement selon la
  /// plateforme.
  Future<void> _exportPdf(Note note) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Préparation du PDF…')),
      snackBarAnimationStyle: Motion.style(context),
    );
    try {
      Future<ByteData> font(String path) =>
          rootBundle.load('assets/fonts/$path');
      final fonts = PdfFonts.fromBytes(
        regular: await font('plus_jakarta_sans/PlusJakartaSans-Regular.ttf'),
        bold: await font('plus_jakarta_sans/PlusJakartaSans-Bold.ttf'),
        serif: await font('fraunces/Fraunces-Regular.ttf'),
        serifBold: await font('fraunces/Fraunces-SemiBold.ttf'),
        fallback: await font('noto_sans/NotoSans-Regular.ttf'),
      );
      final store = ref.read(mediaStoreProvider);
      final bytes = await NotePdfExporter(
        fonts: fonts,
        loadImage: (source) async => store?.read(source),
      ).build(note);
      final name =
          note.displayTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ').trim();
      messenger.hideCurrentSnackBar();
      await Printing.sharePdf(
          bytes: bytes, filename: '${name.isEmpty ? 'fiche' : name}.pdf');
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(
                content: Text('Export PDF impossible sur cet appareil.')),
            snackBarAnimationStyle: Motion.style(context));
    }
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: Motion.style(context),
      builder: (context) => AlertDialog(
        scrollable: true,
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
            child: Text('Supprimer',
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
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: context.cq.vertDark)),
      );
    }
    if (stored != null) _hydrate(stored);

    final draft = _draft;
    if (draft == null) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: context.cq.vertDark)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPreview ? 'Aperçu' : 'Édition'),
        actions: [
          IconButton(
            tooltip: draft.isFavorite
                ? 'Retirer des favorites'
                : 'Ajouter aux favorites',
            icon: Icon(
              draft.isFavorite ? Icons.star : Icons.star_border,
              color:
                  draft.isFavorite ? context.cq.warning : context.cq.textMuted,
            ),
            onPressed: () =>
                _updateDraft((d) => d.copyWith(isFavorite: !d.isFavorite)),
          ),
          IconButton(
            tooltip: 'S’entraîner sur cette fiche',
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () {
              // Le quiz lit la fiche enregistrée : la frappe en attente
              // doit y être.
              if (_hasUnsavedEdits) {
                _autosave?.cancel();
                _persist();
              }
              context.push(AppRoute.quizFor(noteId: widget.noteId));
            },
          ),
          IconButton(
            tooltip: _isPreview ? 'Modifier la fiche' : 'Voir l’aperçu',
            icon: Icon(
                _isPreview ? Icons.edit_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _isPreview = !_isPreview),
          ),
          PopupMenuButton<String>(
            popUpAnimationStyle: Motion.style(context),
            tooltip: 'Options',
            onSelected: (value) async {
              switch (value) {
                case 'meta':
                  final updated =
                      await NoteMetaSheet.show(context, note: draft);
                  if (updated != null) _updateDraft((_) => updated);
                case 'pdf':
                  await _exportPdf(draft.copyWith(
                    title: _titleController.text,
                    content: _contentController.text,
                  ));
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
              const PopupMenuItem(
                value: 'pdf',
                child: Text('Exporter en PDF'),
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
          ? _RichPreview(
              note: draft.copyWith(
                title: _titleController.text,
                content: _contentController.text,
              ),
            )
          : Column(
              children: [
                FormatToolbar(
                  controller: _contentController,
                  onEdited: () {
                    _lastContent = _contentController.text;
                    _scheduleSave();
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => _scheduleSave(),
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: TypeScale.headline,
                          fontWeight: FontWeight.bold,
                          color: context.cq.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Titre de la fiche',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            fontSize: TypeScale.headline,
                            fontWeight: FontWeight.bold,
                            color: context.cq.textHint,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MetaSummary(note: draft),
                      const SizedBox(height: 12),
                      TextField(
                        key: _contentKey,
                        controller: _contentController,
                        onChanged: _onContentChanged,
                        minLines: 6,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                            fontSize: TypeScale.bodyLarge,
                            height: 1.5,
                            color: context.cq.textPrimary),
                        decoration: const InputDecoration(
                          hintText:
                              'Écris ici. Tape / pour un titre, une liste, du '
                              'code, une image ou une vidéo, et [[ pour lier une '
                              'fiche.',
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
                        noteId: draft.id,
                        linkableNotes:
                            ref.watch(notesProvider).valueOrNull ?? const [],
                        onChanged: (blocks) =>
                            _updateDraft((d) => d.copyWith(blocks: blocks)),
                      ),
                    ],
                  ),
                ),
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
            label: Text(note.subject!,
                style: const TextStyle(fontSize: TypeScale.caption)),
            avatar: const Icon(Icons.folder_outlined, size: 13),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        for (final tag in note.tags)
          Chip(
            label: Text('#$tag',
                style: const TextStyle(fontSize: TypeScale.caption)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        if (importance != NoteImportance.review)
          Chip(
            label: Text(importance.label,
                style: const TextStyle(fontSize: TypeScale.caption)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

/// Aperçu de la fiche en lecture seule : texte mis en forme (souligné,
/// surligné, alignements), liens vers d'autres fiches, images Storage, et
/// PDF annotés ouvrables.
class _RichPreview extends ConsumerWidget {
  const _RichPreview({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
    void openLink(String text, String? href, String title) {
      final id = WikiLinks.noteIdOf(href);
      // Un lien vers une fiche ouvre la fiche ; les autres restent du texte
      // (pas de sortie inattendue de l'app).
      if (id != null) context.push('${AppRoute.notes}/$id');
    }

    return SelectionArea(
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.xxxl),
        children: [
          Text(
            note.displayTitle,
            style: TextStyle(
              fontFamily: appSerifFamily,
              fontSize: TypeScale.display,
              fontWeight: FontWeight.w500,
              letterSpacing: TypeScale.displayTracking,
              height: TypeScale.titleHeight,
              color: cq.textPrimary,
            ),
          ),
          const SizedBox(height: Space.sm),
          _MetaSummary(note: note),
          const SizedBox(height: Space.md),
          if (note.content.trim().isNotEmpty)
            RichMarkdown(
              data: WikiLinks.toMarkdown(note.content, notes),
              selectable: false,
              onTapLink: openLink,
            ),
          for (final block in note.blocks)
            Padding(
              padding: const EdgeInsets.only(top: Space.md),
              child: switch (block.type) {
                NoteBlockType.pdf => PdfBlockCard(content: block.content),
                NoteBlockType.image when block.content.trim().isNotEmpty =>
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: MediaImage(
                        source: block.content.trim(),
                        broken: (context) => Icon(Icons.broken_image_outlined,
                            color: cq.textHint),
                      ),
                    ),
                  ),
                _ => RichMarkdown(
                    data: WikiLinks.toMarkdown(block.toMarkdown(), notes),
                    selectable: false,
                    onTapLink: openLink,
                  ),
              },
            ),
        ],
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
            style: TextStyle(
                fontSize: TypeScale.caption, color: context.cq.textHint),
          ),
        ],
      ),
    );
  }
}
