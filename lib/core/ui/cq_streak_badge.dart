import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Pastille de série (habitudes, sessions) : aplat ambre et texte foncé.
///
/// L'ambre ne se lit pas en texte sur un fond clair (1,6:1) : il porte donc
/// le fond, et [CognicColors.onAmbre] le texte (8,9:1).
class CqStreakBadge extends StatelessWidget {
  const CqStreakBadge({super.key, required this.label});

  /// Texte affiché, par ex. « 🔥 3 j ».
  final String label;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.sm, vertical: Space.xs / 2),
      decoration: BoxDecoration(
        color: cq.ambre,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: TypeScale.caption,
          fontWeight: FontWeight.w700,
          color: cq.onAmbre,
        ),
      ),
    );
  }
}
