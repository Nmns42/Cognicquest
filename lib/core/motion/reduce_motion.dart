import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';

/// Réglage système « réduire les animations ».
///
/// Deux drapeaux, selon la plateforme :
/// - `disableAnimations` : Android (« Supprimer les animations ») et web
///   (`prefers-reduced-motion`) ;
/// - `reduceMotion` : iOS (« Réduire les animations »), où
///   `disableAnimations` n'est pas renseigné.
///
/// Suivi en direct : un changement dans les réglages du téléphone s'applique
/// sans redémarrer l'app.
class SystemReduceMotion extends Notifier<bool> with WidgetsBindingObserver {
  @override
  bool build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    return _read();
  }

  bool _read() {
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return features.disableAnimations || features.reduceMotion;
  }

  @override
  void didChangeAccessibilityFeatures() => state = _read();
}

final systemReduceMotionProvider =
    NotifierProvider<SystemReduceMotion, bool>(SystemReduceMotion.new);

/// Animations réduites effectives : réglage de l'app **ou** réglage système.
///
/// Seul point de décision. `CognicQuestApp` l'applique à la racine (thème,
/// transitions) et le réinjecte dans `MediaQuery.disableAnimations`, que les
/// widgets lisent via [Motion].
final effectiveReduceMotionProvider = Provider<bool>(
  (ref) =>
      ref.watch(reduceMotionProvider) || ref.watch(systemReduceMotionProvider),
);

/// Durées et styles d'animation, selon le réglage effectif.
///
/// Règle (CdC : interface douce, anti burn-out) :
/// - mouvement décoratif (glissement, zoom, rebond) : supprimé ;
/// - animation qui porte une information (sélection, progression, retour
///   d'action) : changement instantané ;
/// - indicateurs de chargement : conservés.
///
/// Réglage désactivé : chaque méthode rend exactement la valeur d'origine.
abstract final class Motion {
  /// `true` si les animations doivent être réduites sous [context].
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [normal], ou zéro si les animations sont réduites.
  static Duration duration(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;

  /// Style d'animation des feuilles, dialogues, menus et messages : `null`
  /// (défaut Flutter) ou aucune animation.
  static AnimationStyle? style(BuildContext context) =>
      reduced(context) ? AnimationStyle.noAnimation : null;

  /// Thème sans transitions de page ni effet d'encre décoratif. Le surlignage
  /// d'un bouton pressé (retour d'action) reste, instantané.
  static ThemeData reducedTheme(ThemeData theme) => theme.copyWith(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const _InstantPageTransitionsBuilder(),
          },
        ),
        splashFactory: NoSplash.splashFactory,
      );
}

/// Transition de page instantanée : la nouvelle page apparaît d'emblée.
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
