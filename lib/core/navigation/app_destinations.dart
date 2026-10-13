import 'package:flutter/material.dart';

/// Une section de l'application : un écran racine et ses sous-pages.
class AppSection {
  const AppSection({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}

/// Les quatre espaces de la navigation (refonte « zen », Phase 1).
///
/// Dix destinations au même niveau, c'était dix décisions possibles à chaque
/// regard sur la barre. On les regroupe par intention : ce que je fais
/// aujourd'hui, ce que j'apprends, ce que j'organise, ce sur quoi je reviens.
/// La barre du bas tient ainsi en quatre entrées (UI UX Pro Max : « bottom
/// nav ≤ 5 »). Les réglages sont hors espaces, accessibles depuis l'accueil
/// et le rail.
enum AppSpace {
  today(
    label: "Aujourd'hui",
    icon: Icons.wb_sunny_outlined,
    selectedIcon: Icons.wb_sunny,
    sections: [
      AppSection(route: '/home', label: 'Accueil', icon: Icons.home_outlined),
      AppSection(
          route: '/pomodoro', label: 'Concentration', icon: Icons.timer_outlined),
      // Habitudes : retirées de l'interface pour l'instant (code et données
      // conservés, route toujours valide).
    ],
  ),
  learn(
    label: 'Apprendre',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
    sections: [
      AppSection(
          route: '/notes', label: 'Fiches', icon: Icons.auto_stories_outlined),
      AppSection(route: '/review', label: 'Réviser', icon: Icons.style_outlined),
      // Graphe de connaissances : retiré de la navigation (les liens entre
      // fiches restent, visibles dans les fiches elles-mêmes).
    ],
  ),
  organize(
    label: 'Organiser',
    icon: Icons.view_kanban_outlined,
    selectedIcon: Icons.view_kanban,
    sections: [
      AppSection(
          route: '/kanban', label: 'Tâches', icon: Icons.view_kanban_outlined),
      AppSection(
          route: '/planning', label: 'Planification', icon: Icons.event_outlined),
    ],
  ),
  reflect(
    label: 'Réfléchir',
    icon: Icons.self_improvement_outlined,
    selectedIcon: Icons.self_improvement,
    sections: [
      AppSection(
          route: '/journal',
          label: 'Journal',
          icon: Icons.self_improvement_outlined),
    ],
  );

  const AppSpace({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.sections,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final List<AppSection> sections;

  /// Écran d'arrivée de l'espace.
  String get route => sections.first.route;

  /// Section qui contient [location] : la route **la plus longue** qui la
  /// préfixe, pour que `/planning/gantt` désigne « Planification ».
  static AppSection? sectionOf(String location) {
    AppSection? best;
    for (final space in values) {
      for (final section in space.sections) {
        final matches = location == section.route ||
            location.startsWith('${section.route}/');
        if (!matches) continue;
        if (best == null || section.route.length > best.route.length) {
          best = section;
        }
      }
    }
    return best;
  }

  /// Espace qui contient [location], ou `null` (réglages, route inconnue).
  static AppSpace? of(String location) {
    final section = sectionOf(location);
    if (section == null) return null;
    return values.firstWhere((s) => s.sections.contains(section));
  }

  /// `true` sur l'écran racine d'une section : c'est là, et seulement là,
  /// que s'affichent les onglets de l'espace. Dans une sous-page (une fiche
  /// ouverte, une session de révision), rien ne doit distraire.
  static bool isSectionRoot(String location) =>
      sectionOf(location)?.route == location;
}

/// Réglages : hors des quatre espaces.
const String settingsRoute = '/settings';

/// Route du Pomodoro : seule à déclencher le mode concentration.
const String focusRoute = '/pomodoro';

/// Points de rupture de la mise en page.
///
/// Alignés sur les recommandations Material 3 : barre du bas sur téléphone,
/// rail sur tablette, rail étendu sur grand écran — ce qui est aussi la cible
/// web du cahier des charges.
abstract final class Breakpoints {
  static const double railMin = 640;
  static const double extendedRailMin = 1240;

  static NavigationLayout layoutFor(double width) {
    if (width >= extendedRailMin) return NavigationLayout.extendedRail;
    if (width >= railMin) return NavigationLayout.rail;
    return NavigationLayout.bottomBar;
  }
}

enum NavigationLayout { bottomBar, rail, extendedRail }
