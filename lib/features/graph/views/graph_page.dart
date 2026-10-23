import 'dart:math' as math;

import 'package:flutter/rendering.dart' show SemanticsProperties;
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
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
import '../../../core/theme/tokens.dart';

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

  /// Encadré d'analyse refermé pour cette visite (l'analyse complète reste
  /// dans le bouton de la barre).
  bool _insightsClosed = false;

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
          if (!_insightsClosed)
            _InsightBanner(
              insights: insights,
              onClose: () => setState(() => _insightsClosed = true),
            ),
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

/// Calcul asynchrone de la disposition utilisé par la carte.
///
/// Remplaçable uniquement par les tests, pour maîtriser l'ordre dans lequel
/// deux calculs concurrents se terminent.
@visibleForTesting
Future<GraphLayout> Function(List<String>, List<(String, String)>)
    graphLayoutAsync = GraphLayout.computeAsync;

/// Toile du graphe, façon Obsidian : des points et leurs titres flottants,
/// peints directement, animés par une simulation physique continue.
///
/// - Attraper un point le déplace n'importe où ; ses voisins suivent,
///   élastiquement, en temps réel.
/// - Glisser le fond déplace la carte ; pincer ou la molette zoome.
/// - Survoler un point met en avant ses liens et ses voisins.
///
/// La disposition de départ (déterministe) n'est recalculée que si les
/// fiches ou les liens changent : sélectionner un nœud ne bouge rien.
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

class _GraphCanvasState extends State<_GraphCanvas>
    with SingleTickerProviderStateMixin {
  static const double _minScale = 0.15;
  static const double _maxScale = 3;

  final GraphSimulation _simulation = GraphSimulation();

  /// Une frame de plus à peindre (simulation ou caméra).
  final ValueNotifier<int> _frame = ValueNotifier(0);

  late final Ticker _ticker;

  /// Caméra : position à l'écran de l'origine du monde, et zoom.
  Offset _origin = Offset.zero;
  double _scale = 1;
  double _gestureStartScale = 1;
  Size? _viewport;
  bool _needsFit = true;

  String _signature = '';
  bool _hasLayout = false;
  String? _hovered;

  /// Un calcul asynchrone est en cours ; la carte précédente reste affichée.
  bool _isComputing = false;

  /// Numéro du dernier calcul lancé : le résultat d'un calcul dépassé (les
  /// fiches ont changé entre-temps) est ignoré.
  int _generation = 0;

  final Map<String, TextPainter> _labels = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _onTick());
    _relayoutIfNeeded();
  }

  @override
  void didUpdateWidget(_GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _relayoutIfNeeded();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    for (final label in _labels.values) {
      label.dispose();
    }
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
    _clearLabels();
    final edgePairs = [for (final l in widget.links) (l.sourceId, l.targetId)];
    final generation = ++_generation;

    // Petit carnet : le calcul tient dans une frame, il reste synchrone et
    // la carte s'affiche d'emblée.
    if (ids.length <= GraphLayout.asyncThreshold) {
      _isComputing = false;
      _applyLayout(GraphLayout.compute(ids, edgePairs), edgePairs);
      return;
    }

    // Grand carnet : calcul hors du thread UI (isolate, ou tranches sur le
    // web).
    _isComputing = true;
    graphLayoutAsync(ids, edgePairs).then((layout) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _isComputing = false;
        _applyLayout(layout, edgePairs);
      });
    });
  }

  void _applyLayout(GraphLayout layout, List<(String, String)> edges) {
    final first = !_hasLayout;
    _simulation.load(layout, edges);
    _hasLayout = !layout.isEmpty;
    if (first) _needsFit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _kick();
    });
  }

  void _clearLabels() {
    for (final label in _labels.values) {
      label.dispose();
    }
    _labels.clear();
  }

  /// Relance la simulation : en continu à 60 FPS, ou d'un coup jusqu'au
  /// repos quand les animations sont réduites.
  void _kick() {
    if (Motion.reduced(context)) {
      if (_simulation.pinned == null) _simulation.settle();
      setState(() {});
      return;
    }
    if (!_ticker.isActive && _simulation.isActive) _ticker.start();
  }

  void _onTick() {
    _simulation.tick();
    _frame.value++;
    if (!_simulation.isActive) {
      _ticker.stop();
      // Carte posée : la sémantique (position de chaque point pour les
      // lecteurs d'écran) est reconstruite une fois.
      setState(() {});
    }
  }

  Offset _toWorld(Offset screen) => (screen - _origin) / _scale;

  String? _hit(Offset screen) =>
      _simulation.hitTest(_toWorld(screen), 22 / _scale + 6);

  /// Cadre toute la carte dans la zone visible, sans agrandir au-delà de la
  /// taille réelle.
  void _fit(Size viewport) {
    final bounds = _simulation.bounds;
    if (viewport.isEmpty) return;
    const margin = 120.0;
    final width = bounds.width + 2 * margin;
    final height = bounds.height + 2 * margin;
    _scale = math
        .min(viewport.width / width, viewport.height / height)
        .clamp(_minScale, 1.0);
    _origin = viewport.center(Offset.zero) - bounds.center * _scale;
    _needsFit = false;
    _frame.value++;
  }

  void _zoomAt(Offset focal, double scale) {
    final clamped = scale.clamp(_minScale, _maxScale);
    final world = _toWorld(focal);
    _scale = clamped;
    _origin = focal - world * _scale;
    _frame.value++;
  }

  /// Où le doigt s'est posé : le geste ne démarre qu'après le seuil de
  /// glissement, quelques pixels plus loin, parfois hors du point.
  Offset? _pointerDown;

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartScale = _scale;
    final down = _pointerDown ?? details.localFocalPoint;
    final id = details.pointerCount == 1 ? _hit(down) : null;
    if (id == null) return;
    _simulation.pin(id, _toWorld(details.localFocalPoint));
    setState(() => _hovered = id);
    _kick();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_simulation.pinned != null) {
      _simulation.movePin(_toWorld(details.localFocalPoint));
      if (Motion.reduced(context)) {
        // Sans animation : les voisins se replacent aussitôt.
        for (var i = 0; i < 8; i++) {
          _simulation.tick();
        }
      }
      _frame.value++;
      return;
    }
    _origin += details.focalPointDelta;
    if (details.pointerCount > 1) {
      _zoomAt(details.localFocalPoint, _gestureStartScale * details.scale);
    } else {
      _frame.value++;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_simulation.pinned == null) return;
    _simulation.release();
    setState(() => _hovered = null);
    _kick();
  }

  TextPainter _labelFor(GraphNode node, TextStyle style) =>
      _labels.putIfAbsent(
        node.note.id,
        () => TextPainter(
          text: TextSpan(text: node.note.displayTitle, style: style),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: 160),
      );

  @override
  Widget build(BuildContext context) {
    final byId = {for (final node in widget.nodes) node.note.id: node};
    final cq = context.cq;
    final labelStyle = TextStyle(
      fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
      fontSize: TypeScale.caption,
      color: cq.textPrimary,
    );
    // Changement de thème : les titres sont repeints dans la bonne couleur.
    final cached = _labels.values.firstOrNull?.text?.style?.color;
    if (cached != null && cached != labelStyle.color) _clearLabels();

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        if (_viewport != viewport) {
          _viewport = viewport;
          _needsFit = true;
        }
        if (_needsFit && _hasLayout) _fit(viewport);

        return Stack(
          children: [
            Listener(
              onPointerDown: (event) => _pointerDown = event.localPosition,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _zoomAt(event.localPosition,
                      _scale * math.exp(-event.scrollDelta.dy / 400));
                }
              },
              child: MouseRegion(
                cursor: _hovered == null
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.grab,
                onHover: (event) {
                  final id = _hit(event.localPosition);
                  if (id != _hovered) setState(() => _hovered = id);
                },
                onExit: (_) {
                  if (_simulation.pinned == null && _hovered != null) {
                    setState(() => _hovered = null);
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final id = _hit(details.localPosition);
                    if (byId[id] case final node?) widget.onTapNode(node.note);
                  },
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  child: CustomPaint(
                    key: const Key('graph-canvas'),
                    size: Size.infinite,
                    painter: _GraphPainter(
                      repaint: _frame,
                      simulation: _simulation,
                      view: () => (_origin, _scale),
                      nodes: byId,
                      links: widget.links,
                      linkColors: {
                        for (final type in NoteLinkType.values)
                          type: _linkColor(context, type),
                      },
                      nodeColor: cq.vertSauge,
                      isolatedColor: cq.textHint,
                      ringColor: cq.textPrimary,
                      background: cq.beige,
                      selectedId: widget.selectedNoteId,
                      focusId: _simulation.pinned ?? _hovered,
                      label: (node) => _labelFor(node, labelStyle),
                      onTapNode: widget.onTapNode,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: Space.lg,
              bottom: Space.lg,
              child: FloatingActionButton.small(
                heroTag: 'graph-fit',
                tooltip: 'Recentrer',
                onPressed: () => _fit(viewport),
                child: const Icon(Icons.center_focus_strong_outlined),
              ),
            ),
            // Premier calcul d'un grand carnet : rien à montrer encore.
            if (_isComputing && !_hasLayout)
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

/// Peint le graphe : liens, points (taille selon le degré) et titres
/// flottants. Survolée ou tenue, une fiche met en avant ses liens et ses
/// voisines ; le reste s'estompe. Chaque point est annoncé aux lecteurs
/// d'écran et activable (sémantique du painter).
class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required Listenable repaint,
    required this.simulation,
    required this.view,
    required this.nodes,
    required this.links,
    required this.linkColors,
    required this.nodeColor,
    required this.isolatedColor,
    required this.ringColor,
    required this.background,
    required this.selectedId,
    required this.focusId,
    required this.label,
    required this.onTapNode,
  }) : super(repaint: repaint);

  final GraphSimulation simulation;
  final (Offset, double) Function() view;
  final Map<String, GraphNode> nodes;
  final List<NoteLink> links;
  final Map<NoteLinkType, Color> linkColors;
  final Color nodeColor;
  final Color isolatedColor;
  final Color ringColor;
  final Color background;
  final String? selectedId;
  final String? focusId;
  final TextPainter Function(GraphNode) label;
  final ValueChanged<Note> onTapNode;

  static double radiusOf(GraphNode node) =>
      5 + math.min(node.degree, 12) * 0.9;

  Set<String> get _neighbours {
    final focus = focusId;
    if (focus == null) return const {};
    return {
      focus,
      for (final l in links)
        if (l.sourceId == focus)
          l.targetId
        else if (l.targetId == focus)
          l.sourceId,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (origin, scale) = view();
    final positions = simulation.positions;
    final neighbours = _neighbours;
    final dimming = focusId != null;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);

    for (final link in links) {
      final from = positions[link.sourceId];
      final to = positions[link.targetId];
      if (from == null || to == null || link.sourceId == link.targetId) {
        continue;
      }
      final touches = focusId != null && link.touches(focusId!) ||
          selectedId != null && link.touches(selectedId!);
      final color = linkColors[link.type]!;
      final paint = Paint()
        ..color = dimming && !touches ? color.withValues(alpha: 0.18) : color
        ..strokeWidth = (touches ? 2.2 : 1.1) / math.sqrt(scale)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, paint);
      if (link.type.isDirected) _drawArrow(canvas, from, to, paint.color);
    }

    // Titres visibles de loin seulement pour la fiche en avant et ses
    // voisines ; tous dès qu'on zoome assez pour les lire.
    final showAllLabels = scale >= 0.55;
    for (final MapEntry(key: id, value: center) in positions.entries) {
      final node = nodes[id];
      if (node == null) continue;
      final faded = dimming && !neighbours.contains(id);
      final radius = radiusOf(node);
      final base = node.isIsolated ? isolatedColor : nodeColor;
      canvas.drawCircle(
          center, radius, Paint()..color = faded ? base.withValues(alpha: 0.25) : base);
      if (id == selectedId || id == focusId) {
        canvas.drawCircle(
          center,
          radius + 3,
          Paint()
            ..color = ringColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
      if (!showAllLabels && !neighbours.contains(id) && id != selectedId) {
        continue;
      }
      final text = label(node);
      final topLeft =
          center + Offset(-text.width / 2, radius + 4);
      if (faded) {
        canvas.saveLayer(
            topLeft & text.size,
            Paint()..color = background.withValues(alpha: 0.35));
        text.paint(canvas, topLeft);
        canvas.restore();
      } else {
        text.paint(canvas, topLeft);
      }
    }
    canvas.restore();
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final delta = to - from;
    if (delta.distance < 1) return;
    final direction = delta / delta.distance;
    final normal = Offset(-direction.dy, direction.dx);
    const length = 9.0;
    final tip = from + delta / 2 + direction * (length / 2);
    final base = tip - direction * length;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + normal.dx * 5, base.dy + normal.dy * 5)
        ..lineTo(base.dx - normal.dx * 5, base.dy - normal.dy * 5)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
        final (origin, scale) = view();
        return [
          for (final MapEntry(key: id, value: center)
              in simulation.positions.entries)
            if (nodes[id] case final node?)
              CustomPainterSemantics(
                key: ValueKey(id),
                rect: Rect.fromCircle(
                  center: origin + center * scale,
                  radius: math.max(radiusOf(node) * scale, 12),
                ),
                properties: SemanticsProperties(
                  label: node.note.displayTitle,
                  hint: '${node.degree} lien${node.degree > 1 ? 's' : ''}',
                  button: true,
                  selected: id == selectedId,
                  onTap: () => onTapNode(node.note),
                  textDirection: TextDirection.ltr,
                ),
              ),
        ];
      };

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(_GraphPainter oldDelegate) => true;
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.insights, required this.onClose});

  final GraphInsights insights;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final needsAttention = insights.isolatedNotes.isNotEmpty ||
        insights.componentCount > 1;
    final color = needsAttention ? context.cq.warning : context.cq.vertDark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(Radii.md),
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
              style: TextStyle(fontSize: TypeScale.caption, color: color, height: 1.35),
            ),
          ),
          IconButton(
            tooltip: 'Fermer l’analyse',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: Sizes.iconSm, color: color),
            onPressed: onClose,
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
              label: const Text('Tout', style: TextStyle(fontSize: TypeScale.caption)),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          for (final subject in subjects)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(subject, style: const TextStyle(fontSize: TypeScale.caption)),
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
                  color: context.cq.textMuted, fontSize: TypeScale.body, height: 1.4),
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
