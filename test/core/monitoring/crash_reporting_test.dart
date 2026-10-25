import 'package:cognicquest/core/monitoring/crash_reporting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

SentryEvent event() => SentryEvent(
      user: SentryUser(id: 'u1', email: 'eleve@example.com'),
      serverName: 'poste-de-mehdi',
      breadcrumbs: [Breadcrumb(message: 'ouverture de la fiche')],
      exceptions: [
        SentryException(
          type: 'PostgrestException',
          value: 'Ligne 3f2b8c1e-1d2a-4b5c-9e8f-0a1b2c3d4e5f refusée pour '
              'eleve@example.com',
        ),
      ],
    );

void main() {
  test('opposition : aucun rapport envoyé', () {
    expect(CrashReporting.scrub(event(), enabled: false), isNull);
  });

  test('rapport envoyé sans compte, appareil, fil d\'actions ni identifiants',
      () {
    final scrubbed = CrashReporting.scrub(event(), enabled: true)!;
    expect(scrubbed.user, isNull);
    expect(scrubbed.serverName, isNull);
    expect(scrubbed.breadcrumbs, isNull);
    final value = scrubbed.exceptions!.single.value!;
    expect(value, 'Ligne <id> refusée pour <e-mail>');
    expect(scrubbed.exceptions!.single.type, 'PostgrestException');
  });

  test('options : pas de données personnelles ni de mesure de performance',
      () {
    final options = SentryFlutterOptions();
    CrashReporting.configure(options);
    expect(options.sendDefaultPii, isFalse);
    expect(options.attachScreenshot, isFalse);
    expect(options.attachViewHierarchy, isFalse);
    expect(options.maxBreadcrumbs, 0);
    expect(options.tracesSampleRate, 0);
    expect(options.release, startsWith('cognicquest@'));
  });

  test('sans DSN (développement, CI) : Sentry éteint, l\'app démarre', () async {
    expect(CrashReporting.isConfigured, isFalse);
    var started = false;
    await CrashReporting.run(() => started = true);
    expect(started, isTrue);
  });

  test('choix mémorisé, activé par défaut', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await CrashReporting.readPreference(), isTrue);
    await CrashReporting.setEnabled(false);
    expect(await CrashReporting.readPreference(), isFalse);
  });
}
