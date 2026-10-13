import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Surface d'une carte.
enum CqCardTone {
  /// Carte posée sur le fond : légèrement plus claire, avec un filet.
  raised,

  /// Zone en retrait (aperçu, encart) : teinte du fond, sans filet.
  muted,
}

/// Carte sans ombre : le relief vient de la teinte et d'un filet, pas d'une
/// élévation. Cliquable si [onTap] est fourni (retour tactile, 48 dp
/// minimum, annoncée comme bouton).
class CqCard extends StatelessWidget {
  const CqCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.lg),
    this.tone = CqCardTone.raised,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final CqCardTone tone;

  /// Libellé lu par les lecteurs d'écran quand la carte est cliquable.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      side: tone == CqCardTone.raised
          ? BorderSide(color: cq.beigeDark, width: Borders.thin)
          : BorderSide.none,
    );

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
      child: Padding(padding: padding, child: child),
    );

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: tone == CqCardTone.raised ? cq.cardColor : cq.beigeDark,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
