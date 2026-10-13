import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../motion/reduce_motion.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_destinations.dart';

/// Coquille de navigation adaptative, organisée en quatre espaces.
///
/// - Téléphone : barre du bas à quatre entrées.
/// - Tablette : rail d'icônes ; grand écran : rail avec libellés. Les
///   réglages sont en bas du rail.
/// - Dans un espace à plusieurs sections, des onglets discrets en haut de
///   l'écran racine permettent de passer de l'une à l'autre.
/// - **Mode concentration** ([focusMode]) : pendant un Pomodoro, toute la
///   navigation disparaît. Mettre en pause la fait revenir.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.child,
    required this.currentLocation,
    this.focusMode = false,
  });

  final Widget child;
  final String currentLocation;
  final bool focusMode;

  /// Dernier écran visité dans chaque espace : revenir à un espace ramène là
  /// où on l'avait laissé, pas à sa racine.
  static final Map<AppSpace, String> _lastLocation = {};

  /// Oublie les écrans mémorisés (tests, changement de compte).
  @visibleForTesting
  static void resetMemory() => _lastLocation.clear();

  void _goToSpace(BuildContext context, AppSpace space) {
    final current = AppSpace.of(currentLocation);
    // Toucher l'espace où l'on est déjà ramène à sa racine.
    final target =
        current == space ? space.route : (_lastLocation[space] ?? space.route);
    if (target != currentLocation) context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final space = AppSpace.of(currentLocation);
    if (space != null) _lastLocation[space] = currentLocation;

    final layout = Breakpoints.layoutFor(MediaQuery.sizeOf(context).width);
    final content = _SectionTabsFrame(
      currentLocation: currentLocation,
      visible: !focusMode,
      child: child,
    );

    if (layout == NavigationLayout.bottomBar) {
      return Scaffold(
        body: content,
        bottomNavigationBar: _Collapsible(
          visible: !focusMode,
          axis: Axis.vertical,
          child: NavigationBar(
            // Hors des espaces (réglages), on reste sur « Aujourd'hui », d'où
            // l'on y accède.
            selectedIndex: (space ?? AppSpace.today).index,
            onDestinationSelected: (index) =>
                _goToSpace(context, AppSpace.values[index]),
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final s in AppSpace.values)
                NavigationDestination(
                  icon: Icon(s.icon),
                  selectedIcon: Icon(s.selectedIcon),
                  label: s.label,
                ),
            ],
          ),
        ),
      );
    }

    final extended = layout == NavigationLayout.extendedRail;
    return Scaffold(
      body: Row(
        children: [
          _Collapsible(
            visible: !focusMode,
            axis: Axis.horizontal,
            child: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  minWidth: 80,
                  minExtendedWidth: 208,
                  groupAlignment: -1,
                  selectedIndex: space?.index,
                  onDestinationSelected: (index) =>
                      _goToSpace(context, AppSpace.values[index]),
                  leading: _RailHeader(extended: extended),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Space.lg),
                        child: _SettingsButton(
                          selected: currentLocation.startsWith(settingsRoute),
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    for (final s in AppSpace.values)
                      NavigationRailDestination(
                        icon: Icon(s.icon),
                        selectedIcon: Icon(s.selectedIcon),
                        label: Text(s.label),
                        padding: const EdgeInsets.symmetric(vertical: Space.xs),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: context.cq.beigeDark),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

/// Fait disparaître la navigation en douceur (mode concentration).
///
/// Animations réduites : bascule instantanée. `AnimatedSize` n'accepte pas
/// une durée nulle sans erreur de layout, il est donc simplement retiré.
class _Collapsible extends StatelessWidget {
  const _Collapsible({
    required this.visible,
    required this.axis,
    required this.child,
  });

  final bool visible;
  final Axis axis;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shown = visible
        ? child
        : SizedBox(
            width: axis == Axis.horizontal ? 0 : null,
            height: axis == Axis.vertical ? 0 : null,
          );
    if (Motion.reduced(context)) return shown;
    return ClipRect(
      child: AnimatedSize(
        duration: CqMotion.base,
        curve: CqMotion.standard,
        alignment:
            axis == Axis.vertical ? Alignment.topCenter : Alignment.centerRight,
        child: shown,
      ),
    );
  }
}

/// Onglets des sections de l'espace courant, au-dessus de l'écran racine.
///
/// Absents dans un espace à section unique (Réfléchir), dans une sous-page et
/// en mode concentration.
class _SectionTabsFrame extends StatelessWidget {
  const _SectionTabsFrame({
    required this.currentLocation,
    required this.visible,
    required this.child,
  });

  final String currentLocation;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final space = AppSpace.of(currentLocation);
    final show = visible &&
        space != null &&
        space.sections.length > 1 &&
        AppSpace.isSectionRoot(currentLocation);
    if (!show) return child;

    final current = AppSpace.sectionOf(currentLocation);
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final section in space.sections)
                      Padding(
                        padding: const EdgeInsets.only(right: Space.sm),
                        child: _SectionTab(
                          section: section,
                          selected: section == current,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // La marge haute est déjà prise par les onglets : l'en-tête de
        // l'écran ne doit pas la reprendre une seconde fois.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({required this.section, required this.selected});

  final AppSection section;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.cq.textPrimary : context.cq.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? context.cq.vert.withValues(alpha: Tints.selected)
            : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: selected ? null : () => context.go(section.route),
          child: ConstrainedBox(
            // Cible tactile de 48 dp, même si la pastille paraît plus fine.
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Center(
                widthFactor: 1,
                child: Text(
                  section.label,
                  style: TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Réglages',
      isSelected: selected,
      icon: Icon(Icons.settings_outlined, color: context.cq.textMuted),
      selectedIcon: Icon(Icons.settings, color: context.cq.vertDark),
      onPressed: selected ? null : () => context.go(settingsRoute),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Space.lg, horizontal: Space.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Space.xxl,
            height: Space.xxl,
            decoration: BoxDecoration(
              color: context.cq.vert,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(Icons.psychology_outlined,
                size: 20, color: context.onAccent),
          ),
          if (extended) ...[
            const SizedBox(width: Space.md),
            Text(
              'CognicQuest',
              style: TextStyle(
                fontSize: TypeScale.bodyLarge,
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
