import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/metacognition_model.dart';
import '../domain/metacognition_insights.dart';
import '../providers/metacognition_provider.dart';
import '../widgets/mood_trend_chart.dart';

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

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(metacognitionInsightsProvider);
    final profile = ref.watch(learningProfileProvider).valueOrNull;
    final todayEntry = ref.watch(todayJournalEntryProvider);
    final errorPattern = ref.watch(errorPatternProvider);
    final unfinished = ref.watch(unfinishedReframesProvider);
    final entries = ref.watch(journalProvider).valueOrNull ?? const <JournalEntry>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Journal & ressenti')),
      body: RefreshIndicator(
        color: context.cq.vert,
        onRefresh: () => ref.read(metacognitionActionsProvider).sync(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (profile != null && !profile.isComplete)
              _ProfilingPrompt(progress: profile.progress),

            _StrainCard(insights: insights, hasEntryToday: todayEntry != null),
            const SizedBox(height: 20),

            if (insights.entryCount > 0) ...[
              MoodTrendChart(trend: insights.moodTrend),
              const SizedBox(height: 20),
            ],

            const _SectionLabel('Outils'),
            const SizedBox(height: 10),
            _ToolTile(
              icon: Icons.edit_note_outlined,
              title: todayEntry == null
                  ? 'Faire le bilan de ma session'
                  : 'Modifier le bilan du jour',
              subtitle: 'Humeur, effort ressenti, ce qui a marché',
              onTap: () => context.push(AppRoute.journalEntry),
            ),
            const SizedBox(height: 8),
            _ToolTile(
              icon: Icons.psychology_alt_outlined,
              title: 'Recadrage cognitif',
              subtitle: 'Transformer une pensée bloquante en objectif',
              badge: unfinished.isEmpty ? null : '${unfinished.length}',
              onTap: () => context.push(AppRoute.reframe),
            ),
            const SizedBox(height: 8),
            _ToolTile(
              icon: Icons.account_tree_outlined,
              title: 'Les 5 Pourquoi',
              subtitle: 'Remonter d\'un blocage à sa cause réelle',
              onTap: () => context.push(AppRoute.whyChain),
            ),
            const SizedBox(height: 8),
            _ToolTile(
              icon: Icons.rule_outlined,
              title: 'Analyse des erreurs',
              subtitle: errorPattern.isEmpty
                  ? 'Distinguer inattention et incompréhension'
                  : '${errorPattern.total} erreur'
                      '${errorPattern.total > 1 ? 's' : ''} consignée'
                      '${errorPattern.total > 1 ? 's' : ''}',
              onTap: () => context.push(AppRoute.errorLogs),
            ),
            const SizedBox(height: 8),
            _ToolTile(
              icon: Icons.fingerprint,
              title: 'Mon profil d\'apprentissage',
              subtitle: profile?.isComplete ?? false
                  ? [
                      profile!.processingStyle?.label,
                      profile.preferredChannel?.label,
                    ].whereType<String>().join(' · ')
                  : 'Découvrir mon mode d\'emploi',
              onTap: () => context.push(AppRoute.profiling),
            ),

            if (!errorPattern.isEmpty) ...[
              const SizedBox(height: 24),
              _InsightBanner(
                icon: Icons.rule_outlined,
                message: errorPattern.summary,
              ),
            ],

            if (entries.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionLabel('Bilans récents'),
              const SizedBox(height: 10),
              for (final entry in entries.take(8))
                _JournalRow(entry: entry),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfilingPrompt extends StatelessWidget {
  const _ProfilingPrompt({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cq.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: context.cq.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fingerprint, size: 18, color: context.cq.warning),
              SizedBox(width: 8),
              Text(
                'Ton mode d\'emploi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.cq.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
           Text(
            'Cinq questions pour comprendre comment tu apprends. '
            'L\'application adaptera ensuite ses conseils.',
            style: TextStyle(
                fontSize: 12.5, color: context.cq.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push(AppRoute.profiling),
              child: Text(progress == 0 ? 'Commencer' : 'Reprendre'),
            ),
          ),
        ],
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
        StrainLevel.healthy => context.cq.vert,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: insights.isEmpty
            ? context.cq.beigeDark.withValues(alpha: 0.4)
            : _color(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insights.isEmpty
                ? 'Aucun bilan'
                : insights.strainLevel.label,
            style: TextStyle(
              color: insights.isEmpty ? context.cq.textMuted : context.onAccent,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            insights.summary,
            style: TextStyle(
              color: insights.isEmpty
                  ? context.cq.textMuted
                  : context.cq.onVertMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (!insights.isEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _Metric(
                  value: insights.averageMood.toStringAsFixed(1),
                  label: 'humeur / 5',
                ),
                const SizedBox(width: 22),
                _Metric(
                  value: insights.averageRpe.toStringAsFixed(1),
                  label: 'effort / 10',
                ),
                const SizedBox(width: 22),
                _Metric(
                  value: '${insights.currentStreak} j',
                  label: 'de suivi',
                ),
              ],
            ),
          ],
          if (!hasEntryToday) ...[
            const SizedBox(height: 14),
            Text(
              'Pas encore de bilan aujourd\'hui.',
              style: TextStyle(
                fontSize: 12,
                color: insights.isEmpty
                    ? context.cq.textHint
                    : context.cq.onVertMuted,
              ),
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
              color: context.onAccent,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label,
              style:  TextStyle(
                  color: context.cq.onVertMuted, fontSize: 11)),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.cq.vert.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: context.cq.vertDark),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:  TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.cq.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:  TextStyle(
                            fontSize: 12, color: context.cq.textMuted)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.cq.warning,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                        color: context.onAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
               Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: context.cq.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cq.vert.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cq.vert.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: context.cq.vertDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style:  TextStyle(
                  fontSize: 12.5, color: context.cq.vertDark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({required this.entry});

  final JournalEntry entry;

  static const List<String> _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static const List<String> _moodFaces = ['😔', '🙁', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    final date = entry.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_moodFaces[(entry.mood - 1).clamp(0, 4)],
                    style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 10),
                Text(
                  '${date.day} ${_months[date.month - 1]}',
                  style:  TextStyle(
                      fontSize: 12, color: context.cq.textMuted),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.rpe >= 8
                        ? context.cq.errorColor.withValues(alpha: 0.1)
                        : context.cq.beigeDark.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RPE ${entry.rpe}',
                    style: TextStyle(
                      fontSize: 11,
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
                style:  TextStyle(
                    fontSize: 13, color: context.cq.textPrimary, height: 1.4),
              ),
            ],
            if (entry.whatBlocked.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Bloqué : ${entry.whatBlocked}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:  TextStyle(
                    fontSize: 12, color: context.cq.textMuted, height: 1.35),
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
  Widget build(BuildContext context) => Text(
        text,
        style:  TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.cq.textPrimary,
        ),
      );
}
