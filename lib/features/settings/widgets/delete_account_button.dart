import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

/// Suppression définitive du compte (RGPD, exigée par les stores).
///
/// Confirmation forte : l'utilisateur doit taper [confirmationWord]. Une
/// fois le compte supprimé, la session disparaît et le routeur renvoie seul
/// vers `/login`.
class DeleteAccountButton extends ConsumerWidget {
  const DeleteAccountButton({super.key});

  static const String confirmationWord = 'SUPPRIMER';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(authControllerProvider).isLoading;
    final danger = context.cq.errorColor;

    return OutlinedButton.icon(
      onPressed: isBusy ? null : () => _confirmAndDelete(context, ref),
      style: OutlinedButton.styleFrom(
        foregroundColor: danger,
        side: BorderSide(color: danger.withValues(alpha: 0.6)),
      ),
      icon: const Icon(Icons.delete_forever_outlined, size: 18),
      label: const Text('Supprimer mon compte'),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: Motion.style(context),
      builder: (_) => const _ConfirmDeleteDialog(),
    );
    if (!(confirmed ?? false)) return;

    final deleted =
        await ref.read(authControllerProvider.notifier).deleteAccount();
    if (deleted || !context.mounted) return;

    final error = ref.read(authControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      snackBarAnimationStyle: Motion.style(context),
      SnackBar(
        content: Text(
          error is AuthFailure ? error.message : 'Suppression impossible.',
        ),
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog();

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isConfirmed =>
      _controller.text.trim() == DeleteAccountButton.confirmationWord;

  @override
  Widget build(BuildContext context) {
    final danger = context.cq.errorColor;

    return AlertDialog(
      scrollable: true,
      title: const Text('Supprimer ton compte ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ton compte et toutes tes données (fiches, tâches, habitudes, '
            'cartes, journal, planning…) seront effacés définitivement, sur '
            'le serveur et sur cet appareil. Cette action est irréversible.',
          ),
          const SizedBox(height: 14),
          const Text(
            'Tape ${DeleteAccountButton.confirmationWord} pour confirmer :',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: DeleteAccountButton.confirmationWord,
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _isConfirmed ? () => Navigator.pop(context, true) : null,
          child: Text(
            'Supprimer définitivement',
            style: TextStyle(color: _isConfirmed ? danger : null),
          ),
        ),
      ],
    );
  }
}
