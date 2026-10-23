import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';

/// Sélecteur sur une échelle de 1 à [max].
///
/// Boutons plutôt qu'un `Slider` : sur une échelle de 5 ou 10 crans, viser une
/// valeur précise au doigt est pénible, et la valeur choisie doit rester
/// lisible sans manipulation.
class ScalePicker extends StatelessWidget {
  const ScalePicker({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  /// Teinte de l'échelle : neutre pour l'humeur et l'énergie, alerte quand
  /// l'effort ressenti monte haut.
  Color _colorFor(BuildContext context, int level) {
    if (max == 10 && level >= 8) return context.cq.errorColor;
    if (max == 10 && level >= 6) return context.cq.warning;
    return context.cq.vertSauge;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style:  TextStyle(
                fontSize: TypeScale.body,
                fontWeight: FontWeight.w600,
                color: context.cq.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$value / $max',
              style: TextStyle(
                fontSize: TypeScale.body,
                fontWeight: FontWeight.w700,
                color: _colorFor(context, value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(hint,
            style:  TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var level = 1; level <= max; level++) ...[
              if (level > 1) const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  selected: level == value,
                  label: '$label : $level sur $max',
                  child: InkWell(
                    onTap: () => onChanged(level),
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: AnimatedContainer(
                      duration: Motion.duration(context, const Duration(milliseconds: 150)),
                      // Hauteur confortable au doigt même à 10 crans.
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: level <= value
                            ? _colorFor(context, value)
                            : context.cq.beigeDark.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            '$level',
                            style: TextStyle(
                              fontSize: TypeScale.caption,
                              fontWeight: FontWeight.w600,
                              color: level <= value
                                  ? context.cq.beige
                                  : context.cq.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
