import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/motion/entrance.dart';
import '../../../core/theme/tokens.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/pomodoro_session_model.dart';
import '../../../shared/models/note_model.dart';
import '../../../shared/models/task_model.dart';
import '../../habits/providers/habit_provider.dart';
import '../../kanban/providers/task_provider.dart';
import '../../metacognition/domain/metacognition_insights.dart';
import '../../metacognition/providers/metacognition_provider.dart';
import '../../notes/providers/note_provider.dart';
import '../../planning/providers/planning_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../review/providers/review_provider.dart';
import '../models/dashboard_module.dart';
import '../providers/dashboard_layout_provider.dart';
import '../providers/dashboard_stats_provider.dart';
import '../widgets/dashboard_bento.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/module_picker_sheet.dart';
import '../widgets/weekly_focus_chart.dart';
import '../../../core/ui/ui.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const List<String> _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  static const List<String> _weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  /// Largeur à partir de laquelle la grille « bento » s'affiche.
  static const double _wideLayoutMin = 900;

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Bonjour';
    if (now.hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  static String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(dashboardStatsProvider);
    await Future.wait([
      ref.read(taskProvider.notifier).refresh(),
      ref.read(habitProvider.notifier).refresh(),
    ]);
  }

  /// Modules intégrés à la grille ; les autres, s'ils sont affichés,
  /// viennent en cartes sous la grille.
  static const Set<DashboardModule> _inGrid = {
    DashboardModule.quickStart,
    DashboardModule.reviews,
    DashboardModule.tasks,
    DashboardModule.habits,
    DashboardModule.planning,
  };

  static String _dueLabel(DateTime date, DateTime today) {
    final days = DateTime(date.year, date.month, date.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (days == 0) return 'Auj.';
    if (days == 1) return 'Demain';
    return '${date.day} ${_months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final visible = ref.watch(dashboardLayoutProvider).visibleModules;
    final habits = ref.watch(habitProvider).valueOrNull ?? const [];
    final tasks = ref.watch(taskProvider).valueOrNull ?? const <Task>[];
    final stats = ref.watch(dashboardStatsProvider).valueOrNull ??
        const DashboardStats.empty();
    final reviews = ref.watch(reviewStatsProvider);
    final goals = ref.watch(studyGoalsProvider).valueOrNull ?? const [];
    final upcoming = ref.watch(upcomingPlanItemsProvider);

    // Les tâches en retard d'abord, puis celles à échéance proche.
    final pending = tasks.where((t) => !t.isDone).toList()
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        if (a.isDoing != b.isDoing) return a.isDoing ? -1 : 1;
        final aDue = a.dueDate;
        final bDue = b.dueDate;
        if (aDue != null && bDue != null) return aDue.compareTo(bDue);
        if (aDue != null) return -1;
        if (bDue != null) return 1;
        return a.position.compareTo(b.position);
      });
    final doing = tasks.where((t) => t.isDoing).firstOrNull;
    // Les habitudes à valider remontent : la liste est une liste d'actions.
    final sortedHabits = [...habits]..sort((a, b) {
        if (a.completedToday != b.completedToday) {
          return a.completedToday ? 1 : -1;
        }
        return b.streak.compareTo(a.streak);
      });

    final greeting = DashboardGreeting(
      greeting: _greeting(now),
      name: ref.watch(displayNameProvider),
      dateLabel: _formatDate(now),
    );
    final session = visible.contains(DashboardModule.quickStart)
        ? SessionCard(
            subtitle: doing == null
                ? '25 min de focus · Pomodoro'
                : 'En cours : ${doing.title}',
            onStart: () => context.go(AppRoute.pomodoro),
          )
        : null;
    KpiGrid kpis({bool fill = false}) => KpiGrid(
          fill: fill,
          tiles: [
            KpiTile(
              value: '${reviews.dueCount}',
              label: reviews.dueCount > 1 ? 'cartes à revoir' : 'carte à revoir',
              tooltip: 'Voir tout : Révisions du jour',
              onTap: () => context.go(AppRoute.review),
            ),
            KpiTile(
              value: '${pending.length}',
              label: pending.length > 1 ? 'tâches à faire' : 'tâche à faire',
              tooltip: 'Voir tout : Tâches à faire',
              onTap: () => context.go(AppRoute.kanban),
            ),
            KpiTile(
              value: '${goals.length}',
              label: goals.length > 1 ? 'objectifs' : 'objectif',
              tooltip: 'Voir tout : Objectifs',
              onTap: () => context.go(AppRoute.goals),
            ),
            KpiTile(
              value: formatFocusDuration(stats.focusToday),
              label: "de focus aujourd'hui",
              tooltip: 'Voir tout : Pomodoro',
              onTap: () => context.go(AppRoute.pomodoro),
            ),
          ],
        );

    Widget taskBoard(int columns) {
      final shown = pending.take(6).toList();
      if (shown.isEmpty) {
        return ListSection(
          title: 'Tâches',
          emptyMessage: tasks.isEmpty
              ? 'Ajoute tes premières tâches.'
              : "Tout est fait pour l'instant !",
          children: const [],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var col = 0; col < columns; col++) ...[
            if (col > 0) const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                children: [
                  for (final (i, task) in shown.indexed)
                    if (i % columns == col)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: TaskMiniCard(
                          task: task,
                          onOpen: () => context.go(AppRoute.kanban),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    final lists = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListSection(
          title: 'Habitudes',
          emptyMessage: 'Crée tes premières habitudes.',
          children: [
            for (final habit in sortedHabits.take(5))
              ChecklistRow(
                label: habit.name,
                checked: habit.completedToday,
                trailing: habit.streak == 0
                    ? null
                    : '${habit.streak} ${habit.frequency.shortUnit}',
                onTap: () =>
                    ref.read(habitProvider.notifier).toggleToday(habit),
              ),
          ],
        ),
        if (visible.contains(DashboardModule.planning)) ...[
          const SizedBox(height: Space.xl),
          ListSection(
            title: 'Échéances',
            emptyMessage: 'Aucune échéance à venir.',
            children: [
              for (final item in upcoming.take(4))
                ChecklistRow(
                  label: item.title,
                  trailing: _dueLabel(item.endDate, now),
                  onTap: () => context.go(AppRoute.gantt),
                ),
            ],
          ),
        ],
      ],
    );
    const tree = GrowthTreeCard();
    final extras = [
      for (final module in visible)
        if (!_inGrid.contains(module))
          Padding(
            padding: const EdgeInsets.only(top: Space.xl),
            child: CqCard(
                radius: Radii.card, child: _ModuleSection(module: module)),
          ),
    ];
    final showTasks = visible.contains(DashboardModule.tasks);

    return Scaffold(
      // Pas de titre : la salutation tient lieu d'en-tête.
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Personnaliser le tableau de bord',
            icon: const Icon(Icons.tune),
            onPressed: () => ModulePickerSheet.show(context),
          ),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: RefreshIndicator(
        color: context.cq.vertDark,
        onRefresh: () => _refreshAll(ref),
        // Grille « bento » au-dessus de 900 px, une seule colonne en
        // dessous.
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideLayoutMin;
          final gutter = wide ? Space.xxxl : Space.xl;
          final divider = Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xl),
            child: Divider(
                height: Borders.thin,
                thickness: Borders.thin,
                color: context.cq.beigeDark),
          );
          final children = wide
              ? <Widget>[
                  greeting,
                  const SizedBox(height: Space.xl),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (session != null) ...[
                          Expanded(flex: 5, child: session),
                          const SizedBox(width: Space.lg),
                        ],
                        Expanded(flex: 5, child: kpis(fill: true)),
                      ],
                    ),
                  ),
                  divider,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showTasks) ...[
                        Expanded(flex: 5, child: taskBoard(2)),
                        const SizedBox(width: Space.xl),
                      ],
                      Expanded(flex: 3, child: lists),
                      const SizedBox(width: Space.xl),
                      Expanded(flex: 3, child: tree),
                    ],
                  ),
                  ...extras,
                ]
              : <Widget>[
                  greeting,
                  const SizedBox(height: Space.xl),
                  if (session != null) ...[
                    session,
                    const SizedBox(height: Space.md),
                  ],
                  kpis(),
                  divider,
                  if (showTasks) ...[
                    taskBoard(constraints.maxWidth >= 560 ? 2 : 1),
                    const SizedBox(height: Space.lg),
                  ],
                  lists,
                  const SizedBox(height: Space.xl),
                  tree,
                  ...extras,
                ];
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                gutter, Space.sm, gutter, Space.xxxl),
            children: [PanelSettle(child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ))],
          );
        }),
      ),
    );
  }
}

/// Aiguillage vers le contenu de chaque module.
class _ModuleSection extends ConsumerWidget {
  const _ModuleSection({required this.module});

  final DashboardModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (module) {
      DashboardModule.stats => const _StatsModule(),
      DashboardModule.weeklyFocus => const _WeeklyFocusModule(),
      DashboardModule.notes => const _NotesModule(),
      DashboardModule.metacognition => const _MetacognitionModule(),
      // Intégrés à la grille (cf. DashboardPage._inGrid).
      DashboardModule.quickStart ||
      DashboardModule.tasks ||
      DashboardModule.habits ||
      DashboardModule.planning ||
      DashboardModule.reviews =>
        const SizedBox.shrink(),
    };
  }
}

// ─── Progrès du jour ────────────────────────────────────────────────────────

class _StatsModule extends ConsumerWidget {
  const _StatsModule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider).valueOrNull ??
        const DashboardStats.empty();
    final tasks = ref.watch(taskProvider).valueOrNull ?? const <Task>[];
    final habits = ref.watch(habitProvider).valueOrNull ?? const [];

    final doneTasks = tasks.where((t) => t.isDone).length;
    final doneHabits = habits.where((h) => h.completedToday).length;

    return Column(
      children: [
        // Le nombre de tête du Dashboard : une figure héro, pas un graphe.
        HeroFocusCard(
          value: formatFocusDuration(stats.focusToday),
          caption: stats.sessionsToday == 0
              ? "Pas encore de focus aujourd'hui"
              : '${stats.sessionsToday} session'
                  '${stats.sessionsToday > 1 ? 's' : ''} aujourd\'hui',
          trailing: const CqScoreBadge(icon: Icons.timer_outlined),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.task_alt_outlined,
                label: 'Tâches',
                value: tasks.isEmpty ? '—' : '$doneTasks/${tasks.length}',
                onTap: () => context.go(AppRoute.kanban),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.local_fire_department_outlined,
                label: 'Habitudes',
                value: habits.isEmpty ? '—' : '$doneHabits/${habits.length}',
                // Série : l'écorce, en alternance avec la sauge.
                warm: true,
                onTap: () => context.go(AppRoute.habits),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.calendar_today_outlined,
                label: 'Focus / semaine',
                value: formatFocusDuration(stats.focusThisWeek),
                onTap: () => context.go(AppRoute.pomodoro),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Focus de la semaine ────────────────────────────────────────────────────

class _WeeklyFocusModule extends ConsumerWidget {
  const _WeeklyFocusModule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      // Pas de squelette clignotant au rafraîchissement : on garde le rendu
      // précédent en atténué, sans saut de mise en page.
      skipLoadingOnRefresh: true,
      loading: () => const _ChartPlaceholder(),
      error: (_, __) => const _ChartPlaceholder(),
      data: (stats) => WeeklyFocusChart(stats: stats),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 190,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: context.cq.vertDark),
          ),
        ),
    );
  }
}

// ─── Fiches récentes ────────────────────────────────────────────────────────

class _NotesModule extends ConsumerWidget {
  const _NotesModule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
    final pending = ref.watch(unsyncedNotesCountProvider);

    // Les fiches non archivées, de la plus récemment travaillée à la plus
    // ancienne : le Dashboard sert à reprendre là où on s'est arrêté.
    final recent = notes.where((n) => !n.isArchived).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Fiches récentes',
          onMore: () => context.go(AppRoute.notes),
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          EmptySection(
            icon: Icons.auto_stories_outlined,
            message: 'Crée ta première fiche de connaissance',
            onAction: () => context.go(AppRoute.notes),
            actionLabel: 'Commencer',
          )
        else ...[
          for (final note in recent)
            _InsetRow(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.go('${AppRoute.notes}/${note.id}'),
                borderRadius: BorderRadius.circular(Radii.card),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 16, color: context.cq.textHint),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: TypeScale.body,
                                  color: context.cq.textPrimary),
                            ),
                            if (note.subject != null)
                              Text(
                                note.subject!,
                                style: TextStyle(
                                    fontSize: TypeScale.caption,
                                    color: context.cq.textMuted),
                              ),
                          ],
                        ),
                      ),
                      if (!note.isSynced)
                        Icon(Icons.cloud_queue,
                            size: 14, color: context.cq.textHint),
                    ],
                  ),
                ),
              ),
            ),
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '$pending fiche${pending > 1 ? 's' : ''} en attente de synchronisation',
                style: TextStyle(
                    fontSize: TypeScale.caption, color: context.cq.textHint),
              ),
            ),
        ],
      ],
    );
  }
}

// ─── Journal & ressenti ─────────────────────────────────────────────────────

class _MetacognitionModule extends ConsumerWidget {
  const _MetacognitionModule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(metacognitionInsightsProvider);
    final hasEntryToday = ref.watch(todayJournalEntryProvider) != null;

    final color = switch (insights.strainLevel) {
      StrainLevel.atRisk => context.cq.errorColor,
      StrainLevel.watch => context.cq.warning,
      StrainLevel.healthy => context.cq.vertDark,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Journal & ressenti',
          onMore: () => context.go(AppRoute.journal),
          trailingLabel: 'Ouvrir',
        ),
        const SizedBox(height: 10),
        _InsetRow(
          child: InkWell(
            onTap: () => context.go(
              hasEntryToday ? AppRoute.journal : AppRoute.journalEntry,
            ),
            borderRadius: BorderRadius.circular(Radii.card),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Icon(Icons.self_improvement_outlined,
                        size: 20, color: color),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insights.isEmpty
                              ? 'Faire mon premier bilan'
                              : (hasEntryToday
                                  ? insights.strainLevel.label
                                  : 'Bilan du jour à faire'),
                          style: TextStyle(
                            fontSize: TypeScale.body,
                            fontWeight: FontWeight.w600,
                            color: context.cq.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          insights.isEmpty
                              ? 'Humeur, effort ressenti, ce qui a marché'
                              : 'Humeur ${insights.averageMood.toStringAsFixed(1)}/5 · '
                                  'effort ${insights.averageRpe.toStringAsFixed(1)}/10 · '
                                  '${insights.currentStreak} j de suivi',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          // Métadonnée chaleureuse : la terre répond au vert.
                          style: TextStyle(
                              fontSize: TypeScale.caption,
                              color: context.cq.terre),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: context.cq.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne cliquable d'un module : posée dans la `CqCard` du module sur un
/// aplat en retrait, sans filet ni ombre. Remplace l'ancienne `Card`
/// Material imbriquée (double carte).
class _InsetRow extends StatelessWidget {
  const _InsetRow({required this.child, this.margin = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: context.cq.sauge,
        borderRadius: BorderRadius.circular(Radii.card),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
