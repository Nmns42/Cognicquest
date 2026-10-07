import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../router/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.redirectTo});

  /// Destination demandée avant la redirection vers `/login`, si l'utilisateur
  /// a atterri ici depuis une route protégée.
  final String? redirectTo;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    // Le routeur redirige déjà via `refreshListenable` dès que la session
    // arrive ; on ne navigue explicitement que pour honorer `redirectTo`.
    if (success && mounted && widget.redirectTo != null) {
      context.go(widget.redirectTo!);
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
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
    if ((value ?? '').isEmpty) return 'Entre ton mot de passe.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError ? authState.error.toString() : null;

    return AuthScaffold(
      title: AppConfig.appName,
      subtitle: 'Apprendre mieux, chaque jour.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enabled: !isLoading,
                validator: _validatePassword,
                onFieldSubmitted: (_) => isLoading ? null : _signIn(),
                onChanged: (_) =>
                    ref.read(authControllerProvider.notifier).clearError(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading
                ? null
                : () => context.push(AppRoute.forgotPassword),
            child: const Text('Mot de passe oublié ?'),
          ),
        ),
        const SizedBox(height: 8),
        if (error != null) AuthMessageBanner(message: error),
        AuthPrimaryButton(
          label: 'Se connecter',
          isLoading: isLoading,
          onPressed: _signIn,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : _signInWithGoogle,
          icon: const Icon(Icons.g_mobiledata, size: 26),
          label: const Text('Continuer avec Google'),
        ),
        const SizedBox(height: 16),
        AuthFooterLink(
          question: 'Pas encore de compte ?',
          actionLabel: 'Créer un compte',
          onPressed: () => context.go(AppRoute.register),
        ),
      ],
    );
  }
}
