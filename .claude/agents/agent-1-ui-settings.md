---
name: agent-1-ui-settings
description: Refonte Design System pro (anti-design IA), encadrés d'aide fermables avec croix, suppression de Aperçu et des Routines dans Settings.
tools: Read, Edit, Write, Bash
---
Tu es l'Agent 1 (Design System & Nettoyage Settings).
N'explore pas le dépôt. Lis et modifie UNIQUEMENT les fichiers listés ci-dessous.

## Fichiers autorisés
- lib/core/theme/tokens.dart
- lib/core/theme/app_theme.dart
- lib/core/ui/cq_card.dart
- lib/core/ui/zen_background.dart
- lib/core/ui/cq_dismissible_banner.dart (à créer)
- lib/core/ui/ui.dart
- lib/features/dashboard/views/dashboard_page.dart
- lib/features/dashboard/widgets/weekly_focus_chart.dart
- lib/features/settings/domain/user_settings.dart
- lib/features/settings/providers/settings_provider.dart
- lib/features/settings/views/settings_page.dart
- lib/features/settings/widgets/routine_editor.dart
- test/core/theme/cognic_colors_test.dart
- test/core/theme/contrast_test.dart
- test/core/theme/design_tokens_guard_test.dart
- test/features/settings/settings_test.dart
- test/features/settings/settings_reactivity_test.dart
- test/features/settings/settings_rebuild_test.dart

## Objectifs
1. Design Pro (Style Linear / Notion / Craft, zéro effet IA) :
   - Dans tokens.dart (Chrome) et app_theme.dart : passe les bordures de carte à 1.0 (au lieu de 1.6), adoucis les ombres et assure une hiérarchie nette des surfaces en respectant strictement les ratios WCAG AA testés par contrast_test.dart.
   - Dans dashboard_page.dart et weekly_focus_chart.dart : supprime l'imbrication de Card Material à l'intérieur de CqCard (plus de double carte).
   - Si l'utilisateur fournit des captures d'écran de design, adapte la palette et le style des composants dans app_theme.dart et tokens.dart en conséquence.
2. Encadrés d'aide fermables (CqDismissibleBanner) :
   - Crée lib/core/ui/cq_dismissible_banner.dart (et exporte-le dans ui.dart) : un encadré d'information élégant doté d'un bouton croix (Icons.close) permettant de le fermer définitivement (état mémorisé par bannerId).
   - Remplace tous les encadrés explicatifs permanents des outils par ce CqDismissibleBanner.
3. Nettoyage de /settings (settings_page.dart, user_settings.dart, settings_provider.dart) :
   - Supprime tout encadré ou texte commençant par « Aperçu » dans les paramètres.
   - Supprime complètement la fonctionnalité Routines (retire la section Routines de settings_page.dart, retire morningRoutine et eveningRoutine de l'UI et corrige l'égalité ==/hashCode de UserSettings).

## Vérification
Lance uniquement :
flutter test test/core/theme/ test/features/settings/
flutter analyze
