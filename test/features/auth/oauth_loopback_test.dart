import 'dart:convert';
import 'dart:io';

import 'package:cognicquest/features/auth/data/oauth_loopback_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<(int, String)> get(String url) async {
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(Uri.parse(url))).close();
      return (response.statusCode, await response.transform(utf8.decoder).join());
    } finally {
      client.close();
    }
  }

  test('récupère le code PKCE renvoyé par le navigateur', () async {
    final receiver = LoopbackOAuthReceiver(port: 0);
    final redirect = await receiver.start();
    expect(redirect, startsWith('http://127.0.0.1:'));
    expect(redirect, endsWith('/auth/callback'));

    final code = receiver.waitForCode();
    final (status, page) = await get('$redirect?code=abc123');

    expect(await code, 'abc123');
    expect(status, 200);
    expect(page, contains('Connexion réussie'));
  });

  test('une erreur du fournisseur est remontée telle quelle', () async {
    final receiver = LoopbackOAuthReceiver(port: 0);
    final redirect = await receiver.start();

    final code = receiver.waitForCode();
    final expectation = expectLater(
      code,
      throwsA(isA<OAuthLoopbackException>()
          .having((e) => e.message, 'message', 'Accès refusé')),
    );
    await get('$redirect?error=access_denied&error_description=Acc%C3%A8s+refus%C3%A9');
    await expectation;
  });

  test('ignore les requêtes parasites (favicon) et s\'arrête au délai',
      () async {
    final receiver = LoopbackOAuthReceiver(port: 0);
    final redirect = await receiver.start();
    final origin = Uri.parse(redirect).origin;

    final code = receiver.waitForCode(timeout: const Duration(seconds: 1));
    final expectation =
        expectLater(code, throwsA(isA<OAuthLoopbackException>()));
    final (status, _) = await get('$origin/favicon.ico');
    expect(status, 404);
    await expectation;
  });
}
