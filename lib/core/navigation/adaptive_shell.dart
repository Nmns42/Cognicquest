import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'app_destinations.dart';

/// Coquille de navigation adaptative.
///
/// - Téléphone : barre du bas (5 destinations) + tiroir pour le reste.
/// - Tablette : rail d'icônes, toutes destinations visibles.
/// - Grand écran : rail étendu avec libellés.
///
/// Règle ce que le CdC appelle « navigation simple, évolutive et cohérente » :
/// aucune section n'emprunte plus l'onglet d'une autre, et les dix
/// destinations sont atteignables quelle que soit la largeur.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  final Widget child;
  final String currentLocation;

  void _go(BuildContext context, String route) {
    if (currentLocation.startsWith(route)) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final layout = Breakpoints.layoutFor(MediaQuery.sizeOf(context).width);

    return switch (layout) {
      NavigationLayout.bottomBar => _BottomBarShell(
          currentLocation: currentLocation,
          onSelect: (route) => _go(context, route),
          child: child,
        ),
      NavigationLayout.rail ||
      NavigationLayout.extendedRail =>
        _RailShell(
          currentLocation: currentLocation,
          extended: layout == NavigationLayout.extendedRail,
          onSelect: (route) => _go(context, route),
          child: child,
        ),
    };
  }
}

class _BottomBarShell extends StatelessWidget {
  const _BottomBarShell({
    required this.child,
    required this.currentLocation,
    required this.onSelect,
  });

  final Widget child;
  final String currentLocation;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final primary = AppDestinations.primary;
    final selected = AppDestinations.primaryIndexOf(currentLocation);

    return Scaffold(
      drawer: _NavigationDrawer(
        currentLocation: currentLocation,
        onSelect: onSelect,
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        // `selectedIndex` ne peut pas être nul : quand on est dans une section
        // secondaire, on met l'accueil en surbrillance mais l'utilisateur voit
        // par le titre de l'écran où il se trouve. Le tiroir, lui, marque la
        // bonne entrée.
        selectedIndex: selected ?? 0,
        onDestinationSelected: (index) => onSelect(primary[index].route),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final destination in primary)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({
    required this.child,
    required this.currentLocation,
    required this.extended,
    required this.onSelect,
  });

  final Widget child;
  final String currentLocation;
  final bool extended;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const all = AppDestinations.all;
    final selected = AppDestinations.indexOf(currentLocation);

    return Scaffold(
      body: Row(
        children: [
          SingleChildScrollView(
            // Dix destinations ne tiennent pas verticalement sur une tablette
            // en paysage : le rail défile plutôt que de rogner les dernières.
            child: IntrinsicHeight(
              child: NavigationRail(
                extended: extended,
                minWidth: 72,
                minExtendedWidth: 208,
                groupAlignment: -0.9,
                selectedIndex: selected,
                onDestinationSelected: (index) => onSelect(all[index].route),
                leading: _RailHeader(extended: extended),
                destinations: [
                  for (final destination in all)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: Text(destination.label),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                    ),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: context.cq.beigeDark),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.cq.vert,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.psychology_outlined,
                size: 19, color: context.onAccent),
          ),
          if (extended) ...[
            const SizedBox(width: 10),
            Text(
              'CognicQuest',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.cq.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tiroir latéral : sur téléphone, c'est lui qui donne accès aux sections
/// absentes de la barre du bas.
class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.currentLocation,
    required this.onSelect,
  });

  final String currentLocation;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final current = AppDestinations.matching(currentLocation);

    return Drawer(
      backgroundColor: context.cq.beige,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.cq.vert,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.psychology_outlined,
                        size: 20, color: context.onAccent),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    'CognicQuest',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.cq.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            for (final destination in AppDestinations.all)
              ListTile(
                leading: Icon(
                  current?.route == destination.route
                      ? destination.selectedIcon
                      : destination.icon,
                  size: 21,
                  color: current?.route == destination.route
                      ? context.cq.vertDark
                      : context.cq.textMuted,
                ),
                title: Text(
                  destination.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: current?.route == destination.route
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: current?.route == destination.route
                        ? context.cq.vertDark
                        : context.cq.textPrimary,
                  ),
                ),
                selected: current?.route == destination.route,
                selectedTileColor: context.cq.vert.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(destination.route);
                },
              ),
          ],
        ),
      ),
    );
  }
}
