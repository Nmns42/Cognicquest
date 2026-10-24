import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/highlight_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/media_image.dart';
import '../domain/rich_text_format.dart';

/// `++texte++` → souligné.
class UnderlineSyntax extends md.InlineSyntax {
  UnderlineSyntax() : super(r'\+\+(.+?)\+\+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('u', match[1]!));
    return true;
  }
}

/// `==texte==` ou `=={vert}texte==` → surligné.
class HighlightSyntax extends md.InlineSyntax {
  HighlightSyntax() : super(r'==(?:\{([a-z]+)\})?(.+?)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match[2]!)
      ..attributes['color'] = match[1] ?? 'jaune');
    return true;
  }
}

/// Rendu en ligne : un `Text.rich`, que flutter_markdown fusionne au
/// paragraphe (le texte continue sur la même ligne).
class _StyledInlineBuilder extends MarkdownElementBuilder {
  _StyledInlineBuilder(this.styleFor);

  final TextStyle Function(md.Element element) styleFor;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) =>
      Text.rich(TextSpan(
        text: element.textContent,
        style: (parentStyle ?? preferredStyle ?? const TextStyle())
            .merge(styleFor(element)),
      ));
}

/// Markdown des fiches avec les ajouts de CognicQuest : souligné, surligné
/// en couleur, alignement par ligne, images déposées dans Storage.
class RichMarkdown extends StatelessWidget {
  const RichMarkdown({
    super.key,
    required this.data,
    this.onTapLink,
    this.selectable = true,
  });

  final String data;
  final MarkdownTapLinkCallback? onTapLink;
  final bool selectable;

  /// Grec, cyrillique, flèches : absents des polices de l'app.
  static const List<String> fallback = appFontFallback;

  static MarkdownStyleSheet styleSheet(BuildContext context) {
    final cq = context.cq;
    TextStyle heading(double size, FontWeight weight, {bool serif = false}) =>
        TextStyle(
          fontFamily: serif ? appSerifFamily : null,
          fontSize: size,
          fontWeight: weight,
          color: cq.textPrimary,
          height: TypeScale.titleHeight,
          fontFamilyFallback: fallback,
        );
    return MarkdownStyleSheet(
      h1: heading(TypeScale.headline, FontWeight.w500, serif: true),
      h2: heading(TypeScale.title, FontWeight.w500, serif: true),
      h3: heading(TypeScale.bodyLarge, FontWeight.w600),
      h4: heading(TypeScale.body, FontWeight.w700),
      h5: heading(TypeScale.body, FontWeight.w600)
          .copyWith(color: cq.textMuted),
      h6: heading(TypeScale.caption, FontWeight.w600)
          .copyWith(color: cq.textMuted),
      p: TextStyle(
          fontSize: TypeScale.bodyLarge,
          height: TypeScale.bodyHeight,
          color: cq.textPrimary,
          fontFamilyFallback: fallback),
      blockquoteDecoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border(left: BorderSide(color: cq.vertSauge, width: 3)),
      ),
      code: TextStyle(
          fontSize: TypeScale.body,
          backgroundColor: cq.beigeDark,
          color: cq.textPrimary),
      codeblockDecoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: cq.beigeDark),
      ),
    );
  }

  static WrapAlignment _wrapFor(LineAlignment alignment) => switch (alignment) {
        LineAlignment.left => WrapAlignment.start,
        LineAlignment.center => WrapAlignment.center,
        LineAlignment.right => WrapAlignment.end,
        // flutter_markdown traduit spaceBetween en TextAlign.justify.
        LineAlignment.justify => WrapAlignment.spaceBetween,
      };

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final base = styleSheet(context);
    final extensions = md.ExtensionSet(
      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      [
        UnderlineSyntax(),
        HighlightSyntax(),
        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      ],
    );
    final builders = <String, MarkdownElementBuilder>{
      'u': _StyledInlineBuilder(
          (_) => const TextStyle(decoration: TextDecoration.underline)),
      'mark': _StyledInlineBuilder((element) => TextStyle(
          backgroundColor: HighlightPalette.of(
              element.attributes['color'] ?? 'jaune', brightness))),
    };

    Widget image(Uri uri, String? title, String? alt) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: MediaImage(
                source: uri.toString(),
                broken: (context) => Icon(Icons.broken_image_outlined,
                    color: context.cq.textHint),
              ),
            ),
          ),
        );

    final segments = RichTextFormat.segments(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (alignment, text) in segments)
          if (text.trim().isNotEmpty)
            MarkdownBody(
              data: text,
              selectable: selectable,
              extensionSet: extensions,
              builders: builders,
              imageBuilder: image,
              onTapLink: onTapLink,
              styleSheet: base.copyWith(
                textAlign: _wrapFor(alignment),
                h1Align: _wrapFor(alignment),
                h2Align: _wrapFor(alignment),
                h3Align: _wrapFor(alignment),
                h4Align: _wrapFor(alignment),
                h5Align: _wrapFor(alignment),
                h6Align: _wrapFor(alignment),
              ),
            ),
      ],
    );
  }
}
