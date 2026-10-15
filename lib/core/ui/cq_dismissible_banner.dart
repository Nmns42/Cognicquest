import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';
import '../motion/reduce_motion.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Encadré d'aide d'un outil, fermable d'une croix.
///
/// Une fois fermé, il ne revient plus : l'état est mémorisé par [bannerId]
/// dans les préférences synchronisées (`UserSettings.dismissedBanners`).
/// « Rétablir les réglages par défaut » les fait réapparaître.
///
/// Sobre par construction : aplat en retrait, contour d'un pixel, une icône
/// discrète, pas de couleur vive. L'aide se lit, elle ne crie pas.
class CqDismissibleBanner extends ConsumerWidget {
  const CqDismissibleBanner({
    super.key,
    required this.bannerId,
    required this.message,
    this.title,
    this.icon = Icons.info_outline,
  });

  /// Identifiant stable, unique dans l'app (ex. `pomodoro.aide`).
  final String bannerId;

  final String? title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(
        settingsProvider.select((s) => s.dismissedBanners.contains(bannerId)));
    final cq = context.cq;
    final text = Theme.of(context).textTheme;

    // Fondu à la fermeture ; la place se libère à la fin du fondu.
    return AnimatedSwitcher(
      duration: Motion.duration(context, CqMotion.base),
      switchInCurve: CqMotion.enter,
      switchOutCurve: CqMotion.exit,
      child: dismissed
          ? const SizedBox.shrink()
          : Semantics(
              key: ValueKey(bannerId),
              container: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                    Space.lg, Space.md, Space.xs, Space.md),
                decoration: BoxDecoration(
                  color: cq.beige,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: cq.beigeDark, width: Borders.thin),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: Sizes.iconMd, color: cq.textMuted),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null) ...[
                            Text(title!, style: text.titleSmall),
                            const SizedBox(height: Space.xs),
                          ],
                          Text(message,
                              style: text.bodyMedium
                                  ?.copyWith(color: cq.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Fermer l'aide",
                      onPressed: () => ref
                          .read(settingsProvider.notifier)
                          .dismissBanner(bannerId),
                      icon: Icon(Icons.close,
                          size: Sizes.iconMd, color: cq.textMuted),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
