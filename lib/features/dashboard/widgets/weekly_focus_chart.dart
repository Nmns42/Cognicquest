import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/pomodoro_session_model.dart';
import '../providers/dashboard_stats_provider.dart';

/// Graphe du temps de focus des 7 derniers jours.
///
/// Choix de forme et d'encodage (règles de dataviz appliquées) :
///  - **Série unique** → une seule couleur pour *toutes* les barres. On ne
///    fonce pas la barre la plus haute : ce serait double-encoder la longueur
///    en teinte, sans rien apprendre au lecteur.
///  - Teinte [context.cq.vertDark] et non [context.cq.vert] : le vert clair tombe
///    à 2,91:1 sur fond blanc, sous le seuil de 3:1 ; la variante foncée passe.
///  - **Labels sélectifs** : seuls le meilleur jour et aujourd'hui portent leur
///    valeur. Une valeur sur chaque barre serait illisible.
///  - Chaque barre reste accessible au lecteur d'écran et au survol : la
///    valeur n'est jamais réservée à l'infobulle.
///  - Ligne de base pleine, d'un seul ton au-dessus du fond ; pas de pointillés,
///    pas de bordure autour des barres, un écart de 2 px entre elles.
class WeeklyFocusChart extends StatelessWidget {
  const WeeklyFocusChart({super.key, required this.stats});

  final DashboardStats stats;

  static const double _plotHeight = 92;


  @override
  Widget build(BuildContext context) {
    final series = stats.weeklySeries;
    if (series.isEmpty) return const SizedBox.shrink();

    final maxSeconds = series
        .map((d) => d.focus.inSeconds)
        .fold<int>(0, (max, value) => value > max ? value : max);
    final bestSeconds = maxSeconds;
    // Teinte foncée : le vert clair tombe sous 3:1 sur fond clair.
    final barColor = context.cq.vertDark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Le titre nomme la série : pas de légende pour une série unique.
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Focus des 7 derniers jours',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  formatFocusDuration(stats.focusThisWeek),
                  style:  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.cq.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
             Text(
              'Total sur la période',
              style: TextStyle(fontSize: 12, color: context.cq.textMuted),
            ),
            const SizedBox(height: 16),

            if (!stats.hasAnyFocus)
              const _EmptyPlot()
            else
              // La hauteur englobe le tracé *et* la bande des jours : la carte
              // ne doit jamais rogner ses propres étiquettes d'axe.
              SizedBox(
                height: _plotHeight + _Bar.chromeHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final day in series)
                      Expanded(
                        child: _Bar(
                          day: day,
                          maxSeconds: maxSeconds,
                          isBest: bestSeconds > 0 &&
                              day.focus.inSeconds == bestSeconds,
                          plotHeight: _plotHeight,
                          color: barColor,
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
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.maxSeconds,
    required this.isBest,
    required this.plotHeight,
    required this.color,
  });

  final DailyFocus day;
  final int maxSeconds;
  final bool isBest;
  final double plotHeight;
  final Color color;

  /// Un jour sans focus garde un trait visible : « zéro » est une donnée, pas
  /// une absence de barre.
  static const double _zeroHeight = 3;

  static const double _dayLabelHeight = 16;

  /// Tout ce que la colonne empile en plus de la barre : étiquette de valeur
  /// (16), espace (4), ligne de base (1), espace (6), initiale du jour.
  static const double chromeHeight = 16 + 4 + 1 + 6 + _dayLabelHeight;

  @override
  Widget build(BuildContext context) {
    final seconds = day.focus.inSeconds;
    final ratio = maxSeconds == 0 ? 0.0 : seconds / maxSeconds;
    final height = seconds == 0 ? _zeroHeight : (ratio * plotHeight).clamp(6.0, plotHeight);

    // Étiquetage sélectif : le meilleur jour et aujourd'hui, jamais les sept.
    final showsLabel = (isBest || day.isToday) && seconds > 0;

    final valueLabel = formatFocusDuration(day.focus);
    final semanticsLabel = seconds == 0
        ? '${day.fullLabel} : aucune session'
        : '${day.fullLabel} : $valueLabel de focus, '
            '${day.sessions} session${day.sessions > 1 ? 's' : ''}';

    return Semantics(
      label: semanticsLabel,
      child: Tooltip(
        message: semanticsLabel,
        child: Padding(
          // 2 px de part et d'autre : l'écart entre barres est du fond, pas un
          // trait de séparation.
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 16,
                child: showsLabel
                    ? FittedBox(
                        child: Text(
                          valueLabel,
                          // Le texte porte une couleur d'encre, jamais celle de
                          // la série.
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: day.isToday
                                ? context.cq.textPrimary
                                : context.cq.textMuted,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: height),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Container(
                  height: value,
                  decoration: BoxDecoration(
                    color: seconds == 0
                        ? context.cq.beigeDark
                        : color.withValues(alpha: day.isToday ? 1 : 0.75),
                    // Extrémité arrondie côté donnée, ancrée à la ligne de base.
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              // Ligne de base : un hairline plein, un ton au-dessus du fond.
              Container(height: 1, color: context.cq.beigeDark),
              const SizedBox(height: 6),
              // Hauteur fixe : la hauteur naturelle d'un texte dépend de la
              // police et de l'échelle choisie dans les réglages, et quelques
              // dixièmes de pixel de trop suffisaient à faire déborder la
              // colonne sous la barre la plus haute.
              SizedBox(
                height: _dayLabelHeight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    day.initial,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          day.isToday ? FontWeight.w700 : FontWeight.w500,
                      color: day.isToday
                          ? context.cq.textPrimary
                          : context.cq.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlot extends StatelessWidget {
  const _EmptyPlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: context.cq.beigeDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child:  Text(
        'Aucune session cette semaine.\nTa première session apparaîtra ici.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.cq.textMuted, fontSize: 13, height: 1.4),
      ),
    );
  }
}
