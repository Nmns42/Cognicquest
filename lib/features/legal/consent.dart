import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'legal_info.dart';

/// Chemins des textes légaux, ouverts connecté ou non.
abstract final class LegalRoute {
  static const String privacy = '/legal/privacy';
  static const String notice = '/legal/notice';

  static bool contains(String location) => location.startsWith('/legal/');
}

/// Mémoire du consentement, propre à l'appareil : hors de la base locale,
/// qui est effacée à chaque déconnexion.
class ConsentStore {
  const ConsentStore();

  static const String _versionKey = 'cq_consent_version';
  static const String _atKey = 'cq_consent_at';

  /// Version acceptée sur cet appareil, `0` si aucune.
  Future<int> acceptedVersion() async =>
      (await SharedPreferences.getInstance()).getInt(_versionKey) ?? 0;

  Future<void> accept(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_versionKey, version);
    await prefs.setString(_atKey, DateTime.now().toUtc().toIso8601String());
  }

  Future<void> withdraw() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_versionKey);
    await prefs.remove(_atKey);
  }
}

final consentStoreProvider = Provider<ConsentStore>((_) => const ConsentStore());

/// `true` : consentement à jour ; `false` : à demander. En chargement, rien
/// n'est affiché (pas de bandeau qui clignote au démarrage).
class ConsentNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      await ref.read(consentStoreProvider).acceptedVersion() >=
      LegalInfo.consentVersion;

  Future<void> accept() async {
    await ref.read(consentStoreProvider).accept(LegalInfo.consentVersion);
    state = const AsyncValue.data(true);
  }

  Future<void> withdraw() async {
    await ref.read(consentStoreProvider).withdraw();
    state = const AsyncValue.data(false);
  }
}

final consentProvider =
    AsyncNotifierProvider<ConsentNotifier, bool>(ConsentNotifier.new);

/// Bandeau de consentement à la première ouverture : il recouvre l'app tant
/// que l'accord n'est pas donné, sauf sur les pages légales elles-mêmes
/// (qu'il permet d'ouvrir).
class ConsentGate extends ConsumerStatefulWidget {
  const ConsentGate({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends ConsumerState<ConsentGate> {
  bool _onLegalPage = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRoute);
    _onRoute();
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  void _onRoute() {
    final location =
        widget.router.routerDelegate.currentConfiguration.uri.path;
    final onLegal = LegalRoute.contains(location);
    if (onLegal != _onLegalPage && mounted) {
      setState(() => _onLegalPage = onLegal);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Erreur de lecture (stockage indisponible) : on n'empêche pas
    // d'utiliser l'app, le bandeau reviendra au prochain lancement.
    final accepted = ref.watch(consentProvider).valueOrNull ?? true;
    if (accepted || _onLegalPage) return widget.child;

    return Stack(
      children: [
        // L'app reste visible mais inerte : ni appui, ni focus clavier, ni
        // lecteur d'écran, tant que le choix n'est pas fait.
        AbsorbPointer(
          child: ExcludeFocus(
            child: ExcludeSemantics(child: widget.child),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _ConsentCard(
                  onOpen: widget.router.go,
                  onAccept: () => ref.read(consentProvider.notifier).accept(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsentCard extends StatefulWidget {
  const _ConsentCard({required this.onOpen, required this.onAccept});

  final ValueChanged<String> onOpen;
  final VoidCallback onAccept;

  @override
  State<_ConsentCard> createState() => _ConsentCardState();
}

class _ConsentCardState extends State<_ConsentCard> {
  bool _wellbeing = false;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final text = Theme.of(context).textTheme;
    final body = TextStyle(
        fontSize: TypeScale.body,
        color: cq.textPrimary,
        height: TypeScale.bodyHeight);

    return Material(
      color: cq.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: cq.beigeDark),
      ),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: 'Tes données, tes choix',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tes données, tes choix', style: text.headlineSmall),
              const SizedBox(height: Space.sm),
              Text(
                '${LegalInfo.appName} enregistre tes fiches, révisions, '
                'habitudes et ton journal sur cet appareil et, une fois '
                'connecté, sur ses serveurs, uniquement pour faire '
                'fonctionner l’app. Aucune publicité, aucun traceur, aucune '
                'revente.',
                style: body,
              ),
              const SizedBox(height: Space.md),
              CheckboxListTile(
                value: _wellbeing,
                onChanged: (value) =>
                    setState(() => _wellbeing = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'J’accepte que mon humeur, ma fatigue et mon journal soient '
                  'analysés pour me proposer des conseils.',
                  style: body,
                ),
                subtitle: Text(
                  'Données de bien-être : consentement explicite, retirable '
                  'à tout moment dans les Réglages.',
                  style: TextStyle(
                      fontSize: TypeScale.caption, color: cq.textMuted),
                ),
              ),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                children: [
                  TextButton(
                    onPressed: () => widget.onOpen(LegalRoute.privacy),
                    child: const Text('Politique de confidentialité'),
                  ),
                  TextButton(
                    onPressed: () => widget.onOpen(LegalRoute.notice),
                    child: const Text('Mentions légales'),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              FilledButton(
                onPressed: _wellbeing ? widget.onAccept : null,
                child: const Text('Accepter et continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
