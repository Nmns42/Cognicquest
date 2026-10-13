import 'package:flutter/material.dart';

/// Modules affichables sur le Dashboard.
///
/// CdC : « Vue d'ensemble personnalisable : modules déplaçables par
/// drag-and-drop » et « Personnalisation du tableau de bord (activer/désactiver
/// modules) ».
///
/// ⚠️ La valeur `id` est persistée en base : ne jamais la renommer. Ajouter un
/// module se fait en fin d'énumération ; il apparaîtra automatiquement à la fin
/// des layouts déjà enregistrés (cf. [DashboardLayout.fromJson]).
enum DashboardModule {
  stats(
    id: 'stats',
    label: 'Progrès du jour',
    description: 'Sessions, focus, tâches et habitudes du jour',
    icon: Icons.insights_outlined,
  ),
  weeklyFocus(
    id: 'weekly_focus',
    label: 'Focus de la semaine',
    description: 'Temps d\'étude jour par jour',
    icon: Icons.bar_chart_outlined,
  ),
  quickStart(
    id: 'quick_start',
    label: 'Démarrage rapide',
    description: 'Lancer une session Pomodoro',
    icon: Icons.play_circle_outline,
  ),
  tasks(
    id: 'tasks',
    label: 'Tâches à faire',
    description: 'Les prochaines cartes du Kanban',
    icon: Icons.checklist_outlined,
  ),
  habits(
    id: 'habits',
    label: 'Habitudes du jour',
    description: 'Routines à valider aujourd\'hui',
    icon: Icons.local_fire_department_outlined,
  ),
  notes(
    id: 'notes',
    label: 'Fiches récentes',
    description: 'Les dernières fiches travaillées',
    icon: Icons.auto_stories_outlined,
  ),
  metacognition(
    id: 'metacognition',
    label: 'Journal & ressenti',
    description: 'Humeur, effort et bilan de session',
    icon: Icons.self_improvement_outlined,
  ),
  planning(
    id: 'planning',
    label: 'Prochaines échéances',
    description: 'Examens, rendus et objectifs à venir',
    icon: Icons.event_outlined,
  ),
  reviews(
    id: 'reviews',
    label: 'Révisions du jour',
    description: "Cartes à revoir aujourd'hui",
    icon: Icons.style_outlined,
  );

  const DashboardModule({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;

  /// Modules retirés de l'interface (code conservé) : jamais affichés, ni
  /// proposés dans « Personnaliser », même dans une disposition enregistrée.
  static const Set<DashboardModule> retired = {DashboardModule.habits};

  bool get isRetired => retired.contains(this);

  static DashboardModule? fromId(String id) {
    for (final module in values) {
      if (module.id == id) return module;
    }
    // Module retiré d'une version ultérieure : on l'ignore plutôt que de faire
    // échouer tout le chargement du layout.
    return null;
  }
}

/// Disposition du Dashboard : ordre des modules et modules masqués.
@immutable
class DashboardLayout {
  const DashboardLayout({required this.order, required this.hidden});

  /// Les trois blocs affichés par défaut (refonte « zen ») : la prochaine
  /// action, les révisions dues, les habitudes du jour. Les autres restent
  /// disponibles dans « Personnaliser », masqués.
  static const List<DashboardModule> essentials = [
    DashboardModule.quickStart,
    DashboardModule.reviews,
    DashboardModule.tasks,
  ];

  /// Disposition par défaut : les [essentials] d'abord, le reste masqué.
  static const DashboardLayout initial = DashboardLayout(
    order: [
      ...essentials,
      DashboardModule.stats,
      DashboardModule.weeklyFocus,
      DashboardModule.habits,
      DashboardModule.notes,
      DashboardModule.metacognition,
      DashboardModule.planning,
    ],
    hidden: {
      DashboardModule.stats,
      DashboardModule.weeklyFocus,
      DashboardModule.habits,
      DashboardModule.notes,
      DashboardModule.metacognition,
      DashboardModule.planning,
    },
  );

  final List<DashboardModule> order;
  final Set<DashboardModule> hidden;

  List<DashboardModule> get visibleModules =>
      order.where((m) => !hidden.contains(m) && !m.isRetired).toList();

  bool isVisible(DashboardModule module) => !hidden.contains(module);

  /// Déplace le module visible de [oldIndex] vers [newIndex].
  ///
  /// [newIndex] est l'index **final** attendu, après retrait de l'élément :
  /// c'est exactement ce que fournit `ReorderableListView.onReorderItem`.
  DashboardLayout reorder(int oldIndex, int newIndex) {
    final visible = visibleModules;
    if (oldIndex < 0 || oldIndex >= visible.length) return this;

    final moved = List<DashboardModule>.from(visible);
    moved.insert(newIndex.clamp(0, moved.length - 1), moved.removeAt(oldIndex));

    // Les modules masqués conservent leur place relative en fin de liste, pour
    // réapparaître au bon endroit une fois réactivés.
    return DashboardLayout(
      // Les modules retirés de l'interface restent aussi dans `order` : la
      // disposition enregistrée ne doit rien perdre.
      order: [
        ...moved,
        ...order.where((m) => hidden.contains(m) || m.isRetired),
      ],
      hidden: hidden,
    );
  }

  DashboardLayout toggle(DashboardModule module) {
    final next = Set<DashboardModule>.from(hidden);
    if (!next.remove(module)) next.add(module);
    return DashboardLayout(order: order, hidden: next);
  }

  Map<String, dynamic> toJson() => {
        'order': order.map((m) => m.id).toList(),
        'hidden': hidden.map((m) => m.id).toList(),
      };

  /// Tolérant par construction : un layout enregistré par une version
  /// antérieure reste valide, et tout module ajouté depuis est ajouté à la fin
  /// plutôt que de disparaître.
  factory DashboardLayout.fromJson(Map<String, dynamic> json) {
    final storedOrder = (json['order'] as List?)
            ?.whereType<String>()
            .map(DashboardModule.fromId)
            .nonNulls
            .toList() ??
        const <DashboardModule>[];

    final hidden = (json['hidden'] as List?)
            ?.whereType<String>()
            .map(DashboardModule.fromId)
            .nonNulls
            .toSet() ??
        <DashboardModule>{};

    final missing =
        DashboardModule.values.where((m) => !storedOrder.contains(m));

    return DashboardLayout(
      order: [...storedOrder, ...missing],
      hidden: hidden,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardLayout &&
      other.hidden.length == hidden.length &&
      other.hidden.containsAll(hidden) &&
      _sameOrder(other.order, order);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(order),
        Object.hashAllUnordered(hidden),
      );

  static bool _sameOrder(List<DashboardModule> a, List<DashboardModule> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
