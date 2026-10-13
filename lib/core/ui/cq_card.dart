import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Surface d'une carte.
enum CqCardTone {
  /// Carte posée sur le fond : blanche, filet clair et ombre diffuse.
  raised,

  /// Zone en retrait (aperçu, encart) : teinte du fond, sans filet.
  muted,
}

/// Carte de l'application, au « chrome » de la maquette de référence : filet
/// intérieur clair et ombre très diffuse, sans élévation Material.
///
/// Cliquable si [onTap] est fourni (retour tactile, 48 dp minimum, annoncée
/// comme bouton).
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
    final radius = BorderRadius.circular(Radii.md);

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
      child: Padding(padding: padding, child: child),
    );

    // Carte principale : « chrome » de la maquette (filet intérieur clair,
    // ombre très diffuse). Zone en retrait : teinte du fond, sans relief.
    final decoration = tone == CqCardTone.raised
        ? context.chrome.decoration(color: cq.cardColor)
        : BoxDecoration(color: cq.beigeDark, borderRadius: radius);

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child:
              onTap == null ? content : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}
