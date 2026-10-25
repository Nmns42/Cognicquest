import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../auth/providers/auth_provider.dart';
import '../metacognition/data/metacognition_repository.dart';
import 'consent_sync.dart';
import 'legal_info.dart';

/// Chemins des textes légaux, ouverts connecté ou non.
abstract final class LegalRoute {
  static const String privacy = '/legal/privacy';
  static const String notice = '/legal/notice';

  static bool contains(String location) => location.startsWith('/legal/');
}

/// Choix enregistré sur l'appareil.
class ConsentChoice {
  const ConsentChoice({required this.version, required this.wellbeing});

  /// Aucun choix encore fait.
  static const ConsentChoice none = ConsentChoice(version: 0, wellbeing: false);

  /// Version des textes acceptée, `0` si aucune.
  final int version;

  /// Consentement explicite au traitement des données de bien-être
  /// (humeur, fatigue, journal, recadrages) : facultatif.
  final bool wellbeing;

  /// `false` : le bandeau doit être (re)présenté.
  bool get isCurrent => version >= LegalInfo.consentVersion;
}

/// Une décision, en attente d'envoi au serveur comme preuve (art. 7.1).
class ConsentRecord {
  const ConsentRecord({
    required this.version,
    required this.wellbeing,
    required this.decidedAt,
    this.userId,
  });

  factory ConsentRecord.fromJson(Map<String, dynamic> json) => ConsentRecord(
        version: json['version'] as int,
        wellbeing: json['wellbeing'] as bool,
        decidedAt: DateTime.parse(json['decided_at'] as String),
        userId: json['user_id'] as String?,
      );

  final int version;
  final bool wellbeing;
  final DateTime decidedAt;

  /// Compte connecté au moment du choix ; `null` au bandeau d'avant
  /// connexion : la preuve ira au premier compte qui se connecte.
  final String? userId;

  Map<String, dynamic> toJson() => {
        'version': version,
        'wellbeing': wellbeing,
        'decided_at': decidedAt.toUtc().toIso8601String(),
        'user_id': userId,
      };

  String get key => jsonEncode(toJson());
}

/// Mémoire du consentement, propre à l'appareil : hors de la base locale,
/// qui est effacée à chaque déconnexion.
class ConsentStore {
  const ConsentStore();

  static const String _versionKey = 'cq_consent_version';
  static const String _atKey = 'cq_consent_at';
  static const String _wellbeingKey = 'cq_consent_wellbeing';
  static const String _pendingKey = 'cq_consent_pending';
  static const String _purgeKey = 'cq_wellbeing_purge_user';

  Future<ConsentChoice> read() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_versionKey) ?? 0;
    return ConsentChoice(
      version: version,
      // Avant le choix séparé, accepter valait accord au bien-être.
      wellbeing: prefs.getBool(_wellbeingKey) ?? version > 0,
    );
  }

  Future<void> save(ConsentChoice choice, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_versionKey, choice.version);
    await prefs.setBool(_wellbeingKey, choice.wellbeing);
    await prefs.setString(_atKey, at.toUtc().toIso8601String());
  }

  Future<List<ConsentRecord>> pending() async {
    final raw = (await SharedPreferences.getInstance()).getString(_pendingKey);
    if (raw == null) return const [];
    return [
      for (final item in jsonDecode(raw) as List)
        ConsentRecord.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> addPending(ConsentRecord record) async =>
      _writePending([...await pending(), record]);

  /// Retire de la file les décisions envoyées (relue : un choix fait pendant
  /// l'envoi reste en attente).
  Future<void> removePending(Iterable<ConsentRecord> sent) async {
    final keys = {for (final r in sent) r.key};
    await _writePending(
        [for (final r in await pending()) if (!keys.contains(r.key)) r]);
  }

  Future<void> _writePending(List<ConsentRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    if (records.isEmpty) {
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(
          _pendingKey, jsonEncode([for (final r in records) r.toJson()]));
    }
  }

  /// Compte dont les données de bien-être restent à effacer du serveur
  /// (retrait fait hors ligne). Lié au compte : un autre compte connecté
  /// ensuite sur l'appareil n'est jamais purgé.
  Future<String?> purgeUser() async =>
      (await SharedPreferences.getInstance()).getString(_purgeKey);

  Future<void> setPurgeUser(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(_purgeKey);
    } else {
      await prefs.setString(_purgeKey, userId);
    }
  }
}

final consentStoreProvider = Provider<ConsentStore>((_) => const ConsentStore());

/// Choix de l'appareil. En chargement, rien n'est affiché (pas de bandeau
/// qui clignote au démarrage).
class ConsentNotifier extends AsyncNotifier<ConsentChoice> {
  @override
  Future<ConsentChoice> build() => ref.read(consentStoreProvider).read();

  /// Choix du bandeau de première ouverture.
  Future<void> accept({required bool wellbeing}) => _decide(wellbeing);

  /// Activation ou retrait du consentement bien-être (Réglages). Le retrait
  /// efface aussitôt le journal, les recadrages et les chaînes des 5
  /// pourquoi de l'appareil, puis du serveur (dès que possible).
  Future<void> setWellbeing(bool enabled) async {
    if (state.valueOrNull?.wellbeing == enabled) return;
    if (!enabled) {
      await ref.read(metacognitionRepositoryProvider)?.purgeLocalWellbeing();
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        await ref.read(consentStoreProvider).setPurgeUser(userId);
      }
    }
    await _decide(enabled);
  }

  Future<void> _decide(bool wellbeing) async {
    final store = ref.read(consentStoreProvider);
    final now = DateTime.now();
    final choice = ConsentChoice(
        version: LegalInfo.consentVersion, wellbeing: wellbeing);
    await store.save(choice, now);
    await store.addPending(ConsentRecord(
      version: choice.version,
      wellbeing: wellbeing,
      decidedAt: now,
      userId: ref.read(currentUserProvider)?.id,
    ));
    state = AsyncValue.data(choice);
    // Preuve et purge serveur tout de suite si possible ; sinon à la
    // prochaine synchronisation.
    unawaited(ref.read(consentSyncProvider)?.sync().catchError((_) {}));
  }
}

final consentProvider =
    AsyncNotifierProvider<ConsentNotifier, ConsentChoice>(ConsentNotifier.new);

/// `true` seulement avec un accord explicite et à jour : le journal, le
/// recadrage et les conseils tirés de l'humeur en dépendent.
final wellbeingConsentProvider = Provider<bool>((ref) {
  final choice = ref.watch(consentProvider).valueOrNull;
  return choice != null && choice.isCurrent && choice.wellbeing;
});

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
    final decided = ref.watch(consentProvider).valueOrNull?.isCurrent ?? true;
    if (decided || _onLegalPage) return widget.child;

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
                  onContinue: (wellbeing) => ref
                      .read(consentProvider.notifier)
                      .accept(wellbeing: wellbeing),
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
  const _ConsentCard({required this.onOpen, required this.onContinue});

  final ValueChanged<String> onOpen;

  /// Choix validé ; le bien-être est facultatif (art. 7.4 RGPD : l'accès à
  /// l'app ne dépend pas de ce consentement).
  final ValueChanged<bool> onContinue;

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
                  'Facultatif. Sans cet accord, le journal et le recadrage '
                  'restent désactivés ; tout le reste fonctionne. Modifiable '
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
                onPressed: () => widget.onContinue(_wellbeing),
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
