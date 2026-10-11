import '../../../shared/models/note_link_model.dart';
import '../../../shared/models/note_model.dart';

/// Un nœud du graphe : une fiche et son degré de connexion.
class GraphNode {
  const GraphNode({
    required this.note,
    required this.degree,
    required this.componentId,
  });

  final Note note;

  /// Nombre de fiches distinctes auxquelles celle-ci est reliée.
  final int degree;

  /// Identifiant de la composante connexe : deux fiches partageant ce numéro
  /// sont reliées par un chemin, directement ou non.
  final int componentId;

  bool get isIsolated => degree == 0;
}

/// Diagnostic du graphe — CdC : « Analyse du graphe de connaissances pour
/// détecter les zones sous-connectées ou surchargées ».
class GraphInsights {
  const GraphInsights({
    required this.isolatedNotes,
    required this.hubs,
    required this.componentCount,
    required this.largestComponentSize,
    required this.averageDegree,
  });

  /// Fiches sans aucun lien : le savoir « orphelin », que le CdC veut voir.
  final List<Note> isolatedNotes;

  /// Fiches nettement plus connectées que la moyenne : les plaques tournantes.
  final List<Note> hubs;

  /// Nombre d'îlots de connaissance indépendants.
  final int componentCount;

  final int largestComponentSize;
  final double averageDegree;

  bool get isEmpty => componentCount == 0;

  /// Message d'analyse affiché à l'utilisateur, dans l'esprit métacognitif du
  /// CdC : on commente la structure de pensée, on ne se contente pas de
  /// chiffres bruts.
  String get summary {
    if (isEmpty) return 'Crée quelques fiches pour voir ton graphe apparaître.';
    if (isolatedNotes.length == 1) {
      return '1 fiche n\'est reliée à rien. Relie-la pour l\'ancrer dans ce que '
          'tu sais déjà.';
    }
    if (isolatedNotes.length > 1) {
      return '${isolatedNotes.length} fiches ne sont reliées à rien. '
          'Les relier renforce la mémorisation.';
    }
    if (componentCount > 1) {
      return '$componentCount îlots de connaissances séparés. '
          'Cherche ce qui pourrait les relier.';
    }
    return 'Ton graphe est d\'un seul tenant. Belle structure.';
  }
}

/// Graphe de connaissances : construction, analyse et suggestions.
abstract final class KnowledgeGraph {
  /// Construit les nœuds à partir des fiches et des liens.
  ///
  /// Les liens dont une extrémité manque (fiche supprimée, non encore
  /// synchronisée) sont ignorés plutôt que de produire un nœud fantôme.
  static List<GraphNode> buildNodes(List<Note> notes, List<NoteLink> links) {
    final byId = {for (final note in notes) note.id: note};
    final adjacency = adjacencyOf(notes, links);
    final components = _components(byId.keys, adjacency);

    return notes
        .map((note) => GraphNode(
              note: note,
              degree: adjacency[note.id]?.length ?? 0,
              componentId: components[note.id] ?? -1,
            ))
        .toList();
  }

  /// Table d'adjacence non orientée : pour parcourir le graphe, le sens d'une
  /// arête n'a pas d'importance.
  static Map<String, Set<String>> adjacencyOf(
    List<Note> notes,
    List<NoteLink> links,
  ) {
    final ids = notes.map((n) => n.id).toSet();
    final adjacency = {for (final id in ids) id: <String>{}};

    for (final link in links) {
      if (!ids.contains(link.sourceId) || !ids.contains(link.targetId)) continue;
      // Une fiche reliée à elle-même ne compte pas comme une connexion.
      if (link.sourceId == link.targetId) continue;
      adjacency[link.sourceId]!.add(link.targetId);
      adjacency[link.targetId]!.add(link.sourceId);
    }
    return adjacency;
  }

  /// Composantes connexes, par parcours en largeur itératif (une récursion
  /// exploserait la pile sur un gros carnet).
  static Map<String, int> _components(
    Iterable<String> ids,
    Map<String, Set<String>> adjacency,
  ) {
    final component = <String, int>{};
    var current = 0;

    for (final id in ids) {
      if (component.containsKey(id)) continue;

      final queue = <String>[id];
      component[id] = current;

      while (queue.isNotEmpty) {
        final node = queue.removeLast();
        for (final neighbour in adjacency[node] ?? const <String>{}) {
          if (component.containsKey(neighbour)) continue;
          component[neighbour] = current;
          queue.add(neighbour);
        }
      }
      current++;
    }
    return component;
  }

  static GraphInsights analyse(List<Note> notes, List<NoteLink> links) {
    if (notes.isEmpty) {
      return const GraphInsights(
        isolatedNotes: [],
        hubs: [],
        componentCount: 0,
        largestComponentSize: 0,
        averageDegree: 0,
      );
    }

    final nodes = buildNodes(notes, links);
    final degrees = nodes.map((n) => n.degree);
    final averageDegree =
        degrees.fold<int>(0, (sum, d) => sum + d) / nodes.length;

    final sizeByComponent = <int, int>{};
    for (final node in nodes) {
      sizeByComponent[node.componentId] =
          (sizeByComponent[node.componentId] ?? 0) + 1;
    }

    // Une plaque tournante est au moins deux fois plus connectée que la
    // moyenne, avec un plancher : sur un petit carnet, « 2 liens » ne fait pas
    // de quelqu'un un carrefour.
    final hubThreshold = averageDegree * 2;
    final hubs = nodes
        .where((n) => n.degree >= 3 && n.degree >= hubThreshold)
        .toList()
      ..sort((a, b) => b.degree.compareTo(a.degree));

    return GraphInsights(
      isolatedNotes: nodes.where((n) => n.isIsolated).map((n) => n.note).toList(),
      hubs: hubs.take(5).map((n) => n.note).toList(),
      componentCount: sizeByComponent.length,
      largestComponentSize: sizeByComponent.values.isEmpty
          ? 0
          : sizeByComponent.values.reduce((a, b) => a > b ? a : b),
      averageDegree: averageDegree,
    );
  }

  /// Propose des liens à créer, sur la base des tags et du sujet partagés.
  ///
  /// Les paires déjà reliées sont exclues : on ne suggère jamais ce qui existe.
  static List<SuggestedLink> suggest(
    List<Note> notes,
    List<NoteLink> links, {
    int limit = 8,
  }) {
    final existing = <String>{};
    for (final link in links) {
      existing.add(_pairKey(link.sourceId, link.targetId));
    }

    final candidates = <SuggestedLink>[];

    for (var i = 0; i < notes.length; i++) {
      for (var j = i + 1; j < notes.length; j++) {
        final a = notes[i];
        final b = notes[j];
        if (a.isArchived || b.isArchived) continue;
        if (existing.contains(_pairKey(a.id, b.id))) continue;

        final sharedTags = a.tags
            .map((t) => t.toLowerCase())
            .toSet()
            .intersection(b.tags.map((t) => t.toLowerCase()).toSet());

        final sameSubject = a.subject != null && a.subject == b.subject;

        // Le sujet seul relierait tout un chapitre à lui-même : il ne suffit
        // pas, il renforce une proximité déjà établie par les tags.
        if (sharedTags.isEmpty) continue;

        final score = sharedTags.length * 10 + (sameSubject ? 5 : 0);
        final reason = [
          sharedTags.length == 1
              ? 'tag #${sharedTags.first}'
              : '${sharedTags.length} tags en commun',
          if (sameSubject) 'même sujet',
        ].join(' · ');

        candidates.add(SuggestedLink(
          sourceId: a.id,
          targetId: b.id,
          reason: reason,
          score: score,
        ));
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(limit).toList();
  }

  /// Voisins directs d'une fiche, avec le lien qui les relie.
  static List<(Note, NoteLink)> neighboursOf(
    String noteId,
    List<Note> notes,
    List<NoteLink> links,
  ) {
    final byId = {for (final note in notes) note.id: note};
    final result = <(Note, NoteLink)>[];

    for (final link in links) {
      final other = link.otherEnd(noteId);
      if (other == null || other == noteId) continue;
      final note = byId[other];
      if (note != null) result.add((note, link));
    }
    return result;
  }

  /// Clé canonique d'une paire, indépendante de l'ordre.
  static String _pairKey(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
}
