import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';

/// Tendance de l'humeur sur 7 jours.
///
/// Règles de dataviz déjà appliquées aux Lots 3 et 6 : série unique donc une
/// seule teinte (jamais un dégradé par valeur), teinte foncée pour tenir le
/// contraste, étiquettes sélectives, ligne de base pleine, valeurs lisibles
/// sans survol.
///
/// Particularité ici : un jour **non renseigné** n'est pas un jour à zéro. Il
/// est dessiné comme un creux vide, et jamais relié au jour suivant — ce qui
/// laisserait croire à une chute du moral.
class MoodTrendChart extends StatelessWidget {
  const MoodTrendChart({super.key, required this.trend});

  /// Humeur moyenne par jour, du plus ancien au plus récent. `null` = non noté.
  final List<double?> trend;

  static const double _plotHeight = 64;
  static const double _maxMood = 5;

  static const List<String> _dayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final today = DateTime.now();
    final logged = trend.whereType<double>().toList();
    if (logged.isEmpty) return const SizedBox.shrink();

    final best = logged.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Humeur des 7 derniers jours',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${logged.length} jour${logged.length > 1 ? 's' : ''} noté'
              '${logged.length > 1 ? 's' : ''} sur 7',
              style:  TextStyle(fontSize: 12, color: context.cq.textMuted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _plotHeight + 38,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < trend.length; i++)
                    Expanded(
                      child: _MoodBar(
                        value: trend[i],
                        isBest: trend[i] != null && trend[i] == best,
                        isToday: i == trend.length - 1,
                        initial: _dayInitials[
                            today
                                    .subtract(Duration(days: trend.length - 1 - i))
                                    .weekday -
                                1],
                        plotHeight: _plotHeight,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double get maxMood => _maxMood;
}

class _MoodBar extends StatelessWidget {
  const _MoodBar({
    required this.value,
    required this.isBest,
    required this.isToday,
    required this.initial,
    required this.plotHeight,
  });

  final double? value;
  final bool isBest;
  final bool isToday;
  final String initial;
  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    final mood = value;
    final label = mood == null ? 'non noté' : '${mood.toStringAsFixed(1)} / 5';
    final semantics = 'Jour $initial : $label';

    // Étiquetage sélectif : le meilleur jour et aujourd'hui seulement.
    final showsLabel = mood != null && (isBest || isToday);

    return Semantics(
      label: semantics,
      child: Tooltip(
        message: semantics,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 15,
                child: showsLabel
                    ? FittedBox(
                        child: Text(
                          mood.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? context.cq.textPrimary
                                : context.cq.textMuted,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              if (mood == null)
                // Jour non renseigné : un creux discret, pas une barre à zéro.
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.cq.beigeDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: (mood / MoodTrendChart.maxMood * plotHeight)
                        .clamp(6.0, plotHeight),
                  ),
                  duration: Motion.duration(context, const Duration(milliseconds: 420)),
                  curve: Curves.easeOutCubic,
                  builder: (context, height, _) => Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: context.cq.vertDark
                          .withValues(alpha: isToday ? 1 : 0.75),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              Container(height: 1, color: context.cq.beigeDark),
              const SizedBox(height: 5),
              Text(
                initial,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? context.cq.textPrimary : context.cq.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
