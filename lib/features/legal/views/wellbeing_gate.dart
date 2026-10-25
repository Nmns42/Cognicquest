import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/cq_button.dart';
import '../consent.dart';

/// Écrans du module bien-être (journal, recadrage) : ouverts seulement avec
/// le consentement explicite. Sinon, explication et activation en un appui ;
/// l'accès au reste de l'app n'en dépend pas.
class WellbeingGate extends ConsumerWidget {
  const WellbeingGate({super.key, required this.title, required this.child});

  /// Titre de l'écran protégé, gardé dans la barre.
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(wellbeingConsentProvider)) return child;

    final cq = context.cq;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.spa_outlined, size: Sizes.iconLg, color: cq.vertSauge),
                const SizedBox(height: Space.md),
                Text('Module bien-être désactivé',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Space.sm),
                Text(
                  'Le journal et le recadrage enregistrent ton humeur, ta '
                  'fatigue et tes pensées. Ils ne fonctionnent qu’avec ton '
                  'accord explicite, retirable à tout moment dans '
                  'Réglages > Confidentialité.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: TypeScale.body,
                      color: cq.textMuted,
                      height: TypeScale.bodyHeight),
                ),
                const SizedBox(height: Space.lg),
                CqButton.primary(
                  label: 'Activer l’analyse de mon bien-être',
                  onPressed: () =>
                      ref.read(consentProvider.notifier).setWellbeing(true),
                ),
                const SizedBox(height: Space.sm),
                TextButton(
                  onPressed: () => context.push(LegalRoute.privacy),
                  child: const Text('Politique de confidentialité'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
