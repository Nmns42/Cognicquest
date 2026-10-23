import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../notes/providers/note_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/flashcard_editor_sheet.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
import 'explain_page.dart';
import 'sq3r_page.dart';

/// Accueil de la révision active : ce qui est dû aujourd'hui, la charge à
/// venir, et l'accès aux outils de compréhension (SQ3R, « Explique-moi »).
class ReviewHomePage extends ConsumerStatefulWidget {
  const ReviewHomePage({super.key});

  @override
  ConsumerState<ReviewHomePage> createState() => _ReviewHomePageState();
}

class _ReviewHomePageState extends ConsumerState<ReviewHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewActionsProvider).sync();
    });
  }

  Future<void> _createCard() async {
    final draft = await FlashcardEditorSheet.show(context);
    if (draft == null) return;
    await ref.read(reviewActionsProvider).createCard(
          front: draft.front,
          back: draft.back,
          deck: draft.deck,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(flashcardsProvider);
    final stats = ref.watch(reviewStatsProvider);
    final decks = ref.watch(decksProvider);
    final selectedDeck = ref.watch(selectedDeckProvider);

    return Scaffold(
      body: cardsAsync.when(
        loading: () =>  Center(
          child: CircularProgressIndicator(color: context.cq.vertDark),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(error.toString(),
                textAlign: TextAlign.center,
                style:  TextStyle(color: context.cq.textMuted)),
          ),
        ),
        data: (cards) => RefreshIndicator(
          color: context.cq.vertDark,
          onRefresh: () => ref.read(reviewActionsProvider).sync(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _DueCard(stats: stats),
              const SizedBox(height: 20),

              if (decks.isNotEmpty) ...[
                _DeckFilter(
                  decks: decks,
                  selected: selectedDeck,
                  onSelect: (deck) =>
                      ref.read(selectedDeckProvider.notifier).state = deck,
                ),
                const SizedBox(height: 20),
              ],

              if (cards.isNotEmpty) ...[
                const _SectionLabel('Charge des 7 prochains jours'),
                const SizedBox(height: 10),
                _UpcomingLoad(upcoming: stats.upcomingWeek),
                const SizedBox(height: 24),
              ],

              const _SectionLabel('Comprendre avant de mémoriser'),
              const SizedBox(height: 4),
               Text(
                'Mémoriser ce qu\'on n\'a pas compris ne tient pas. '
                'L’étude guidée travaille la compréhension en trois temps.',
                style: TextStyle(
                    fontSize: TypeScale.caption, color: context.cq.textMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              _ToolCard(
                icon: Icons.school_outlined,
                title: 'Étude guidée',
                subtitle: 'Survol et questions · lecture ciblée · '
                    'explication avec tes mots',
                onTap: () => context.push(AppRoute.sq3rPicker),
              ),
              const SizedBox(height: 24),
              const _StudySheets(),

              if (cards.isEmpty)
                const _EmptyCards()
              else ...[
                _SectionLabel('Mes cartes (${cards.length})'),
                const SizedBox(height: 10),
                for (final card in cards.take(20))
                  _CardRow(
                    card: card,
                    onEdit: () async {
                      final draft = await FlashcardEditorSheet.show(
                        context,
                        card: card,
                      );
                      if (draft == null) return;
                      await ref.read(reviewActionsProvider).saveCard(
                            card.copyWith(
                              front: draft.front,
                              back: draft.back,
                              deck: draft.deck,
                              clearDeck: draft.deck == null,
                            ),
                          );
                    },
                    onDelete: () =>
                        ref.read(reviewActionsProvider).deleteCard(card.id),
                  ),
                if (cards.length > 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '… et ${cards.length - 20} autres',
                      style:  TextStyle(
                          fontSize: TypeScale.caption, color: context.cq.textHint),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCard,
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle carte',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.stats});

  final ReviewQueueStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // Carte blanche éditoriale : le vert reste au bouton d'action.
      decoration: context.chrome
          .decoration(color: context.cq.cardColor, radius: Radii.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.hasWork ? '${stats.dueCount}' : '✓',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontFeatures: TypeScale.tabular),
          ),
          const SizedBox(height: 2),
          Text(
            stats.hasWork
                ? 'carte${stats.dueCount > 1 ? 's' : ''} à revoir'
                    '${stats.newCount > 0 ? ' · ${stats.newCount} nouvelle${stats.newCount > 1 ? 's' : ''}' : ''}'
                : stats.totalCards == 0
                    ? 'Aucune carte pour le moment'
                    : 'Tout est à jour. Reviens demain.',
            style:  TextStyle(color: context.cq.textMuted, fontSize: TypeScale.body),
          ),
          if (stats.reviewedToday > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${stats.reviewedToday} déjà travaillée'
              '${stats.reviewedToday > 1 ? 's' : ''} aujourd\'hui',
              style:  TextStyle(color: context.cq.terre, fontSize: TypeScale.caption),
            ),
          ],
          if (stats.hasWork) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoute.reviewSession),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Commencer la session'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeckFilter extends StatelessWidget {
  const _DeckFilter({
    required this.decks,
    required this.selected,
    required this.onSelect,
  });

  final List<String> decks;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Tous', style: TextStyle(fontSize: TypeScale.caption)),
          selected: selected == null,
          onSelected: (_) => onSelect(null),
        ),
        for (final deck in decks)
          FilterChip(
            label: Text(deck, style: const TextStyle(fontSize: TypeScale.caption)),
            selected: selected == deck,
            onSelected: (isSelected) => onSelect(isSelected ? deck : null),
          ),
      ],
    );
  }
}

/// Charge prévisionnelle. Série unique → une seule teinte pour toutes les
/// barres, teinte foncée pour tenir le contraste, étiquette seulement sur le
/// pic et sur aujourd'hui.
class _UpcomingLoad extends StatelessWidget {
  const _UpcomingLoad({required this.upcoming});

  final List<int> upcoming;

  static const double _plotHeight = 56;

  @override
  Widget build(BuildContext context) {
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final max = upcoming.reduce((a, b) => a > b ? a : b);
    const labels = ["Auj.", 'J+1', 'J+2', 'J+3', 'J+4', 'J+5', 'J+6'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        // Pas de hauteur fixe pour l'ensemble : 92 px ne laissaient pas de
        // place au libellé du jour dès que le texte grandit (1 px de
        // débordement à 100 % avec la vraie police, 14 px à 200 %). Chaque
        // colonne réserve une zone fixe pour la valeur et la barre ; le
        // libellé prend la hauteur dont il a besoin.
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < upcoming.length; i++)
                Expanded(
                  child: Semantics(
                    label: '${labels[i]} : ${upcoming[i]} carte'
                        '${upcoming[i] > 1 ? 's' : ''}',
                    child: Tooltip(
                      message: '${labels[i]} : ${upcoming[i]} carte'
                          '${upcoming[i] > 1 ? 's' : ''}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Zone fixe : valeur + barre, alignées en bas.
                            SizedBox(
                              height: 14 + 3 + _plotHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                            SizedBox(
                              height: 14,
                              child: (upcoming[i] > 0 &&
                                      (upcoming[i] == max || i == 0))
                                  ? FittedBox(
                                      child: Text(
                                        '${upcoming[i]}',
                                        style: TextStyle(
                                          fontSize: TypeScale.caption,
                                          fontWeight: FontWeight.w600,
                                          color: i == 0
                                              ? context.cq.textPrimary
                                              : context.cq.textMuted,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              height: max == 0
                                  ? 3
                                  : (upcoming[i] / max * _plotHeight)
                                      .clamp(3.0, _plotHeight),
                              decoration: BoxDecoration(
                                color: upcoming[i] == 0
                                    ? context.cq.beigeDark
                                    : context.cq.vertDark
                                        .withValues(alpha: i == 0 ? 1 : 0.75),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(Radii.md),
                                ),
                              ),
                            ),
                                ],
                              ),
                            ),
                            Container(height: 1, color: context.cq.beigeDark),
                            const SizedBox(height: 5),
                            Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: TypeScale.caption,
                                fontWeight: i == 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == 0
                                    ? context.cq.textPrimary
                                    : context.cq.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.cq.vertSauge.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(icon, size: 20, color: context.cq.vertDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:  TextStyle(
                            fontSize: TypeScale.body,
                            fontWeight: FontWeight.w600,
                            color: context.cq.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:  TextStyle(
                            fontSize: TypeScale.caption, color: context.cq.textMuted)),
                  ],
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

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  final Flashcard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final days = card.daysUntilDue;
    final dueLabel = card.isDue
        ? 'à revoir'
        : (days == 1 ? 'demain' : 'dans $days j');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.frontSide.text.isEmpty
                          ? 'Image'
                          : card.frontSide.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                          fontSize: TypeScale.body, color: context.cq.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          dueLabel,
                          style: TextStyle(
                            fontSize: TypeScale.caption,
                            color: card.isDue
                                ? context.cq.vertDark
                                : context.cq.textMuted,
                            fontWeight:
                                card.isDue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (card.deck != null) ...[
                           Text(' · ',
                              style: TextStyle(
                                  fontSize: TypeScale.caption, color: context.cq.textHint)),
                          Flexible(
                            child: Text(
                              card.deck!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:  TextStyle(
                                  fontSize: TypeScale.caption, color: context.cq.textHint),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (card.frontSide.hasImage || card.backSide.hasImage)
                Padding(
                  padding: const EdgeInsets.only(right: Space.xs),
                  child: Icon(Icons.image_outlined,
                      size: Sizes.iconSm, color: context.cq.textHint),
                ),
              if (!card.isSynced)
                 Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.cloud_queue,
                      size: 13, color: context.cq.textHint),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Supprimer',
                icon:  Icon(Icons.delete_outline,
                    size: 17, color: context.cq.textHint),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fiches de révision : chaque fiche passée par l'étude guidée, ouvrable
/// comme une fiche de cours (questions, réponses, explication, maîtrise).
class _StudySheets extends ConsumerWidget {
  const _StudySheets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(studySessionsProvider).valueOrNull ?? const [];
    final explanations =
        ref.watch(explanationsProvider).valueOrNull ?? const <Explanation>[];
    final noteIds = <String>{
      ...sessions.map((s) => s.noteId),
      ...explanations.map((e) => e.noteId),
    };
    if (noteIds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel('Mes fiches de révision (${noteIds.length})'),
        const SizedBox(height: Space.sm),
        for (final noteId in noteIds)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: _StudySheetRow(
              noteId: noteId,
              session: sessions.where((s) => s.noteId == noteId).firstOrNull,
              latest: explanations.where((e) => e.noteId == noteId).firstOrNull,
            ),
          ),
        const SizedBox(height: Space.lg),
      ],
    );
  }
}

class _StudySheetRow extends ConsumerWidget {
  const _StudySheetRow({
    required this.noteId,
    required this.session,
    required this.latest,
  });

  final String noteId;
  final Sq3rSession? session;
  final Explanation? latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteByIdProvider(noteId));
    if (note == null) return const SizedBox.shrink();
    final current = session;
    final status = current == null || current.isComplete
        ? (latest == null
            ? 'Étudiée'
            : 'Maîtrise ${latest!.confidence}/5 · '
                '${ConfidencePicker.labels[latest!.confidence - 1]}')
        : 'En cours · ${StudyStage.of(current.currentStep).label}';
    final questions = current?.questions.length ?? 0;
    return CqCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(AppRoute.studySheetFor(noteId)),
      semanticLabel: 'Ouvrir la fiche de révision ${note.displayTitle}',
      child: CqListRow(
        title: note.displayTitle,
        subtitle: questions == 0
            ? status
            : '$status · $questions question${questions > 1 ? 's' : ''}',
        leadingIcon: Icons.school_outlined,
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
          fontSize: TypeScale.body,
          fontWeight: FontWeight.w600,
          color: context.cq.textPrimary,
        ),
      );
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cq.beigeDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child:  Column(
        children: [
          Icon(Icons.style_outlined, size: 36, color: context.cq.textHint),
          const SizedBox(height: 12),
          Text(
            'Aucune carte pour l\'instant.\n'
            'Crée-en une, ou génère-les depuis une fiche.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.cq.textMuted, fontSize: TypeScale.body, height: 1.4),
          ),
        ],
      ),
    );
  }
}
