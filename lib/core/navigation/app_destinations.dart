import 'package:flutter/material.dart';

/// Une destination de navigation.
class AppDestination {
  const AppDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.isPrimary = true,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// `true` pour les destinations qui tiennent dans la barre du bas sur
  /// mobile. Les autres restent accessibles par le tiroir et par le rail.
  final bool isPrimary;
}

/// Catalogue unique des destinations de l'application.
///
/// Auparavant, la liste était dupliquée dans `_MainShell` et trois sections
/// (graphe, journal, planification) n'y figuraient pas du tout : elles
/// empruntaient l'onglet d'une autre section, ce qui rendait la barre du bas
/// menteuse. Tout est désormais déclaré ici, une seule fois.
abstract final class AppDestinations {
  static const List<AppDestination> all = [
    AppDestination(
      route: '/home',
      label: 'Accueil',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AppDestination(
      route: '/pomodoro',
      label: 'Pomodoro',
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
    ),
    AppDestination(
      route: '/kanban',
      label: 'Tâches',
      icon: Icons.view_kanban_outlined,
      selectedIcon: Icons.view_kanban,
    ),
    AppDestination(
      route: '/notes',
      label: 'Fiches',
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories,
    ),
    AppDestination(
      route: '/review',
      label: 'Réviser',
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
    ),
    // ── Secondaires : hors barre du bas, présentes partout ailleurs ────────
    AppDestination(
      route: '/habits',
      label: 'Habitudes',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
      isPrimary: false,
    ),
    AppDestination(
      route: '/graph',
      label: 'Graphe',
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub,
      isPrimary: false,
    ),
    AppDestination(
      route: '/planning',
      label: 'Planification',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      isPrimary: false,
    ),
    AppDestination(
      route: '/journal',
      label: 'Journal',
      icon: Icons.self_improvement_outlined,
      selectedIcon: Icons.self_improvement,
      isPrimary: false,
    ),
    AppDestination(
      route: '/settings',
      label: 'Réglages',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      isPrimary: false,
    ),
  ];

  /// Destinations affichées dans la barre du bas sur mobile.
  static List<AppDestination> get primary =>
      all.where((d) => d.isPrimary).toList();

  static List<AppDestination> get secondary =>
      all.where((d) => !d.isPrimary).toList();

  /// Destination correspondant à l'emplacement courant.
  ///
  /// On retient la route **la plus longue** qui préfixe l'emplacement :
  /// sinon `/journal` serait capté par `/j…` et, surtout, `/planning/gantt`
  /// doit désigner « Planification » et non la première route qui matche.
  static AppDestination? matching(String location) {
    AppDestination? best;
    for (final destination in all) {
      if (!location.startsWith(destination.route)) continue;
      if (best == null || destination.route.length > best.route.length) {
        best = destination;
      }
    }
    return best;
  }

  /// Index dans [primary], ou `null` si l'emplacement relève d'une section
  /// secondaire — la barre du bas n'affiche alors aucune sélection plutôt
  /// que d'en inventer une.
  static int? primaryIndexOf(String location) {
    final destination = matching(location);
    if (destination == null || !destination.isPrimary) return null;
    return primary.indexWhere((d) => d.route == destination.route);
  }

  static int? indexOf(String location) {
    final destination = matching(location);
    if (destination == null) return null;
    return all.indexWhere((d) => d.route == destination.route);
  }
}

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
