import '../../../shared/models/planning_model.dart';

/// Niveau de zoom du Gantt — « zoom (jour, semaine, mois) » (CdC).
enum GanttZoom {
  day('Jour', 34),
  week('Semaine', 14),
  month('Mois', 5);

  const GanttZoom(this.label, this.pixelsPerDay);

  final String label;

  /// Largeur d'une journée à ce niveau de zoom.
  final double pixelsPerDay;
}

/// Un élément placé dans la grille : sa colonne de départ et sa ligne.
class PlacedItem {
  const PlacedItem({
    required this.item,
    required this.dayOffset,
    required this.durationDays,
    required this.lane,
  });

  final PlanItem item;

  /// Décalage en jours depuis le début de la fenêtre.
  final int dayOffset;

  final int durationDays;

  /// Ligne d'affichage : deux éléments qui se chevauchent n'y sont jamais.
  final int lane;
}

/// Résultat de la mise en page du diagramme.
class GanttLayout {
  const GanttLayout({
    required this.start,
    required this.end,
    required this.items,
    required this.laneCount,
  });

  const GanttLayout.empty()
      : start = null,
        end = null,
        items = const [],
        laneCount = 0;

  final DateTime? start;
  final DateTime? end;
  final List<PlacedItem> items;
  final int laneCount;

  bool get isEmpty => items.isEmpty;

  int get totalDays {
    final from = start;
    final to = end;
    if (from == null || to == null) return 0;
    return to.difference(from).inDays + 1;
  }

  /// Décalage en jours d'une date donnée dans la fenêtre, ou `null` si hors
  /// champ (le marqueur « aujourd'hui » ne doit pas se dessiner en dehors).
  int? offsetOf(DateTime date) {
    final from = start;
    if (from == null) return null;
    final offset = _dayOnly(date).difference(from).inDays;
    return offset < 0 || offset >= totalDays ? null : offset;
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Construction et validation du diagramme de Gantt.
abstract final class GanttTimeline {
  /// Marge de confort de part et d'autre de la période couverte.
  static const int paddingDays = 2;

  /// Place les éléments sur une grille temporelle, en évitant les
  /// chevauchements visuels.
  static GanttLayout layout(List<PlanItem> items) {
    if (items.isEmpty) return const GanttLayout.empty();

    final sorted = List<PlanItem>.from(items)
      ..sort((a, b) {
        final byStart = a.startDate.compareTo(b.startDate);
        return byStart != 0 ? byStart : a.title.compareTo(b.title);
      });

    var min = _dayOnly(sorted.first.startDate);
    var max = _dayOnly(sorted.first.endDate);
    for (final item in sorted) {
      final itemStart = _dayOnly(item.startDate);
      final itemEnd = _dayOnly(item.endDate);
      if (itemStart.isBefore(min)) min = itemStart;
      if (itemEnd.isAfter(max)) max = itemEnd;
    }

    final start = min.subtract(const Duration(days: paddingDays));
    final end = max.add(const Duration(days: paddingDays));

    // Attribution des lignes : on place chaque élément sur la première ligne
    // libre à sa date de début. Empiler tout sur une ligne rendrait les
    // chevauchements illisibles.
    final laneEnds = <int>[];
    final placed = <PlacedItem>[];

    for (final item in sorted) {
      final offset = _dayOnly(item.startDate).difference(start).inDays;
      final duration = item.durationDays;

      var lane = laneEnds.indexWhere((lastEnd) => lastEnd < offset);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(offset + duration - 1);
      } else {
        laneEnds[lane] = offset + duration - 1;
      }

      placed.add(PlacedItem(
        item: item,
        dayOffset: offset,
        durationDays: duration,
        lane: lane,
      ));
    }

    return GanttLayout(
      start: start,
      end: end,
      items: placed,
      laneCount: laneEnds.length,
    );
  }

  /// Vérifie qu'ajouter la dépendance `from → to` ne crée pas de cycle.
  ///
  /// Sans ce contrôle, une chaîne A→B→C→A rendrait tout calcul de planning
  /// infini, et l'interface se figerait au premier parcours.
  static bool wouldCreateCycle(
    List<PlanItem> items,
    String itemId,
    String dependsOnId,
  ) {
    if (itemId == dependsOnId) return true;

    final dependencies = {
      for (final item in items) item.id: item.dependsOnId,
    };
    // On simule la dépendance envisagée.
    dependencies[itemId] = dependsOnId;

    final seen = <String>{};
    String? cursor = itemId;

    while (cursor != null) {
      if (!seen.add(cursor)) return true;
      cursor = dependencies[cursor];
    }
    return false;
  }

  /// Dépendances violées : un élément qui démarre avant la fin de celui dont
  /// il dépend.
  static List<PlanItem> violatedDependencies(List<PlanItem> items) {
    final byId = {for (final item in items) item.id: item};
    final violations = <PlanItem>[];

    for (final item in items) {
      final parentId = item.dependsOnId;
      if (parentId == null) continue;
      final parent = byId[parentId];
      if (parent == null) continue;

      if (_dayOnly(item.startDate).isBefore(_dayOnly(parent.endDate))) {
        violations.add(item);
      }
    }
    return violations;
  }

  /// Décale un élément et propage le décalage à ce qui en dépend.
  ///
  /// Repousser une tâche sans bouger la suite produirait un planning
  /// silencieusement faux.
  static List<PlanItem> shift(
    List<PlanItem> items,
    String itemId,
    Duration offset,
  ) {
    final byId = {for (final item in items) item.id: item};
    final target = byId[itemId];
    if (target == null || offset == Duration.zero) return items;

    // Descendants directs et indirects.
    final toShift = <String>{itemId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final item in items) {
        final parent = item.dependsOnId;
        if (parent != null &&
            toShift.contains(parent) &&
            toShift.add(item.id)) {
          changed = true;
        }
      }
    }

    return [
      for (final item in items)
        if (toShift.contains(item.id))
          item.copyWith(
            startDate: item.startDate.add(offset),
            endDate: item.endDate.add(offset),
          )
        else
          item,
    ];
  }

  /// Prochaines échéances, jalons compris, à partir d'aujourd'hui.
  static List<PlanItem> upcoming(List<PlanItem> items, {int limit = 5}) {
    final today = _dayOnly(DateTime.now());
    final future = items
        .where((item) =>
            !item.isComplete && !_dayOnly(item.endDate).isBefore(today))
        .toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));
    return future.take(limit).toList();
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
