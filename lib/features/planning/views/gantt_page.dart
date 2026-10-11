import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/planning_model.dart';
import '../domain/gantt_timeline.dart';
import '../providers/planning_provider.dart';
import '../widgets/plan_item_sheet.dart';

/// Diagramme de Gantt — « vue chronologique horizontale avec barres
/// ajustables », « zoom (jour, semaine, mois) », « affichage des
/// dépendances » (CdC).
class GanttPage extends ConsumerWidget {
  const GanttPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(ganttLayoutProvider);
    final zoom = ref.watch(ganttZoomProvider);
    final violations = ref.watch(dependencyViolationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning'),
        actions: [
          PopupMenuButton<GanttZoom>(
            tooltip: 'Zoom',
            icon: const Icon(Icons.zoom_in),
            initialValue: zoom,
            onSelected: (value) =>
                ref.read(ganttZoomProvider.notifier).state = value,
            itemBuilder: (_) => [
              for (final level in GanttZoom.values)
                PopupMenuItem(value: level, child: Text(level.label)),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: layout.isEmpty
          ? const _EmptyGantt()
          : Column(
              children: [
                if (violations.isNotEmpty)
                  _ViolationBanner(items: violations),
                Expanded(
                  child: _GanttChart(layout: layout, zoom: zoom),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final draft = await PlanItemSheet.show(context);
          if (draft == null) return;
          await ref.read(planningActionsProvider).savePlanItem(draft);
        },
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle échéance',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _GanttChart extends ConsumerWidget {
  const _GanttChart({required this.layout, required this.zoom});

  final GanttLayout layout;
  final GanttZoom zoom;

  static const double _laneHeight = 44;
  static const double _labelWidth = 128;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = layout.totalDays * zoom.pixelsPerDay;
    final todayOffset = layout.offsetOf(DateTime.now());

    // Une ligne par piste, plus l'en-tête de dates.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _labelWidth + width,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateHeader(
                layout: layout,
                zoom: zoom,
                labelWidth: _labelWidth,
              ),
              const Divider(height: 1),
              SizedBox(
                height: layout.laneCount * _laneHeight + 12,
                child: Stack(
                  children: [
                    // Marqueur « aujourd'hui », sous les barres pour ne pas
                    // masquer leur contenu.
                    if (todayOffset != null)
                      Positioned(
                        left: _labelWidth + todayOffset * zoom.pixelsPerDay,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: context.cq.errorColor.withValues(alpha: 0.5),
                        ),
                      ),
                    for (final placed in layout.items)
                      Positioned(
                        left: _labelWidth +
                            placed.dayOffset * zoom.pixelsPerDay,
                        top: placed.lane * _laneHeight + 6,
                        width: (placed.durationDays * zoom.pixelsPerDay)
                            .clamp(14.0, double.infinity),
                        height: _laneHeight - 12,
                        child: _Bar(placed: placed, zoom: zoom),
                      ),
                    for (var lane = 0; lane < layout.laneCount; lane++)
                      Positioned(
                        left: 0,
                        top: lane * _laneHeight + 6,
                        width: _labelWidth,
                        height: _laneHeight - 12,
                        child: _LaneLabel(
                          items: layout.items
                              .where((p) => p.lane == lane)
                              .map((p) => p.item)
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.layout,
    required this.zoom,
    required this.labelWidth,
  });

  final GanttLayout layout;
  final GanttZoom zoom;
  final double labelWidth;

  static const List<String> _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  /// Un repère tous les N jours, pour que les étiquettes ne se chevauchent
  /// jamais quel que soit le zoom.
  int get _step => switch (zoom) {
        GanttZoom.day => 1,
        GanttZoom.week => 7,
        GanttZoom.month => 14,
      };

  @override
  Widget build(BuildContext context) {
    final start = layout.start;
    if (start == null) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: Stack(
        children: [
          for (var day = 0; day < layout.totalDays; day += _step)
            Positioned(
              left: labelWidth + day * zoom.pixelsPerDay,
              top: 8,
              child: Builder(
                builder: (context) {
                  final date = start.add(Duration(days: day));
                  return Text(
                    zoom == GanttZoom.month
                        ? '${date.day}/${date.month}'
                        : '${date.day} ${_months[date.month - 1]}',
                    style:  TextStyle(
                        fontSize: 10, color: context.cq.textHint),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.placed, required this.zoom});

  final PlacedItem placed;
  final GanttZoom zoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = placed.item;

    final color = item.isLate
        ? context.cq.errorColor
        : (item.isComplete ? context.cq.textMuted : context.cq.vertDark);

    if (item.isMilestone) {
      return Tooltip(
        message: '${item.title} · jalon',
        child: GestureDetector(
          onTap: () => _edit(context, ref, item),
          child: Center(
            child: Transform.rotate(
              angle: 0.785, // 45° : le losange classique des jalons.
              child: Container(
                width: 14,
                height: 14,
                color: item.isLate ? context.cq.errorColor : context.cq.vertDark,
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: '${item.title}\n'
          '${item.durationDays} j · ${(item.progress * 100).round()} %'
          '${item.dependsOnId != null ? '\nDépend d\'une autre étape' : ''}',
      child: GestureDetector(
        onTap: () => _edit(context, ref, item),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Stack(
            children: [
              // Remplissage proportionnel à l'avancement.
              FractionallySizedBox(
                widthFactor: item.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:  TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.cq.textPrimary,
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

  Future<void> _edit(BuildContext context, WidgetRef ref, PlanItem item) async {
    final draft = await PlanItemSheet.show(context, item: item);
    if (draft == null) return;
    await ref.read(planningActionsProvider).savePlanItem(draft);
  }
}

class _LaneLabel extends StatelessWidget {
  const _LaneLabel({required this.items});

  final List<PlanItem> items;

  @override
  Widget build(BuildContext context) {
    final subjects = items
        .map((i) => i.subject)
        .whereType<String>()
        .toSet()
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          subjects.isEmpty ? '—' : subjects,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:  TextStyle(fontSize: 11, color: context.cq.textMuted),
        ),
      ),
    );
  }
}

class _ViolationBanner extends StatelessWidget {
  const _ViolationBanner({required this.items});

  final List<PlanItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE39A3B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFE39A3B).withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 17, color: Color(0xFFE39A3B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${items.length} étape${items.length > 1 ? 's' : ''} '
              'démarre${items.length > 1 ? 'nt' : ''} avant la fin de ce dont '
              'elle${items.length > 1 ? 's' : ''} dépend'
              '${items.length > 1 ? 'ent' : ''} : '
              '${items.map((i) => i.title).join(', ')}.',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFE39A3B), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGantt extends StatelessWidget {
  const _EmptyGantt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.view_timeline_outlined,
                size: 48, color: context.cq.textHint),
            const SizedBox(height: 16),
            Text('Planning vide',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
             Text(
              'Ajoute tes échéances et jalons, ou génère un plan depuis '
              'l\'ordre de révision.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.cq.textMuted, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
