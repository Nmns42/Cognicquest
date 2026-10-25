import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Rapports de plantage (Sentry), pour corriger les bugs vus en production.
///
/// Base légale : intérêt légitime (art. 6.1.f RGPD), avec opposition en un
/// appui dans Réglages > Confidentialité. Données minimales : ni compte, ni
/// e-mail, ni adresse IP, ni capture d'écran, ni fil d'actions ; les
/// identifiants et e-mails restés dans les messages d'erreur sont masqués
/// avant l'envoi ([scrub]).
///
/// Inactif sans `SENTRY_DSN` (développement, tests, CI) : l'app démarre
/// alors sans Sentry.
abstract final class CrashReporting {
  static const String _prefKey = 'cq_crash_reports';

  static bool _enabled = true;

  static bool get isConfigured => AppConfig.sentryDsn.isNotEmpty;

  /// Choix de l'appareil ; activé par défaut (opposition possible).
  static Future<bool> readPreference() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_prefKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await (await SharedPreferences.getInstance()).setBool(_prefKey, enabled);
  }

  /// Lance l'app, sous Sentry s'il est configuré : erreurs Flutter, erreurs
  /// asynchrones et plantages natifs sont alors remontés.
  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (!isConfigured) return appRunner();
    _enabled = await readPreference();
    await SentryFlutter.init(configure, appRunner: appRunner);
  }

  @visibleForTesting
  static void configure(SentryFlutterOptions options) {
    options
      ..dsn = AppConfig.sentryDsn
      ..environment = kReleaseMode ? 'production' : 'development'
      ..release = 'cognicquest@${AppConfig.appVersion}'
      ..sendDefaultPii = false
      ..attachScreenshot = false
      ..attachViewHierarchy = false
      ..enableAutoNativeBreadcrumbs = false
      ..maxBreadcrumbs = 0
      // Web : pas de SDK JavaScript chargé depuis le CDN de Sentry (CSP
      // stricte, mode hors ligne) ; le SDK Dart envoie seul les erreurs.
      ..autoInitializeNativeSdk = !kIsWeb
      // Pas de mesure de performance : seulement les plantages.
      ..tracesSampleRate = 0
      ..beforeSend = (event, hint) => scrub(event);
  }

  static final RegExp _uuid = RegExp(
      r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
      caseSensitive: false);
  static final RegExp _email = RegExp(r'[^\s@"<>]+@[^\s@"<>]+\.[a-z]{2,}',
      caseSensitive: false);

  /// Dernier filtre avant l'envoi : `null` si l'utilisateur s'y est opposé.
  @visibleForTesting
  static SentryEvent? scrub(SentryEvent event, {bool? enabled}) {
    if (!(enabled ?? _enabled)) return null;
    event
      ..user = null
      ..request = null
      ..serverName = null
      ..breadcrumbs = null;
    for (final exception in event.exceptions ?? const <SentryException>[]) {
      final value = exception.value;
      if (value == null) continue;
      exception.value = value
          .replaceAll(_email, '<e-mail>')
          .replaceAll(_uuid, '<id>');
    }
    return event;
  }
}

/// Choix « Rapports de plantage » des Réglages.
class CrashReportsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => CrashReporting.readPreference();

  Future<void> set(bool enabled) async {
    await CrashReporting.setEnabled(enabled);
    state = AsyncValue.data(enabled);
  }
}

final crashReportsProvider =
    AsyncNotifierProvider<CrashReportsNotifier, bool>(CrashReportsNotifier.new);
