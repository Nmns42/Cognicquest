import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'botanical_decorations.dart';

/// Bannière éditoriale : carte blanche à filet fin, titre en serif, un
/// bouquet de feuillage discret à droite, et une bande pierre de chiffres
/// séparés par de fins filets. Le vert forêt reste réservé aux actions.
class BotanicalHeroBanner extends StatelessWidget {
  const BotanicalHeroBanner({
    super.key,
    required this.title,
    required this.stats,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<BotanicalHeroStat> stats;

  /// En dessous, le feuillage gênerait la lecture du titre : il disparaît.
  static const double _foliageMin = 520;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final radius = BorderRadius.circular(Radii.card);

    return DecoratedBox(
      decoration:
          context.chrome.decoration(color: cq.cardColor, radius: Radii.card),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: cq.cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final foliage = constraints.maxWidth >= _foliageMin;
                final foliageWidth =
                    math.min(constraints.maxWidth * 0.4, 300.0);
                return ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: foliage ? Space.xxxl * 3.5 : 0),
                  child: Stack(
                    children: [
                      if (foliage)
                        Positioned(
                          right: Space.lg,
                          top: Space.md,
                          bottom: 0,
                          width: foliageWidth,
                          child: const HeroFoliageOverlay(),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            Space.xl,
                            Space.xl,
                            foliage ? foliageWidth + Space.xl : Space.xl,
                            Space.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: Space.sm),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                    color: cq.textMuted,
                                    fontSize: TypeScale.body),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cq.sauge,
                  border: Border(top: BorderSide(color: cq.beigeDark)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.xl, vertical: Space.lg),
                  child: _HeroStats(stats: stats),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un chiffre de la bande sombre, avec sa légende et un ornement éventuel
/// (couronne de laurier…).
class BotanicalHeroStat extends StatelessWidget {
  const BotanicalHeroStat({
    super.key,
    required this.value,
    required this.label,
    this.leading,
  });

  final String value;
  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: Space.md)],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: context.cq.textPrimary,
                  fontSize: TypeScale.title,
                  fontWeight: FontWeight.w700,
                  fontFeatures: TypeScale.tabular,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                    color: context.cq.textMuted, fontSize: TypeScale.caption),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chiffres en colonnes séparées de filets verticaux, ou empilés sur un
/// écran étroit (et à 200 % de texte).
class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.stats});

  final List<BotanicalHeroStat> stats;

  static const double _columnsMin = 560;

  @override
  Widget build(BuildContext context) {
    final rule = context.cq.beigeDark;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < _columnsMin) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, stat) in stats.indexed) ...[
              if (i > 0)
                Divider(height: Space.lg, thickness: Borders.thin, color: rule),
              stat,
            ],
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, stat) in stats.indexed) ...[
              if (i > 0)
                VerticalDivider(
                    width: Space.xl, thickness: Borders.thin, color: rule),
              Expanded(child: stat),
            ],
          ],
        ),
      );
    });
  }
}

/// Panneau latéral « Arbre de détente » (grand écran) : l'arbre compagnon,
/// qui grandit avec la régularité ([growth], 0 à 1), et des rappels
/// métacognitifs.
class MindfulTreePanel extends StatelessWidget {
  const MindfulTreePanel({
    super.key,
    required this.growth,
    this.caption,
    this.advice,
  });

  final double growth;

  /// Phrase sous l'arbre ; par défaut, la régularité sur 30 jours.
  final Widget? caption;

  /// Conseils personnalisés ; par défaut, des rappels génériques.
  final Widget? advice;

  static const List<(IconData, String)> _reminders = [
    (
      Icons.self_improvement_outlined,
      'Avant de commencer, pose une intention claire pour la séance.'
    ),
    (
      Icons.psychology_alt_outlined,
      "Qu'est-ce qui t'a aidé hier ? Refais-le aujourd'hui."
    ),
    (
      Icons.spa_outlined,
      "Une pause de 5 minutes consolide ce que tu viens d'apprendre."
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, Space.xl, Space.xl, Space.xl),
      child: DecoratedBox(
        decoration:
            context.chrome.decoration(color: cq.cardColor, radius: Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Arbre de détente',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Space.sm),
              AspectRatio(
                aspectRatio: 1,
                child: MindfulTreeIllustration(growth: growth),
              ),
              caption ??
                  Text(
                    'Il grandit avec ta régularité : '
                    '${(growth.clamp(0.0, 1.0) * 100).round()} % sur 30 jours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: TypeScale.caption, color: cq.textMuted),
                  ),
              const SizedBox(height: Space.lg),
              if (advice != null) advice!,
              if (advice == null)
                for (final (icon, text) in _reminders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cq.sauge,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: Sizes.iconMd, color: cq.vertSauge),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                    fontSize: TypeScale.caption,
                                    color: cq.textPrimary),
                              ),
                            ),
                          ],
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

/// Pastille ronde sauge ou écorce ([warm]) : un chiffre (série, score) ou
/// une icône, en couleur du fond de l'app (≥ 4,5:1 sur les deux teintes).
class CqScoreBadge extends StatelessWidget {
  const CqScoreBadge({
    super.key,
    this.value,
    this.icon,
    this.semanticLabel,
    this.warm = false,
    this.dimension = Sizes.iconXl + Space.xs,
  }) : assert(value != null || icon != null);

  final String? value;
  final IconData? icon;
  final String? semanticLabel;
  final bool warm;

  /// Diamètre minimal ; la pastille s'allonge si le chiffre est long.
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final badge = Container(
      constraints: BoxConstraints(minWidth: dimension, minHeight: dimension),
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: warm ? cq.terre : cq.vertSauge,
        // Cercle pour un ou deux chiffres, pastille au-delà.
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
            color: cq.beige.withValues(alpha: 0.5), width: Borders.focus),
      ),
      child: icon != null
          ? Icon(icon, size: Sizes.iconMd, color: cq.beige)
          : Text(
              value!,
              style: TextStyle(
                fontSize: TypeScale.body,
                fontWeight: FontWeight.w700,
                color: cq.beige,
              ),
            ),
    );
    if (semanticLabel == null) return badge;
    return Semantics(
        label: semanticLabel, excludeSemantics: true, child: badge);
  }
}
