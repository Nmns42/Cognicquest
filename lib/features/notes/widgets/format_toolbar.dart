import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/highlight_palette.dart';
import '../../../core/theme/tokens.dart';
import '../domain/rich_text_format.dart';

/// Barre de mise en forme du texte d'une fiche, façon traitement de texte :
/// gras, italique, souligné, barré, surlignage en couleur, alignements.
/// Chaque bouton agit sur la sélection de [controller] (ou insère les
/// marqueurs au curseur).
class FormatToolbar extends StatelessWidget {
  const FormatToolbar({
    super.key,
    required this.controller,
    required this.onEdited,
  });

  final TextEditingController controller;

  /// Appelé après chaque mise en forme (sauvegarde automatique).
  final VoidCallback onEdited;

  void _apply(TextEditingValue Function(TextEditingValue) transform) {
    controller.value = transform(controller.value);
    onEdited();
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    Widget tool(IconData icon, String tooltip, VoidCallback onPressed) =>
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: Sizes.iconMd, color: cq.textPrimary),
          onPressed: onPressed,
        );
    Widget separator() => SizedBox(
          height: Sizes.iconLg,
          child: VerticalDivider(
              width: Space.md, thickness: Borders.thin, color: cq.beigeDark),
        );

    return Material(
      color: cq.cardColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cq.beigeDark)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          child: Row(
            children: [
              tool(
                  Icons.format_bold,
                  InlineFormat.bold.label,
                  () => _apply(
                      (v) => RichTextFormat.applyInline(v, InlineFormat.bold))),
              tool(
                  Icons.format_italic,
                  InlineFormat.italic.label,
                  () => _apply((v) =>
                      RichTextFormat.applyInline(v, InlineFormat.italic))),
              tool(
                  Icons.format_underlined,
                  InlineFormat.underline.label,
                  () => _apply((v) =>
                      RichTextFormat.applyInline(v, InlineFormat.underline))),
              tool(
                  Icons.format_strikethrough,
                  InlineFormat.strike.label,
                  () => _apply((v) =>
                      RichTextFormat.applyInline(v, InlineFormat.strike))),
              PopupMenuButton<HighlightColor>(
                popUpAnimationStyle: Motion.style(context),
                tooltip: 'Surligner',
                icon: Icon(Icons.border_color_outlined,
                    size: Sizes.iconMd, color: cq.textPrimary),
                onSelected: (color) =>
                    _apply((v) => RichTextFormat.highlight(v, color)),
                itemBuilder: (context) => [
                  for (final color in HighlightColor.values)
                    PopupMenuItem(
                      value: color,
                      child: Row(
                        children: [
                          Container(
                            width: Sizes.iconMd,
                            height: Sizes.iconMd,
                            decoration: BoxDecoration(
                              color: HighlightPalette.of(
                                  color.name, Theme.of(context).brightness),
                              borderRadius: BorderRadius.circular(Radii.xs),
                              border: Border.all(color: cq.beigeDark),
                            ),
                          ),
                          const SizedBox(width: Space.md),
                          Text('Surligner en ${color.label.toLowerCase()}'),
                        ],
                      ),
                    ),
                ],
              ),
              separator(),
              tool(
                  Icons.format_align_left,
                  LineAlignment.left.label,
                  () => _apply(
                      (v) => RichTextFormat.align(v, LineAlignment.left))),
              tool(
                  Icons.format_align_center,
                  LineAlignment.center.label,
                  () => _apply(
                      (v) => RichTextFormat.align(v, LineAlignment.center))),
              tool(
                  Icons.format_align_right,
                  LineAlignment.right.label,
                  () => _apply(
                      (v) => RichTextFormat.align(v, LineAlignment.right))),
              tool(
                  Icons.format_align_justify,
                  LineAlignment.justify.label,
                  () => _apply(
                      (v) => RichTextFormat.align(v, LineAlignment.justify))),
            ],
          ),
        ),
      ),
    );
  }
}
