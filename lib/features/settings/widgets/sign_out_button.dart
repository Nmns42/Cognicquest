import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/ui.dart';
import '../../auth/providers/auth_provider.dart';

/// Déconnexion, avec la mise en garde sur les modifications pas encore
/// envoyées (elles seraient perdues avec la purge de l'appareil).
///
/// Un seul endroit dans l'app : la section « Compte » des réglages.
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CqButton.secondary(
      label: 'Se déconnecter',
      icon: Icons.logout,
      onPressed: () => _confirmSignOut(context, ref),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    // La déconnexion efface les données de l'appareil : on envoie d'abord ce
    // qui peut l'être, puis on prévient de ce qui serait perdu.
    final remaining =
        ref.read(authControllerProvider.notifier).flushPendingWrites();
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: Motion.style(context),
      builder: (context) => FutureBuilder<int>(
        future: remaining,
        builder: (context, snapshot) {
          final isFlushing = snapshot.connectionState != ConnectionState.done;
          final pending = snapshot.data ?? 0;
          return AlertDialog(
            scrollable: true,
            title: const Text('Se déconnecter ?'),
            content: isFlushing
                ? const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Text('Synchronisation en cours…')),
                    ],
                  )
                : Text(
                    pending == 0
                        ? 'Tes données sont synchronisées sur ton compte. '
                            'Elles seront effacées de cet appareil.'
                        : '$pending modification${pending > 1 ? 's' : ''} '
                            'n\'${pending > 1 ? 'ont' : 'a'} pas pu être '
                            'envoyée${pending > 1 ? 's' : ''} (hors ligne ?). '
                            'Te déconnecter maintenant '
                            '${pending > 1 ? 'les' : 'la'} perdra '
                            'définitivement.',
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed:
                    isFlushing ? null : () => Navigator.pop(context, true),
                child: Text(
                  pending == 0 ? 'Se déconnecter' : 'Se déconnecter quand même',
                  style: TextStyle(
                    color: isFlushing ? null : context.cq.errorColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed ?? false) {
      // Le routeur redirige seul vers /login via refreshListenable.
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}
