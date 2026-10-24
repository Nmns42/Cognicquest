import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../coach/providers/coach_provider.dart';
import '../../coach/widgets/coach_advice_list.dart';
import '../../../shared/models/metacognition_model.dart';
import '../domain/metacognition_insights.dart';
import '../providers/metacognition_provider.dart';
import '../widgets/mood_trend_chart.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';

/// Point d'entrée de la métacognition : état du moment, outils, historique.
class JournalHubPage extends ConsumerStatefulWidget {
  const JournalHubPage({super.key});

  @override
  ConsumerState<JournalHubPage> createState() => _JournalHubPageState();
}

class _JournalHubPageState extends ConsumerState<JournalHubPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(metacognitionActionsProvider).sync();
    });
  }

  /// Largeur à partir de laquelle l'arbre s'affiche à droite.
  static const double _wideMin = 900;
  static const double _sideWidth = 300;

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(metacognitionInsightsProvider);
    final profile = ref.watch(learningProfileProvider).valueOrNull;
    final todayEntry = ref.watch(todayJournalEntryProvider);
    final errorPattern = ref.watch(errorPatternProvider);
    final unfinished = ref.watch(unfinishedReframesProvider);
    final entries =
        ref.watch(journalProvider).valueOrNull ?? const <JournalEntry>[];
    const tree = _GrowthTreeCard();

    List<Widget> content({required bool withTree}) => [
          _RetrospectiveCard(
            hasEntryToday: todayEntry != null,
            onWrite: () => context.push(AppRoute.journalEntry),
          ),
          const SizedBox(height: Space.xl),
          _StrainCard(insights: insights, hasEntryToday: todayEntry != null),
          if (insights.entryCount > 0) ...[
            const SizedBox(height: Space.lg),
            MoodTrendChart(trend: insights.moodTrend),
          ],
          const SizedBox(height: Space.xl),
          const _SectionLabel("Outils d'évaluation"),
          const SizedBox(height: Space.md),
          _ToolTile(
            icon: Icons.psychology_alt_outlined,
            title: 'Recadrage cognitif',
            subtitle: 'Identifier une pensée bloquante, '
                'puis la transformer en premier pas',
            badge: unfinished.isEmpty ? null : '${unfinished.length}',
            onTap: () => context.push(AppRoute.reframe),
          ),
          const SizedBox(height: Space.md),
          _ToolTile(
            icon: Icons.rule_outlined,
            title: 'Analyse des erreurs',
            subtitle: errorPattern.isEmpty
                ? 'Comprendre la cause de chaque erreur'
                : '${errorPattern.total} erreur'
                    '${errorPattern.total > 1 ? 's' : ''} consignée'
                    '${errorPattern.total > 1 ? 's' : ''}',
            onTap: () => context.push(AppRoute.errorLogs),
          ),
          const SizedBox(height: Space.md),
          _ToolTile(
            icon: Icons.fingerprint,
            title: 'Mon profil d\'apprentissage',
            subtitle: profile?.isComplete ?? false
                ? [
                    profile!.processingStyle?.label,
                    profile.preferredChannel?.label,
                  ].whereType<String>().join(' · ')
                : 'Comment tu apprends le mieux',
            onTap: () => context.push(AppRoute.profiling),
          ),
          if (!errorPattern.isEmpty) ...[
            const SizedBox(height: Space.xl),
            // Refermable ; il revient quand le constat change.
            CqDismissibleBanner(
              bannerId: 'journal.erreurs.${errorPattern.summary.hashCode}',
              icon: Icons.rule_outlined,
              message: errorPattern.summary,
            ),
          ],
          if (withTree) ...[
            const SizedBox(height: Space.xl),
            tree,
          ],
          if (entries.isNotEmpty) ...[
            const SizedBox(height: Space.xl),
            const _SectionLabel('Bilans récents'),
            const SizedBox(height: Space.md),
            for (final entry in entries.take(8)) _JournalRow(entry: entry),
          ],
        ];

    return Scaffold(
      appBar: AppBar(title: const Text('Journal de réflexion')),
      body: RefreshIndicator(
        color: context.cq.vertDark,
        onRefresh: () => ref.read(metacognitionActionsProvider).sync(),
        child: LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= _wideMin;
          final list = ListView(
            padding: const EdgeInsets.fromLTRB(
                Space.xl, Space.xs, Space.xl, Space.xxxl * 2),
            physics: const AlwaysScrollableScrollPhysics(),
            children: content(withTree: !wide),
          );
          if (!wide) return list;
          // Grand écran : l'arbre compagnon accompagne la page, à droite.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: list),
              SizedBox(
                width: _sideWidth,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      0, Space.xs, Space.xl, Space.xl),
                  child: tree,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Carte de rétrospective : chaleureuse (crème), une question pour se
/// relire, et l'action d'écrire son bilan.
class _RetrospectiveCard extends StatelessWidget {
  const _RetrospectiveCard({required this.hasEntryToday, required this.onWrite});

  final bool hasEntryToday;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: cq.beigeDark),
        boxShadow: [context.chrome.shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rétrospective de la session',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Space.xs),
          Text(
            hasEntryToday
                ? 'Bilan du jour enregistré : relis-le, complète-le.'
                : 'As-tu bien identifié les notions floues ?',
            style: TextStyle(fontSize: TypeScale.body, color: cq.terre),
          ),
          const SizedBox(height: Space.lg),
          // Bouton sauge : une invitation douce, pas l'action principale.
          FilledButton.icon(
            onPressed: onWrite,
            style: FilledButton.styleFrom(
              backgroundColor: cq.vertSauge,
              foregroundColor: cq.beige,
              minimumSize: const Size(Sizes.touchTarget, Sizes.touchTarget),
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm)),
            ),
            icon: const Icon(Icons.edit_note_outlined, size: Sizes.iconMd),
            label: Text(
                hasEntryToday ? 'Modifier mon bilan' : 'Écrire mon bilan'),
          ),
        ],
      ),
    );
  }
}

/// Carte « Mon arbre de croissance » : vitalité et conseils de
/// l'Arbre-Coach (humeur, fatigue, régularité, rétention, notions floues).
class _GrowthTreeCard extends ConsumerWidget {
  const _GrowthTreeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final growth = ref.watch(treeCoachProvider).vitality;
    return DecoratedBox(
      decoration: context.chrome.decoration(color: cq.cardColor, radius: Radii.card),
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mon arbre de croissance',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.md),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: AspectRatio(
                  aspectRatio: 0.9,
                  child: MindfulTreeIllustration(growth: growth),
                ),
              ),
            ),
            const SizedBox(height: Space.sm),
            const CoachHeadline(),
            const SizedBox(height: Space.lg),
            const CoachAdviceList(),
          ],
        ),
      ),
    );
  }
}

/// Indicateur de rythme de travail — prévention de l'épuisement.
class _StrainCard extends StatelessWidget {
  const _StrainCard({required this.insights, required this.hasEntryToday});

  final MetacognitionInsights insights;
  final bool hasEntryToday;

  Color _color(BuildContext context) => switch (insights.strainLevel) {
        StrainLevel.atRisk => context.cq.errorColor,
        StrainLevel.watch => context.cq.warning,
        StrainLevel.healthy => context.cq.vertDark,
      };

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      // Carte blanche sobre : l'état n'est plus un gros aplat coloré.
      decoration: BoxDecoration(
        color: cq.cardColor,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: Space.sm,
                height: Space.sm,
                decoration: BoxDecoration(
                  color: insights.isEmpty ? cq.textHint : _color(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  insights.isEmpty ? 'Aucun bilan' : insights.strainLevel.label,
                  style: TextStyle(
                    color: cq.textPrimary,
                    fontSize: TypeScale.bodyLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            insights.summary,
            style: TextStyle(
              color: cq.textMuted,
              fontSize: TypeScale.body,
              height: 1.4,
            ),
          ),
          if (!insights.isEmpty) ...[
            const SizedBox(height: Space.lg),
            // Flexible : à grande taille de texte, les libellés passent à
            // la ligne au lieu de déborder.
            Row(
              children: [
                Flexible(
                  child: _Metric(
                    value: insights.averageMood.toStringAsFixed(1),
                    label: 'humeur / 5',
                  ),
                ),
                const SizedBox(width: Space.xl),
                Flexible(
                  child: _Metric(
                    value: insights.averageRpe.toStringAsFixed(1),
                    label: 'effort / 10',
                  ),
                ),
                const SizedBox(width: Space.xl),
                Flexible(
                  child: _Metric(
                    value: '${insights.currentStreak} j',
                    label: 'de suivi',
                  ),
                ),
              ],
            ),
          ],
          if (!hasEntryToday) ...[
            const SizedBox(height: Space.md),
            Text(
              'Pas encore de bilan aujourd\'hui.',
              style: TextStyle(fontSize: TypeScale.caption, color: cq.terre),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
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
          Text(label,
              style: TextStyle(
                  color: context.cq.textMuted, fontSize: TypeScale.caption)),
        ],
      );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.card),
      side: BorderSide(color: cq.beigeDark),
    );
    return Material(
      color: cq.cardColor,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        hoverColor: cq.sauge,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Space.lg, vertical: Space.md),
          child: Row(
            children: [
              // Icône linéaire délicate, sans pastille.
              Icon(icon, size: Sizes.iconMd, color: cq.vertSauge),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: TypeScale.body,
                            fontWeight: FontWeight.w600,
                            color: context.cq.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: TypeScale.caption, color: cq.terre)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: Space.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.sm, vertical: Space.xs / 2),
                  decoration: BoxDecoration(
                    color: cq.terre,
                    borderRadius: BorderRadius.circular(Radii.xs),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                        color: context.cq.beige,
                        fontSize: TypeScale.caption,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              Icon(Icons.arrow_forward, size: Sizes.iconMd, color: cq.vertSauge),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({required this.entry});

  final JournalEntry entry;

  static const List<String> _months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  static const List<String> _moodFaces = ['😔', '🙁', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    final date = entry.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      decoration: BoxDecoration(
        color: context.cq.cardColor,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: context.cq.beigeDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_moodFaces[(entry.mood - 1).clamp(0, 4)],
                    style: const TextStyle(fontSize: TypeScale.title)),
                const SizedBox(width: 10),
                Text(
                  '${date.day} ${_months[date.month - 1]}',
                  style: TextStyle(
                    fontSize: TypeScale.caption,
                    color: context.cq.terre,
                    fontFeatures: TypeScale.tabular,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.rpe >= 8
                        ? context.cq.errorColor.withValues(alpha: 0.1)
                        : context.cq.sauge,
                    borderRadius: BorderRadius.circular(Radii.xs),
                  ),
                  child: Text(
                    'RPE ${entry.rpe}',
                    style: TextStyle(
                      fontSize: TypeScale.caption,
                      fontWeight: FontWeight.w600,
                      color: entry.rpe >= 8
                          ? context.cq.errorColor
                          : context.cq.textMuted,
                    ),
                  ),
                ),
                if (!entry.isSynced)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.cloud_queue,
                        size: 13, color: context.cq.textHint),
                  ),
              ],
            ),
            if (entry.whatLearned.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.whatLearned,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: TypeScale.body,
                    color: context.cq.textPrimary,
                    height: 1.4),
              ),
            ],
            if (entry.whatBlocked.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Bloqué : ${entry.whatBlocked}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: TypeScale.caption,
                    color: context.cq.textMuted,
                    height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
}
