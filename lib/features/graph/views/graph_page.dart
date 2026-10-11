import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/note_link_model.dart';
import '../../../shared/models/note_model.dart';
import '../../notes/providers/note_provider.dart';
import '../domain/graph_layout.dart';
import '../domain/knowledge_graph.dart';
import '../providers/graph_provider.dart';
import '../widgets/graph_insights_sheet.dart';
import '../widgets/node_preview_sheet.dart';

/// Graphe de liaison des connaissances — CdC : « visualiser les connexions
/// entre les pages, concepts et idées », avec zoom, filtrage et aperçu au
/// survol des nœuds.
class GraphPage extends ConsumerStatefulWidget {
  const GraphPage({super.key});

  @override
  ConsumerState<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends ConsumerState<GraphPage> {
  String? _selectedNoteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(graphActionsProvider).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(graphNodesProvider);
    final links = ref.watch(visibleLinksProvider);
    final insights = ref.watch(graphInsightsProvider);
    final subjects = ref.watch(noteSubjectsProvider);
    final subjectFilter = ref.watch(graphSubjectFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphe de connaissances'),
        actions: [
          IconButton(
            tooltip: 'Analyse du graphe',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => GraphInsightsSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _InsightBanner(insights: insights),
          if (subjects.isNotEmpty)
            _SubjectFilterBar(
              subjects: subjects,
              selected: subjectFilter,
              onSelect: (subject) => ref
                  .read(graphSubjectFilterProvider.notifier)
                  .state = subject,
            ),
          Expanded(
            child: nodes.isEmpty
                ? const _EmptyGraph()
                : _GraphCanvas(
                    nodes: nodes,
                    links: links,
                    selectedNoteId: _selectedNoteId,
                    onTapNode: (note) {
                      setState(() => _selectedNoteId = note.id);
                      NodePreviewSheet.show(context, noteId: note.id);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Toile du graphe : zoom et panoramique via `InteractiveViewer`.
///
/// La disposition n'est recalculée que si l'ensemble des fiches ou des liens
/// change — sélectionner un nœud ne fait donc pas bouger la carte.
class _GraphCanvas extends StatefulWidget {
  const _GraphCanvas({
    required this.nodes,
    required this.links,
    required this.selectedNoteId,
    required this.onTapNode,
  });

  final List<GraphNode> nodes;
  final List<NoteLink> links;
  final String? selectedNoteId;
  final ValueChanged<Note> onTapNode;

  @override
  State<_GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<_GraphCanvas> {
  static const double _minScale = 0.15;

  final _transformation = TransformationController();
  GraphLayout _layout = GraphLayout.empty;
  String _signature = '';
  Size? _fittedViewport;

  /// Un calcul asynchrone est en cours ; la carte précédente reste affichée.
  bool _isComputing = false;

  /// Numéro du dernier calcul lancé : le résultat d'un calcul dépassé (les
  /// fiches ont changé entre-temps) est ignoré.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _relayoutIfNeeded();
  }

  @override
  void didUpdateWidget(_GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _relayoutIfNeeded();
  }

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _relayoutIfNeeded() {
    final ids = widget.nodes.map((n) => n.note.id).toList()..sort();
    final edges = widget.links
        .map((l) => '${l.sourceId}>${l.targetId}')
        .toList()
      ..sort();
    final signature = '${ids.join(',')}|${edges.join(',')}';
    if (signature == _signature) return;

    _signature = signature;
    final edgePairs = [for (final l in widget.links) (l.sourceId, l.targetId)];
    final generation = ++_generation;

    // Petit carnet : le calcul tient dans une frame, il reste synchrone et
    // la carte s'affiche d'emblée, comme avant.
    if (ids.length <= GraphLayout.asyncThreshold) {
      _isComputing = false;
      _applyLayout(GraphLayout.compute(ids, edgePairs));
      return;
    }

    // Grand carnet : plusieurs centaines de millisecondes de calcul, hors du
    // thread UI (isolate, ou tranches sur le web).
    _isComputing = true;
    GraphLayout.computeAsync(ids, edgePairs).then((layout) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _isComputing = false;
        _applyLayout(layout);
      });
    });
  }

  void _applyLayout(GraphLayout layout) {
    _layout = layout;
    // Nouvelle carte : on la recadre au prochain affichage.
    _fittedViewport = null;
  }

  /// Cadre toute la carte dans la zone visible, sans agrandir au-delà de la
  /// taille réelle (des étiquettes géantes seraient illisibles).
  void _fitToViewport(Size viewport) {
    final size = _layout.size;
    if (size.isEmpty || viewport.isEmpty) return;
    final scale = math
        .min(viewport.width / size.width, viewport.height / size.height)
        .clamp(_minScale, 1.0);
    final offset = Offset(
      (viewport.width - size.width * scale) / 2,
      (viewport.height - size.height * scale) / 2,
    );
    _transformation.value = Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _fittedViewport = viewport;
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final node in widget.nodes) node.note.id: node};

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        if (_fittedViewport != viewport) _fitToViewport(viewport);

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformation,
              constrained: false,
              boundaryMargin: EdgeInsets.all(viewport.shortestSide),
              minScale: _minScale,
              maxScale: 3,
              child: SizedBox.fromSize(
                size: _layout.size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _EdgePainter(
                          layout: _layout,
                          links: widget.links,
                          colors: {
                            for (final type in NoteLinkType.values)
                              type: _linkColor(context, type),
                          },
                          highlightedId: widget.selectedNoteId,
                        ),
                      ),
                    ),
                    for (final MapEntry(key: id, value: center)
                        in _layout.positions.entries)
                      if (byId[id] case final node?)
                        Positioned(
                          key: ValueKey(id),
                          left: center.dx,
                          top: center.dy,
                          // Le nœud est centré sur sa position.
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: _NodeChip(
                              node: node,
                              isSelected: id == widget.selectedNoteId,
                              onTap: () => widget.onTapNode(node.note),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                heroTag: 'graph-fit',
                tooltip: 'Recentrer',
                onPressed: () => setState(() => _fitToViewport(viewport)),
                child: const Icon(Icons.center_focus_strong_outlined),
              ),
            ),
            // Premier calcul d'un grand carnet : rien à montrer encore.
            // Avant, l'écran entier restait figé pendant ce temps.
            if (_isComputing && _layout.isEmpty)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  static Color _linkColor(BuildContext context, NoteLinkType type) =>
      switch (type) {
        NoteLinkType.related => context.cq.textHint,
        NoteLinkType.seen => context.cq.vertDark,
        NoteLinkType.toReview => context.cq.errorColor,
        NoteLinkType.prerequisite => context.cq.warning,
      };
}

/// Trace les liens de centre à centre ; une relation orientée porte une flèche
/// à mi-parcours (à l'extrémité, elle serait cachée sous le nœud).
class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.layout,
    required this.links,
    required this.colors,
    required this.highlightedId,
  });

  final GraphLayout layout;
  final List<NoteLink> links;
  final Map<NoteLinkType, Color> colors;
  final String? highlightedId;

  @override
  void paint(Canvas canvas, Size size) {
    for (final link in links) {
      final from = layout.positions[link.sourceId];
      final to = layout.positions[link.targetId];
      if (from == null || to == null || link.sourceId == link.targetId) {
        continue;
      }

      final highlighted = highlightedId != null && link.touches(highlightedId!);
      final paint = Paint()
        ..color = colors[link.type]!
        ..strokeWidth = highlighted ? 2.8 : 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, paint);

      if (link.type.isDirected) _drawArrow(canvas, from, to, paint.color);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final delta = to - from;
    if (delta.distance < 1) return;
    final direction = delta / delta.distance;
    final normal = Offset(-direction.dy, direction.dx);
    const length = 10.0;
    final tip = from + delta / 2 + direction * (length / 2);
    final base = tip - direction * length;
    final left = base + normal * length * 0.55;
    final right = base - normal * length * 0.55;

    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.links != links ||
      oldDelegate.highlightedId != highlightedId ||
      !mapEquals(oldDelegate.colors, colors);
}

/// Nœud du graphe.
///
/// La taille croît avec le degré : une notion centrale se voit d'un coup d'œil,
/// sans avoir à lire les étiquettes.
class _NodeChip extends StatelessWidget {
  const _NodeChip({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  final GraphNode node;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIsolated = node.isIsolated;
    final scale = (1 + node.degree * 0.06).clamp(1.0, 1.45);

    return Tooltip(
      message: '${node.note.displayTitle}\n'
          '${node.degree} lien${node.degree > 1 ? 's' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(maxWidth: 150 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 8 * scale,
          ),
          decoration: BoxDecoration(
            color: isIsolated ? context.cq.cardColor : context.cq.vert,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? context.cq.textPrimary
                  : (isIsolated ? context.cq.beigeDark : context.cq.vertDark),
              width: isSelected ? 2.4 : 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                node.note.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: isIsolated ? context.cq.textMuted : Colors.white,
                ),
              ),
              if (node.note.subject != null)
                Text(
                  node.note.subject!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9 * scale,
                    color: isIsolated
                        ? context.cq.textHint
                        : context.cq.onVertMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.insights});

  final GraphInsights insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final needsAttention = insights.isolatedNotes.isNotEmpty ||
        insights.componentCount > 1;
    final color = needsAttention ? context.cq.warning : context.cq.vertDark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(
            needsAttention ? Icons.lightbulb_outline : Icons.check_circle_outline,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insights.summary,
              style: TextStyle(fontSize: 12.5, color: color, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectFilterBar extends StatelessWidget {
  const _SubjectFilterBar({
    required this.subjects,
    required this.selected,
    required this.onSelect,
  });

  final List<String> subjects;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tout', style: TextStyle(fontSize: 12)),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          for (final subject in subjects)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(subject, style: const TextStyle(fontSize: 12)),
                selected: selected == subject,
                onSelected: (isSelected) =>
                    onSelect(isSelected ? subject : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyGraph extends StatelessWidget {
  const _EmptyGraph();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.hub_outlined, size: 48, color: context.cq.textHint),
            const SizedBox(height: 16),
            Text('Pas encore de carte',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
             Text(
              'Crée des fiches, puis relie-les entre elles. '
              'Le graphe dessine alors ta structure de pensée.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.cq.textMuted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoute.notes),
              icon: const Icon(Icons.auto_stories_outlined, size: 18),
              label: const Text('Aller aux fiches'),
            ),
          ],
        ),
      ),
    );
  }
}
