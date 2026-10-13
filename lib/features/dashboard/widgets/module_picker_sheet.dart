import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/dashboard_layout_provider.dart';
import '../../../core/theme/tokens.dart';

/// Activation / désactivation des modules du Dashboard.
///
/// CdC : « Personnalisation du tableau de bord (activer/désactiver modules) ».
class ModulePickerSheet extends ConsumerWidget {
  const ModulePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ModulePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutProvider);
    final notifier = ref.read(dashboardLayoutProvider.notifier);

    // Fond et forme viennent du thème de la feuille : un fond peint ici
    // masquerait le retour visuel des interrupteurs.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        // Neuf modules et le bouton de rétablissement ne tiennent pas sur un
        // petit écran : la feuille défile, rien n'est coupé.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.cq.beigeDark,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Modules du tableau de bord',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Choisis ce que tu veux voir. Maintiens un module appuyé sur le '
                'tableau de bord pour le déplacer.',
                style: TextStyle(
                    fontSize: TypeScale.caption,
                    color: context.cq.textMuted,
                    height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final module in layout.order)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: layout.isVisible(module),
                  onChanged: (_) => notifier.toggle(module),
                  secondary: Icon(module.icon,
                      size: 20,
                      color: layout.isVisible(module)
                          ? context.cq.vert
                          : context.cq.textHint),
                  title: Text(module.label,
                      style: const TextStyle(fontSize: TypeScale.body)),
                  subtitle: Text(
                    module.description,
                    style: TextStyle(
                        fontSize: TypeScale.caption,
                        color: context.cq.textMuted),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  notifier.resetToDefault();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.settings_backup_restore, size: 18),
                label: const Text('Rétablir la disposition par défaut'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
