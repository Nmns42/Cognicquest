import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../router/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _successMessage = null);

    final outcome = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );

    if (!mounted || outcome == null) return;

    // L'ancien code faisait `context.go('/home')` systematiquement : quand la
    // confirmation d'email est activee dans Supabase, `signUp` ne renvoie
    // aucune session et l'utilisateur etait renvoye vers /login sans explication.
    if (outcome == SignUpOutcome.emailConfirmationRequired) {
      setState(() {
        _successMessage = 'Compte créé. Ouvre le lien de confirmation envoyé à '
            '${_emailController.text.trim()} pour activer ton accès.';
      });
    }
    // Si une session est ouverte, le routeur redirige seul vers /home.
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Entre ton prénom.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Entre ton adresse email.';
    if (!AppConfig.emailPattern.hasMatch(email)) {
      return 'Cette adresse email n\'est pas valide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Choisis un mot de passe.';
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
      title: 'Créer un compte',
      subtitle: 'Rejoins CognicQuest',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                enabled: !isLoading,
                validator: _validateName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'ton.email@exemple.com',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enabled: !isLoading,
                validator: _validateEmail,
                onChanged: (_) =>
                    ref.read(authControllerProvider.notifier).clearError(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
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
                onFieldSubmitted: (_) => isLoading ? null : _register(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (error != null) AuthMessageBanner(message: error),
        if (_successMessage != null)
          AuthMessageBanner(message: _successMessage!, isError: false),
        AuthPrimaryButton(
          label: 'Créer mon compte',
          isLoading: isLoading,
          onPressed: _register,
        ),
        const SizedBox(height: 16),
        AuthFooterLink(
          question: 'Déjà un compte ?',
          actionLabel: 'Se connecter',
          onPressed: () => context.go(AppRoute.login),
        ),
      ],
    );
  }
}
