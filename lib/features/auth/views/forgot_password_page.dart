import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

/// Réinitialisation du mot de passe par email.
///
/// Écran absent jusqu'ici : un utilisateur ayant perdu son mot de passe n'avait
/// aucun recours dans l'application.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);

    if (success && mounted) setState(() => _emailSent = true);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Entre ton adresse email.';
    if (!AppConfig.emailPattern.hasMatch(email)) {
      return 'Cette adresse email n\'est pas valide.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError ? authState.error.toString() : null;

    return AuthScaffold(
      title: 'Mot de passe oublié',
      subtitle: 'Indique ton email : nous t\'envoyons un lien pour choisir '
          'un nouveau mot de passe.',
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'ton.email@exemple.com',
              prefixIcon: Icon(Icons.mail_outline, size: 20),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enabled: !isLoading && !_emailSent,
            validator: _validateEmail,
            onFieldSubmitted: (_) => isLoading ? null : _sendReset(),
            onChanged: (_) =>
                ref.read(authControllerProvider.notifier).clearError(),
          ),
        ),
        const SizedBox(height: 20),
        if (error != null) AuthMessageBanner(message: error),
        if (_emailSent)
          const AuthMessageBanner(
            message: 'Email envoyé. Vérifie ta boîte de réception '
                '(et les indésirables).',
            isError: false,
          ),
        if (!_emailSent)
          AuthPrimaryButton(
            label: 'Envoyer le lien',
            isLoading: isLoading,
            onPressed: _sendReset,
          ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Retour à la connexion'),
          ),
        ),
      ],
    );
  }
}
