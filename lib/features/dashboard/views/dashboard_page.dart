import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/pomodoro_session_model.dart';
import '../../../shared/models/note_model.dart';
import '../../../shared/models/task_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../habits/providers/habit_provider.dart';
import '../../kanban/providers/task_provider.dart';
import '../../metacognition/domain/metacognition_insights.dart';
import '../../metacognition/providers/metacognition_provider.dart';
import '../../notes/providers/note_provider.dart';
import '../../planning/providers/planning_provider.dart';
import '../../../shared/models/planning_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/dashboard_module.dart';
import '../providers/dashboard_layout_provider.dart';
import '../providers/dashboard_stats_provider.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/module_picker_sheet.dart';
import '../widgets/weekly_focus_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const List<String> _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  static const List<String> _weekdays = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche',
  ];

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Bonjour';
    if (now.hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  static String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    // La déconnexion efface les données de l'appareil : on envoie d'abord ce
    // qui peut l'être, puis on prévient de ce qui serait perdu.
    final remaining =
        ref.read(authControllerProvider.notifier).flushPendingWrites();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => FutureBuilder<int>(
        future: remaining,
        builder: (context, snapshot) {
          final isFlushing =
              snapshot.connectionState != ConnectionState.done;
          final pending = snapshot.data ?? 0;
          return AlertDialog(
            title: const Text('Se déconnecter ?'),
            content: isFlushing
                ? const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Text('Synchronisation en cours…')),
                    ],
                  )
                : Text(
                    pending == 0
                        ? 'Tes données sont synchronisées sur ton compte. '
                            'Elles seront effacées de cet appareil.'
                        : '$pending modification${pending > 1 ? 's' : ''} '
                            'n\'${pending > 1 ? 'ont' : 'a'} pas pu être '
                            'envoyée${pending > 1 ? 's' : ''} (hors ligne ?). '
                            'Te déconnecter maintenant '
                            '${pending > 1 ? 'les' : 'la'} perdra '
                            'définitivement.',
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed:
                    isFlushing ? null : () => Navigator.pop(context, true),
                child: Text(
                  pending == 0 ? 'Se déconnecter' : 'Se déconnecter quand même',
                  style: TextStyle(
                    color: isFlushing ? null : context.cq.errorColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed ?? false) {
      // Le routeur redirige seul vers /login via refreshListenable.
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(dashboardStatsProvider);
    await Future.wait([
      ref.read(taskProvider.notifier).refresh(),
      ref.read(habitProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final layout = ref.watch(dashboardLayoutProvider);
    final visibleModules = layout.visibleModules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CognicQuest'),
        actions: [
          IconButton(
            tooltip: 'Personnaliser le tableau de bord',
            icon: const Icon(Icons.tune),
            onPressed: () => ModulePickerSheet.show(context),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: context.cq.vert,
        onRefresh: () => _refreshAll(ref),
        // `ReorderableListView` porte le glisser-déposer des modules demandé
        // par le CdC, sans dépendance supplémentaire.
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          physics: const AlwaysScrollableScrollPhysics(),
          // L'accueil n'est pas un module : il reste en tête, non déplaçable.
          header: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GreetingCard(
              greeting: _greeting(now),
              name: ref.watch(displayNameProvider),
              dateLabel: _formatDate(now),
            ),
          ),
          footer: const _CustomiseHint(),
          itemCount: visibleModules.length,
          onReorderItem: ref.read(dashboardLayoutProvider.notifier).reorder,
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: Opacity(opacity: 0.92, child: child),
          ),
          itemBuilder: (context, index) {
            final module = visibleModules[index];
            return Padding(
              // La clé porte l'identifiant du module : Flutter suit ainsi le
              // bon widget pendant le déplacement.
              key: ValueKey(module.id),
              padding: const EdgeInsets.only(bottom: 20),
              child: _ModuleSection(module: module),
            );
          },
        ),
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
      DashboardModule.quickStart => const _QuickStartModule(),
      DashboardModule.tasks => const _TasksModule(),
      DashboardModule.habits => const _HabitsModule(),
      DashboardModule.notes => const _NotesModule(),
      DashboardModule.metacognition => const _MetacognitionModule(),
      DashboardModule.planning => const _PlanningModule(),
    };
  }
}

// ─── Progrès du jour ────────────────────────────────────────────────────────

class _StatsModule extends ConsumerWidget {
  const _StatsModule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats =
        ref.watch(dashboardStatsProvider).valueOrNull ?? const DashboardStats.empty();
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
          trailing: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.cq.vert.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:  Icon(Icons.timer_outlined,
                color: context.cq.vertDark, size: 22),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.task_alt_outlined,
                label: 'Tâches',
                value: tasks.isEmpty ? '—' : '$doneTasks/${tasks.length}',
                color: context.cq.textMuted,
                onTap: () => context.go(AppRoute.kanban),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.local_fire_department_outlined,
                label: 'Habitudes',
                value: habits.isEmpty ? '—' : '$doneHabits/${habits.length}',
                color: context.cq.errorColor,
                onTap: () => context.go(AppRoute.habits),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.calendar_today_outlined,
                label: 'Focus / semaine',
                value: formatFocusDuration(stats.focusThisWeek),
                color: context.cq.vertDark,
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
    return  Card(
      child: SizedBox(
        height: 190,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: context.cq.vert),
          ),
        ),
      ),
    );
  }
}

// ─── Démarrage rapide ───────────────────────────────────────────────────────

class _QuickStartModule extends ConsumerWidget {
  const _QuickStartModule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider).valueOrNull ?? const <Task>[];
    final doing = tasks.where((t) => t.isDoing).firstOrNull;

    return QuickStartCard(
      onTap: () => context.go(AppRoute.pomodoro),
      subtitle: doing == null
          ? '25 min de focus · Pomodoro'
          : 'En cours : ${doing.title}',
    );
  }
}

// ─── Tâches ─────────────────────────────────────────────────────────────────

class _TasksModule extends ConsumerWidget {
  const _TasksModule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider).valueOrNull ?? const <Task>[];

    // Les tâches en retard d'abord, puis celles à échéance proche : le
    // Dashboard doit montrer ce qui presse, pas l'ordre d'insertion.
    final pending = tasks.where((t) => !t.isDone).toList()
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        final aDue = a.dueDate;
        final bDue = b.dueDate;
        if (aDue != null && bDue != null) return aDue.compareTo(bDue);
        if (aDue != null) return -1;
        if (bDue != null) return 1;
        return a.position.compareTo(b.position);
      });

    final preview = pending.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'À faire',
          onMore: () => context.go(AppRoute.kanban),
        ),
        const SizedBox(height: 10),
        if (preview.isEmpty)
          EmptySection(
            icon: tasks.isEmpty ? Icons.add_task : Icons.celebration_outlined,
            message: tasks.isEmpty
                ? 'Ajoute tes premières tâches'
                : 'Tout est fait pour l\'instant !',
            onAction: tasks.isEmpty ? () => context.go(AppRoute.kanban) : null,
            actionLabel: 'Créer une tâche',
          )
        else
          for (final task in preview)
            TaskPreviewRow(
              task: task,
              onToggle: () =>
                  ref.read(taskProvider.notifier).toggleDone(task.id),
              onOpen: () => context.go(AppRoute.kanban),
            ),
      ],
    );
  }
}

// ─── Habitudes ──────────────────────────────────────────────────────────────

class _HabitsModule extends ConsumerWidget {
  const _HabitsModule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider).valueOrNull ?? const [];

    // Les habitudes non validées remontent : la liste est une liste d'actions.
    final sorted = [...habits]..sort((a, b) {
        if (a.completedToday != b.completedToday) {
          return a.completedToday ? 1 : -1;
        }
        return b.streak.compareTo(a.streak);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Habitudes du jour',
          onMore: () => context.go(AppRoute.habits),
        ),
        const SizedBox(height: 10),
        if (habits.isEmpty)
          EmptySection(
            icon: Icons.check_circle_outline,
            message: 'Crée tes premières habitudes',
            onAction: () => context.go(AppRoute.habits),
            actionLabel: 'Commencer',
          )
        else
          for (final habit in sorted.take(5))
            HabitPreviewRow(
              habit: habit,
              onToggle: () =>
                  ref.read(habitProvider.notifier).toggleToday(habit),
            ),
      ],
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
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.go('${AppRoute.notes}/${note.id}'),
                borderRadius: BorderRadius.circular(AppTheme.radius),
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
                              style:  TextStyle(
                                  fontSize: 14, color: context.cq.textPrimary),
                            ),
                            if (note.subject != null)
                              Text(
                                note.subject!,
                                style:  TextStyle(
                                    fontSize: 11, color: context.cq.textMuted),
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
                style:  TextStyle(fontSize: 11, color: context.cq.textHint),
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
      StrainLevel.watch => const Color(0xFFE39A3B),
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
        Card(
          child: InkWell(
            onTap: () => context.go(
              hasEntryToday ? AppRoute.journal : AppRoute.journalEntry,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
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
                          style:  TextStyle(
                            fontSize: 14,
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
                          style:  TextStyle(
                              fontSize: 12, color: context.cq.textMuted),
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

// ─── Prochaines échéances ───────────────────────────────────────────────────

class _PlanningModule extends ConsumerWidget {
  const _PlanningModule();

  static const List<String> _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingPlanItemsProvider);
    final goals = ref.watch(activeGoalsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Prochaines échéances',
          onMore: () => context.go(AppRoute.planning),
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty && goals.isEmpty)
          EmptySection(
            icon: Icons.event_outlined,
            message: 'Planifie tes examens et objectifs',
            onAction: () => context.go(AppRoute.planning),
            actionLabel: 'Commencer',
          )
        else ...[
          for (final item in upcoming.take(3))
            _DeadlineRow(item: item, months: _months),
          if (upcoming.isEmpty && goals.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.go(AppRoute.goals),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                       Icon(Icons.flag_outlined,
                          size: 16, color: context.cq.textHint),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${goals.length} objectif${goals.length > 1 ? 's' : ''} en cours',
                          style:  TextStyle(
                              fontSize: 14, color: context.cq.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.item, required this.months});

  final PlanItem item;
  final List<String> months;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = DateTime(item.endDate.year, item.endDate.month, item.endDate.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final urgent = days <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go(AppRoute.gantt),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.isMilestone ? Icons.flag : Icons.event_outlined,
                size: 16,
                color: urgent ? context.cq.errorColor : context.cq.textHint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:  TextStyle(
                      fontSize: 14, color: context.cq.textPrimary),
                ),
              ),
              Text(
                days == 0
                    ? "Auj."
                    : (days == 1
                        ? 'Demain'
                        : '${item.endDate.day} ${months[item.endDate.month - 1]}'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: urgent ? FontWeight.w700 : FontWeight.w500,
                  color: urgent ? context.cq.errorColor : context.cq.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomiseHint extends StatelessWidget {
  const _CustomiseHint();

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.drag_indicator, size: 14, color: context.cq.textHint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Maintiens un module appuyé pour le déplacer',
              style: TextStyle(fontSize: 12, color: context.cq.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
