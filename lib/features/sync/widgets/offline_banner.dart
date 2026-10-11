import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/sync_coordinator.dart';

/// Bandeau affiché seulement quand l'app travaille hors ligne.
///
/// Discret à dessein — CdC : « design minimaliste, notifications limitées ».
/// Il rassure sur le fait que rien n'est perdu, sans interrompre le travail.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncCoordinatorProvider);
    final visible = status.isOffline;

    final pending = status.pendingCount;
    final message = pending == 0
        ? 'Hors ligne — tout est enregistré sur cet appareil.'
        : 'Hors ligne — $pending modification${pending > 1 ? 's' : ''} '
            'en attente, envoyée${pending > 1 ? 's' : ''} au retour du réseau.';

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Material(
              color: context.cq.beigeDark,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: 16, color: context.cq.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.cq.textMuted,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: status.isSyncing
                            ? null
                            : () => ref
                                .read(syncCoordinatorProvider.notifier)
                                .syncNow(),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: context.cq.vertDark,
                        ),
                        child: Text(status.isSyncing ? 'Envoi…' : 'Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
