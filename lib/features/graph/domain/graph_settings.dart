import '../../../shared/models/note_link_model.dart';
import '../../../shared/models/note_model.dart';
import '../../notes/domain/wiki_links.dart';
import 'knowledge_graph.dart';

/// Forces de la simulation physique du graphe.
class GraphForces {
  const GraphForces({
    this.center = 0.03,
    this.repel = 1.1,
    this.link = 0.7,
    this.distance = 170,
  });

  /// Rappel vers le centre (retient les îlots).
  final double center;

  /// Répulsion entre fiches (en multiple de la distance au carré).
  final double repel;

  /// Raideur des liens.
  final double link;

  /// Longueur de repos d'un lien, en unités du monde.
  final double distance;

  static const ({double min, double max}) centerRange = (min: 0, max: 0.15);
  static const ({double min, double max}) repelRange = (min: 0, max: 4);
  static const ({double min, double max}) linkRange = (min: 0, max: 2);
  static const ({double min, double max}) distanceRange = (min: 40, max: 400);

  GraphForces copyWith({
    double? center,
    double? repel,
    double? link,
    double? distance,
  }) =>
      GraphForces(
        center: center ?? this.center,
        repel: repel ?? this.repel,
        link: link ?? this.link,
        distance: distance ?? this.distance,
      );

  @override
  bool operator ==(Object other) =>
      other is GraphForces &&
      other.center == center &&
      other.repel == repel &&
      other.link == link &&
      other.distance == distance;

  @override
  int get hashCode => Object.hash(center, repel, link, distance);
}

/// Réglages du graphe, en quatre sections (comme Obsidian) : filtres,
/// groupes, affichage, forces.
class GraphSettings {
  const GraphSettings({
    this.query = '',
    this.showAttachments = false,
    this.existingOnly = true,
    this.showOrphans = true,
    this.colorByFolder = false,
    this.groupByFolder = false,
    this.colorLinksByType = true,
    this.labelThreshold = 0.55,
    this.nodeSize = 1,
    this.linkThickness = 1,
    this.forces = const GraphForces(),
  });

  static const GraphSettings defaults = GraphSettings();

  // ── Filtres ──────────────────────────────────────────────────────────
  /// Mots-clés cherchés dans le titre, les tags, le sujet et le texte.
  final String query;

  /// Pièces jointes (images, vidéos, PDF) en nœuds satellites de leur fiche.
  final bool showAttachments;

  /// `false` : les `[[Titre]]` qui ne mènent à aucune fiche apparaissent en
  /// nœuds fantômes.
  final bool existingOnly;

  /// Fiches sans aucun lien.
  final bool showOrphans;

  // ── Groupes ──────────────────────────────────────────────────────────
  /// Couleur des fiches selon leur dossier.
  final bool colorByFolder;

  /// Les fiches d'un même dossier s'attirent : la carte se regroupe.
  final bool groupByFolder;

  /// Couleur des liens selon leur type (lié, vu, à revoir, prérequis).
  final bool colorLinksByType;

  // ── Affichage ────────────────────────────────────────────────────────
  /// Zoom à partir duquel tous les titres apparaissent (en deçà, seuls les
  /// carrefours sont titrés).
  final double labelThreshold;

  /// Multiplicateur de la taille des nœuds.
  final double nodeSize;

  /// Multiplicateur de l'épaisseur des liens.
  final double linkThickness;

  static const ({double min, double max}) labelRange = (min: 0.1, max: 2);
  static const ({double min, double max}) nodeSizeRange = (min: 0.5, max: 2.5);
  static const ({double min, double max}) linkRange = (min: 0.3, max: 3);

  // ── Forces ───────────────────────────────────────────────────────────
  final GraphForces forces;

  GraphSettings copyWith({
    String? query,
    bool? showAttachments,
    bool? existingOnly,
    bool? showOrphans,
    bool? colorByFolder,
    bool? groupByFolder,
    bool? colorLinksByType,
    double? labelThreshold,
    double? nodeSize,
    double? linkThickness,
    GraphForces? forces,
  }) =>
      GraphSettings(
        query: query ?? this.query,
        showAttachments: showAttachments ?? this.showAttachments,
        existingOnly: existingOnly ?? this.existingOnly,
        showOrphans: showOrphans ?? this.showOrphans,
        colorByFolder: colorByFolder ?? this.colorByFolder,
        groupByFolder: groupByFolder ?? this.groupByFolder,
        colorLinksByType: colorLinksByType ?? this.colorLinksByType,
        labelThreshold: labelThreshold ?? this.labelThreshold,
        nodeSize: nodeSize ?? this.nodeSize,
        linkThickness: linkThickness ?? this.linkThickness,
        forces: forces ?? this.forces,
      );

  Map<String, dynamic> toJson() => {
        'query': query,
        'attachments': showAttachments,
        'existing_only': existingOnly,
        'orphans': showOrphans,
        'color_folders': colorByFolder,
        'group_folders': groupByFolder,
        'color_links': colorLinksByType,
        'label_threshold': labelThreshold,
        'node_size': nodeSize,
        'link_thickness': linkThickness,
        'center': forces.center,
        'repel': forces.repel,
        'link': forces.link,
        'distance': forces.distance,
      };

  /// Tolérant : une valeur absente ou hors bornes retombe sur le défaut.
  factory GraphSettings.fromJson(Map<String, dynamic> json) {
    bool flag(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    double number(String key, double fallback,
        ({double min, double max}) range) {
      final value = json[key];
      return value is num
          ? value.toDouble().clamp(range.min, range.max)
          : fallback;
    }

    const d = GraphSettings.defaults;
    const f = GraphForces();
    return GraphSettings(
      query: json['query'] is String ? json['query'] as String : '',
      showAttachments: flag('attachments', d.showAttachments),
      existingOnly: flag('existing_only', d.existingOnly),
      showOrphans: flag('orphans', d.showOrphans),
      colorByFolder: flag('color_folders', d.colorByFolder),
      groupByFolder: flag('group_folders', d.groupByFolder),
      colorLinksByType: flag('color_links', d.colorLinksByType),
      labelThreshold: number('label_threshold', d.labelThreshold, labelRange),
      nodeSize: number('node_size', d.nodeSize, nodeSizeRange),
      linkThickness: number('link_thickness', d.linkThickness, linkRange),
      forces: GraphForces(
        center: number('center', f.center, GraphForces.centerRange),
        repel: number('repel', f.repel, GraphForces.repelRange),
        link: number('link', f.link, GraphForces.linkRange),
        distance: number('distance', f.distance, GraphForces.distanceRange),
      ),
    );
  }
}

/// Préfixes des nœuds qui ne sont pas des fiches.
abstract final class GraphNodeIds {
  static const String attachment = 'att:';
  static const String ghost = 'ghost:';

  static bool isAttachment(String id) => id.startsWith(attachment);
  static bool isGhost(String id) => id.startsWith(ghost);
}

/// Vue du graphe après réglages : nœuds et liens à dessiner.
class GraphViewData {
  const GraphViewData(this.nodes, this.links);

  final List<GraphNode> nodes;
  final List<NoteLink> links;
}

abstract final class GraphView {
  /// Applique les filtres aux fiches et aux liens, et ajoute pièces jointes
  /// et fiches fantômes si demandé.
  static GraphViewData build(
    List<Note> notes,
    List<NoteLink> links,
    GraphSettings settings,
  ) {
    final query = settings.query.trim().toLowerCase();
    final visible = query.isEmpty
        ? notes
        : notes.where((n) => _matches(n, query)).toList();

    final extraNotes = <Note>[];
    final extraLinks = <NoteLink>[];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    NoteLink synthetic(String id, String source, String target) => NoteLink(
          id: id,
          userId: '',
          sourceId: source,
          targetId: target,
          type: NoteLinkType.related,
          createdAt: epoch,
        );

    if (settings.showAttachments) {
      for (final note in visible) {
        for (final block in note.blocks.where((b) => b.type.isMedia)) {
          if (block.content.trim().isEmpty) continue;
          final id = '${GraphNodeIds.attachment}${block.id}';
          extraNotes.add(Note(
            id: id,
            userId: note.userId,
            title: _attachmentTitle(block),
            content: '',
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
            folderId: note.folderId,
          ));
          extraLinks.add(synthetic('$id-link', note.id, id));
        }
      }
    }

    if (!settings.existingOnly) {
      final ghosts = <String, String>{};
      for (final note in visible) {
        // Titres tels qu'écrits (titlesIn les normalise en minuscules).
        for (final match in WikiLinks.pattern.allMatches(note.content)) {
          final title = match.group(1)!.trim();
          if (title.isEmpty || WikiLinks.resolve(title, notes) != null) {
            continue;
          }
          final id = '${GraphNodeIds.ghost}${title.toLowerCase()}';
          ghosts.putIfAbsent(id, () => title);
          final linkId = '$id-${note.id}';
          // Un même titre cité deux fois : un seul lien.
          if (extraLinks.any((l) => l.id == linkId)) continue;
          extraLinks.add(synthetic(linkId, note.id, id));
        }
      }
      for (final MapEntry(key: id, value: title) in ghosts.entries) {
        extraNotes.add(Note(
          id: id,
          userId: '',
          title: title,
          content: '',
          createdAt: epoch,
          updatedAt: epoch,
        ));
      }
    }

    final all = [...visible, ...extraNotes];
    final ids = {for (final n in all) n.id};
    final allLinks = [
      for (final link in [...links, ...extraLinks])
        if (ids.contains(link.sourceId) && ids.contains(link.targetId)) link,
    ];
    var nodes = KnowledgeGraph.buildNodes(all, allLinks);
    if (!settings.showOrphans) {
      nodes = nodes.where((n) => n.degree > 0).toList();
    }
    return GraphViewData(nodes, allLinks);
  }

  static bool _matches(Note note, String query) {
    bool has(String? text) => text != null && text.toLowerCase().contains(query);
    return has(note.title) ||
        has(note.subject) ||
        note.tags.any(has) ||
        has(note.content);
  }

  static String _attachmentTitle(NoteBlock block) => switch (block.type) {
        NoteBlockType.pdf => 'PDF',
        NoteBlockType.video => 'Vidéo',
        _ => 'Image',
      };
}
