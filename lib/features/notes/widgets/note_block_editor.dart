import 'dart:async';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/media/media_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_model.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
import '../../../core/ui/media_image.dart';
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
            controller: block.type == NoteBlockType.divider ||
                    block.type.isMedia
                ? null
                : _controllerFor(block),
            onContentChanged: (rowContext, value) => _onContentChanged(
                rowContext, block, block.content, value),
            onToggleCheck: () =>
                _update(block, block.copyWith(isChecked: !block.isChecked)),
            onMediaChanged: (source) =>
                _update(block, block.copyWith(content: source)),
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
    required this.onMediaChanged,
    required this.onRemove,
  });

  final int index;
  final NoteBlock block;
  final TextEditingController? controller;
  final void Function(BuildContext rowContext, String value)
      onContentChanged;
  final VoidCallback onToggleCheck;
  final ValueChanged<String> onMediaChanged;
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
    if (block.type.isMedia) {
      return _MediaBlock(block: block, onChanged: onMediaChanged);
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
                        block.isChecked ? context.cq.vertSauge : Colors.transparent,
                    border: Border.all(
                      color: block.isChecked
                          ? context.cq.vertSauge
                          : context.cq.beigeDark,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: block.isChecked
                      ? Icon(Icons.check, size: 12, color: context.cq.beige)
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
        NoteBlockType.video => 'URL de la vidéo',
        _ => 'Texte',
      };
}

// ─── Blocs média ────────────────────────────────────────────────────────────

/// Poids maximal d'une image importée (limite du bucket Storage).
const int _maxImageBytes = MediaStore.maxBytes;

/// Bloc image ou vidéo. Vide, il propose d'importer un fichier ou de coller
/// un lien ; rempli, il affiche l'image ou le lecteur vidéo.
///
/// Contenu du bloc :
/// - image : référence Storage `media://…`, lien `http(s)` ou (ancien
///   format) image encodée `data:image/…;base64,…` ;
/// - vidéo : lien `http(s)` (fichier vidéo ou page YouTube) ou chemin d'un
///   fichier de l'appareil (lisible sur cet appareil seulement).
class _MediaBlock extends StatelessWidget {
  const _MediaBlock({required this.block, required this.onChanged});

  final NoteBlock block;
  final ValueChanged<String> onChanged;

  bool get _isImage => block.type == NoteBlockType.image;

  Future<void> _import(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles(
        type: _isImage ? FileType.image : FileType.video,
      );
      final file = files.firstOrNull;
      if (file == null) return;
      if (_isImage) {
        if ((await file.length() ?? 0) > _maxImageBytes) {
          if (!context.mounted) return;
          _snack(context, 'Image trop lourde (5 Mo au plus) : '
                  'colle plutôt un lien.');
          return;
        }
        final bytes = await file.readAsBytes();
        if (!context.mounted) return;
        onChanged(await storeImage(context, bytes, extension: file.extension));
      } else {
        // Sur le web, un fichier choisi n'a pas de chemin durable.
        final path = kIsWeb ? null : file.path;
        if (path == null) {
          if (!context.mounted) return;
          _snack(context, 'Sur le web, ajoute la vidéo par un lien.');
          return;
        }
        onChanged(path);
      }
    } catch (_) {
      if (!context.mounted) return;
      _snack(context, 'Impossible d’ouvrir le sélecteur de fichiers ici.');
    }
  }

  Future<void> _paste(BuildContext context) async {
    final link = await showDialog<String>(
      context: context,
      animationStyle: Motion.style(context),
      builder: (_) => _LinkDialog(isImage: _isImage, initial: block.content),
    );
    if (link != null && link.isNotEmpty) onChanged(link);
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final source = block.content.trim();
    if (source.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: cq.beige,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: cq.beigeDark),
        ),
        child: Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(_isImage ? Icons.image_outlined : Icons.smart_display_outlined,
                size: Sizes.iconMd, color: cq.textMuted),
            Text(_isImage ? 'Image' : 'Vidéo',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: Space.sm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => _import(context),
              icon: const Icon(Icons.upload_file, size: Sizes.iconSm),
              label: const Text('Importer'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => _paste(context),
              icon: const Icon(Icons.link, size: Sizes.iconSm),
              label: const Text('Lien'),
            ),
          ],
        ),
      );
    }

    final media = _isImage
        ? _ImageView(source: source)
        : _VideoView(key: ValueKey(source), source: source);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.md),
          child: media,
        ),
        Positioned(
          top: Space.xs,
          right: Space.xs,
          child: Material(
            color: cq.cardColor,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: _isImage ? 'Remplacer l’image' : 'Remplacer la vidéo',
              icon: Icon(Icons.swap_horiz, size: Sizes.iconSm,
                  color: cq.textMuted),
              onPressed: () => onChanged(''),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageView extends StatelessWidget {
  const _ImageView({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final image = MediaImage(
      source: source,
      broken: (context) => _MediaFallback(
          icon: Icons.broken_image_outlined,
          message: 'Image introuvable',
          detail: source.startsWith('http') ? source : null),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Semantics(image: true, label: 'Image de la fiche', child: image),
    );
  }
}

/// Lecteur vidéo : fichier ou lien direct dans un lecteur intégré ; une
/// page YouTube s'affiche en aperçu (miniature et lien).
class _VideoView extends StatefulWidget {
  const _VideoView({super.key, required this.source});

  final String source;

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  VideoPlayerController? _controller;
  bool _failed = false;

  /// Identifiant d'une vidéo YouTube, ou `null`.
  static String? youTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.firstOrNull;
    }
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ??
          (uri.pathSegments.length > 1 && uri.pathSegments.first == 'shorts'
              ? uri.pathSegments[1]
              : null);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (youTubeId(widget.source) != null) return;
    final isWeb = widget.source.startsWith('http');
    final controller = isWeb
        ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
        : (kIsWeb
            ? null
            : VideoPlayerController.file(File(widget.source)));
    if (controller == null) {
      _failed = true;
      return;
    }
    _controller = controller;
    controller.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
    controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onTick);
      unawaited(controller.dispose().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final youTube = youTubeId(widget.source);
    if (youTube != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://img.youtube.com/vi/$youTube/hqdefault.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: cq.beigeDark),
                ),
                Center(
                  child: Icon(Icons.play_circle_fill,
                      size: Sizes.iconXl * 2, color: cq.cardColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: SelectableText(widget.source,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      );
    }

    final controller = _controller;
    if (_failed || controller == null) {
      return _MediaFallback(
        icon: Icons.videocam_off_outlined,
        message: 'Vidéo illisible ici',
        detail: widget.source,
      );
    }
    if (!controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: cq.beigeDark,
          child: Center(
            child: CircularProgressIndicator(
                strokeWidth: Sizes.spinnerStroke, color: cq.vertDark),
          ),
        ),
      );
    }
    final playing = controller.value.isPlaying;
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(controller),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => playing ? controller.pause() : controller.play(),
                child: Semantics(
                  button: true,
                  label: playing ? 'Mettre en pause' : 'Lire la vidéo',
                  child: Center(
                    child: playing
                        ? const SizedBox.shrink()
                        : Icon(Icons.play_circle_fill,
                            size: Sizes.iconXl * 2, color: cq.cardColor),
                  ),
                ),
              ),
            ),
          ),
          VideoProgressIndicator(controller, allowScrubbing: true),
        ],
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback({required this.icon, required this.message, this.detail});

  final IconData icon;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      color: cq.beige,
      child: Column(
        children: [
          Icon(icon, size: Sizes.iconXl, color: cq.textHint),
          const SizedBox(height: Space.sm),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (detail != null)
            SelectableText(detail!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.isImage, required this.initial});

  final bool isImage;
  final String initial;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final TextEditingController _controller = TextEditingController(
      text: widget.initial.startsWith('http') ? widget.initial : '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.isImage ? 'Lien de l’image' : 'Lien de la vidéo'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: widget.isImage
              ? 'https://…/image.png'
              : 'https://youtu.be/… ou https://…/video.mp4',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(onPressed: _submit, child: const Text('Valider')),
      ],
    );
  }
}

/// Message bref, animé selon le réglage « Réduire les animations ».
void _snack(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)),
      snackBarAnimationStyle: Motion.style(context));
}
