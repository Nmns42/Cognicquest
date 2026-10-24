import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/media/media_store.dart';
import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/highlight_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/media_image.dart';
import '../domain/pdf_annotations.dart';

/// Bloc « PDF » d'une fiche : vide, il propose d'importer un fichier ;
/// rempli, il affiche le document et ouvre l'annotateur.
class PdfBlockCard extends ConsumerWidget {
  const PdfBlockCard({
    super.key,
    required this.content,
    this.onChanged,
  });

  /// Contenu du bloc (JSON, cf. [PdfBlockData]).
  final String content;

  /// `null` : lecture seule (aperçu de la fiche).
  final ValueChanged<String>? onChanged;

  Future<void> _import(BuildContext context) async {
    void tell(String text) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
        snackBarAnimationStyle: Motion.style(context));
    try {
      final file = (await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      ))
          .firstOrNull;
      if (file == null) return;
      if ((await file.length() ?? 0) > MediaStore.maxPdfBytes) {
        if (context.mounted) tell('PDF trop lourd (20 Mo au plus).');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      final source = await storeImage(context, bytes, extension: 'pdf');
      onChanged?.call(PdfBlockData(source: source, name: file.name).encode());
    } catch (_) {
      if (context.mounted) {
        tell('Impossible d’ouvrir le sélecteur de fichiers ici.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final data = PdfBlockData.decode(content);

    if (data.isEmpty) {
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
            Icon(Icons.picture_as_pdf_outlined,
                size: Sizes.iconMd, color: cq.textMuted),
            Text('PDF', style: Theme.of(context).textTheme.titleSmall),
            if (onChanged != null)
              OutlinedButton.icon(
                onPressed: () => _import(context),
                icon: const Icon(Icons.upload_file, size: Sizes.iconSm),
                label: const Text('Importer un PDF'),
              ),
          ],
        ),
      );
    }

    final count = data.marks.length;
    return Material(
      color: cq.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: cq.beigeDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PdfAnnotatorPage(
            data: data,
            onChanged: onChanged == null
                ? null
                : (updated) => onChanged!(updated.encode()),
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined,
                  size: Sizes.iconLg, color: cq.terre),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: TypeScale.body,
                            fontWeight: FontWeight.w600,
                            color: cq.textPrimary)),
                    Text(
                      count == 0
                          ? (onChanged == null
                              ? 'Ouvrir le document'
                              : 'Ouvrir et annoter')
                          : '$count annotation${count > 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: TypeScale.caption, color: cq.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cq.vertSauge),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lecture et annotation d'un PDF : sélectionner un passage, puis le
/// surligner, le souligner ou le barrer dans la couleur choisie. Les
/// annotations sont gardées en coordonnées PDF (indépendantes du zoom).
class PdfAnnotatorPage extends ConsumerStatefulWidget {
  const PdfAnnotatorPage({super.key, required this.data, this.onChanged});

  final PdfBlockData data;

  /// `null` : lecture seule.
  final ValueChanged<PdfBlockData>? onChanged;

  @override
  ConsumerState<PdfAnnotatorPage> createState() => _PdfAnnotatorPageState();
}

class _PdfAnnotatorPageState extends ConsumerState<PdfAnnotatorPage> {
  final _controller = PdfViewerController();
  late List<PdfMark> _marks = [...widget.data.marks];
  String _color = 'jaune';
  bool _hasSelection = false;

  /// Passages sélectionnés, relus à chaque changement : toucher un bouton
  /// d'outil peut effacer la sélection du lecteur avant qu'on la lise.
  List<PdfPageTextRange> _ranges = const [];

  bool get _editable => widget.onChanged != null;

  void _save() =>
      widget.onChanged?.call(widget.data.copyWith(marks: List.of(_marks)));

  void _annotate(PdfMarkKind kind) {
    final ranges = _ranges;
    if (ranges.isEmpty) return;
    final added = <PdfMark>[];
    for (final range in ranges) {
      final boxes = [
        for (final fragment in range.enumerateFragmentBoundingRects())
          PdfBox(fragment.bounds.left, fragment.bounds.top,
              fragment.bounds.right, fragment.bounds.bottom),
      ];
      if (boxes.isEmpty) continue;
      added.add(PdfMark(
        id: '${DateTime.now().microsecondsSinceEpoch}-${range.pageNumber}',
        page: range.pageNumber,
        kind: kind,
        color: _color,
        boxes: boxes,
        text: range.text.trim(),
      ));
    }
    // Enregistré d'abord : effacer la sélection ensuite, sans l'attendre.
    setState(() {
      _marks = [..._marks, ...added];
      _hasSelection = false;
      _ranges = const [];
    });
    _save();
    unawaited(_controller.textSelectionDelegate.clearTextSelection());
  }

  void _remove(PdfMark mark) {
    setState(() => _marks = [..._marks]..removeWhere((m) => m.id == mark.id));
    _save();
  }

  Future<void> _showMarks() => showModalBottomSheet<void>(
        context: context,
        sheetAnimationStyle: Motion.style(context),
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final cq = sheetContext.cq;
            final marks = [..._marks]..sort((a, b) => a.page.compareTo(b.page));
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
                child: marks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(Space.xl),
                        child: Text(
                          'Aucune annotation. Sélectionne un passage du PDF, '
                          'puis choisis Surligner, Souligner ou Barrer.',
                          style: TextStyle(
                              fontSize: TypeScale.body, color: cq.textMuted),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final mark in marks)
                            ListTile(
                              leading: Icon(_iconFor(mark.kind),
                                  color: HighlightPalette.ink(mark.color)),
                              title: Text(
                                mark.text.isEmpty ? mark.kind.label : mark.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                  '${mark.kind.label} · page ${mark.page}'),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                _controller.goToPage(pageNumber: mark.page);
                              },
                              trailing: _editable
                                  ? IconButton(
                                      tooltip: 'Supprimer l’annotation',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () {
                                        _remove(mark);
                                        setSheetState(() {});
                                      },
                                    )
                                  : null,
                            ),
                        ],
                      ),
              ),
            );
          },
        ),
      );

  static IconData _iconFor(PdfMarkKind kind) => switch (kind) {
        PdfMarkKind.highlight => Icons.border_color_outlined,
        PdfMarkKind.underline => Icons.format_underlined,
        PdfMarkKind.strike => Icons.format_strikethrough,
      };

  List<Widget> _overlays(BuildContext context, Rect pageRect, PdfPage page) => [
        for (final mark in _marks)
          if (mark.page == page.pageNumber)
            for (final box in mark.boxes)
              () {
                final rect = PdfRect(box.left, box.top, box.right, box.bottom)
                    .toRect(page: page, scaledPageSize: pageRect.size);
                final ink = HighlightPalette.ink(mark.color);
                final line = (rect.height * 0.09).clamp(1.0, 4.0);
                return Positioned.fromRect(
                  rect: rect,
                  child: IgnorePointer(
                    child: switch (mark.kind) {
                      PdfMarkKind.highlight => ColoredBox(
                          color:
                              HighlightPalette.of(mark.color, Brightness.light)
                                  .withValues(alpha: 0.5)),
                      PdfMarkKind.underline => Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                              height: line,
                              width: double.infinity,
                              child: ColoredBox(color: ink))),
                      PdfMarkKind.strike => Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                              height: line,
                              width: double.infinity,
                              child: ColoredBox(color: ink))),
                    },
                  ),
                );
              }(),
      ];

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final bytes = ref.watch(mediaBytesProvider(widget.data.source));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data.name, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton.icon(
            onPressed: _showMarks,
            icon: const Icon(Icons.list_alt_outlined, size: Sizes.iconMd),
            label: Text('${_marks.length}',
                style: const TextStyle(fontFeatures: TypeScale.tabular)),
          ),
        ],
      ),
      body: bytes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Unavailable(cq: cq),
        data: (data) => data == null
            ? _Unavailable(cq: cq)
            : PdfViewer.data(
                data,
                sourceName: widget.data.source,
                controller: _controller,
                params: PdfViewerParams(
                  backgroundColor: cq.parchemin,
                  pageOverlaysBuilder: _overlays,
                  textSelectionParams: PdfTextSelectionParams(
                    // Pas de menu contextuel : la barre d'outils en bas le
                    // remplace (le menu captait le premier appui hors du
                    // document, qui ne déclenchait donc pas l'outil).
                    showContextMenuAutomatically: false,
                    onTextSelectionChange: (selection) async {
                      final has = selection.hasSelectedText;
                      final ranges = has
                          ? await selection.getSelectedTextRanges()
                          : const <PdfPageTextRange>[];
                      if (!mounted) return;
                      setState(() {
                        _hasSelection = has && ranges.isNotEmpty;
                        _ranges = ranges;
                      });
                    },
                  ),
                ),
              ),
      ),
      bottomNavigationBar: !_editable
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.md, vertical: Space.sm),
                decoration: BoxDecoration(
                  color: cq.cardColor,
                  border: Border(top: BorderSide(color: cq.beigeDark)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _hasSelection
                          ? 'Passage sélectionné : choisis une couleur et un outil.'
                          : 'Sélectionne un passage du PDF pour l’annoter.',
                      style: TextStyle(
                          fontSize: TypeScale.caption, color: cq.textMuted),
                    ),
                    const SizedBox(height: Space.sm),
                    Row(
                      children: [
                        for (final name in const [
                          'jaune',
                          'vert',
                          'bleu',
                          'rose',
                          'orange',
                        ]) ...[
                          _ColorDot(
                            name: name,
                            selected: _color == name,
                            onTap: () => setState(() => _color = name),
                          ),
                          const SizedBox(width: Space.sm),
                        ],
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    Row(
                      children: [
                        for (final (i, kind) in PdfMarkKind.values.indexed) ...[
                          if (i > 0) const SizedBox(width: Space.sm),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, Sizes.touchTarget),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Space.sm),
                              ),
                              onPressed:
                                  _hasSelection ? () => _annotate(kind) : null,
                              icon: Icon(_iconFor(kind), size: Sizes.iconSm),
                              label: FittedBox(child: Text(kind.label)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Couleur $name',
      child: InkResponse(
        onTap: onTap,
        radius: Sizes.touchTarget / 2,
        child: Container(
          width: Sizes.iconLg + Space.xs,
          height: Sizes.iconLg + Space.xs,
          decoration: BoxDecoration(
            color: HighlightPalette.of(name, Brightness.light),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? cq.textPrimary : cq.beigeDark,
              width: selected ? Borders.focus : Borders.thin,
            ),
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.cq});

  final CognicColors cq;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Text(
            'PDF indisponible : il n’est pas encore sur cet appareil. '
            'Reconnecte-toi pour le télécharger.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: TypeScale.body, color: cq.textMuted),
          ),
        ),
      );
}
