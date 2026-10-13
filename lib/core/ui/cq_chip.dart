import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Puce de filtre ou de choix. La sélection se lit aussi à la coche, pas à la
/// seule couleur ; la zone tactile fait 48 dp même si la puce paraît fine.
class CqChip extends StatelessWidget {
  const CqChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      checkmarkColor: context.cq.vertDark,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      labelStyle: TextStyle(
        fontFamily: appFontFamily,
        fontSize: TypeScale.body,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? context.cq.vertDark : context.cq.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
    );
  }
}
