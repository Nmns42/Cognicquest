import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

/// Choix du nouveau mot de passe, ouvert par le lien de [ForgotPasswordPage].
///
/// Le routeur y force l'utilisateur tant que [passwordRecoveryProvider] est
/// vrai ; une fois le mot de passe enregistré, il le renvoie seul à l'accueil.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .updatePassword(_passwordController.text);
    // En cas de succès, le routeur quitte cette page de lui-même.
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Choisis un nouveau mot de passe.';
    if (password.length < AppConfig.minPasswordLength) {
      return '${AppConfig.minPasswordLength} caractères minimum.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError ? authState.error.toString() : null;

    return AuthScaffold(
      title: 'Nouveau mot de passe',
      subtitle: 'Choisis le mot de passe que tu utiliseras désormais.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  helperText:
                      '${AppConfig.minPasswordLength} caractères minimum',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    tooltip: _obscurePassword
                        ? 'Afficher le mot de passe'
                        : 'Masquer le mot de passe',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !isLoading,
                validator: _validatePassword,
                onChanged: (_) =>
                    ref.read(authControllerProvider.notifier).clearError(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirme le mot de passe',
                  prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
                validator: _validateConfirm,
                onFieldSubmitted: (_) => isLoading ? null : _save(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (error != null) AuthMessageBanner(message: error),
        AuthPrimaryButton(
          label: 'Enregistrer',
          isLoading: isLoading,
          onPressed: _save,
        ),
        const SizedBox(height: 16),
        Center(
          // Abandonner ferme la session ouverte par le lien : l'utilisateur
          // n'entre pas dans l'app sans avoir changé son mot de passe.
          child: TextButton(
            onPressed: isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Annuler'),
          ),
        ),
      ],
    );
  }
}
