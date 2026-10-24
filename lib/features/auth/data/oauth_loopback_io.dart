import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Retour OAuth par serveur local (`127.0.0.1`), pour les plateformes de
/// bureau sans schéma d'URL (`io.cognicquest.app://`) : Windows et Linux.
///
/// Le navigateur est renvoyé vers `http://127.0.0.1:<port>/auth/callback`
/// avec le code PKCE ; le serveur le récupère, affiche une page « Connexion
/// réussie » et s'arrête. Il n'écoute que la boucle locale et une seule
/// requête de rappel.
class LoopbackOAuthReceiver {
  LoopbackOAuthReceiver({this.port = defaultPort});

  /// Port fixe : l'adresse de retour doit être autorisée telle quelle dans
  /// Supabase (Authentication > URL Configuration > Redirect URLs).
  static const int defaultPort = 43823;

  static const String callbackPath = '/auth/callback';

  final int port;
  HttpServer? _server;

  static bool get isNeeded => Platform.isWindows || Platform.isLinux;

  /// Démarre l'écoute et renvoie l'adresse de retour à donner à Supabase.
  Future<String> start() async {
    final server = _server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    return 'http://127.0.0.1:${server.port}$callbackPath';
  }

  /// Attend le rappel et renvoie le code d'autorisation. Lève une
  /// [OAuthLoopbackException] si le fournisseur renvoie une erreur ou si
  /// rien n'arrive avant [timeout].
  Future<String> waitForCode({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final server = _server;
    if (server == null) throw StateError('start() doit précéder');
    try {
      await for (final request in server.timeout(timeout)) {
        if (request.uri.path != callbackPath) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }
        final params = request.uri.queryParameters;
        final code = params['code'];
        final error = params['error_description'] ?? params['error'];
        await _reply(request.response, success: code != null);
        if (code != null) return code;
        throw OAuthLoopbackException(error ?? 'Connexion annulée.');
      }
      throw const OAuthLoopbackException('Connexion interrompue.');
    } on TimeoutException {
      throw const OAuthLoopbackException(
          'Délai dépassé : la connexion Google n’a pas abouti.');
    } finally {
      await close();
    }
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
  }

  static Future<void> _reply(HttpResponse response,
      {required bool success}) async {
    final message = success
        ? 'Connexion réussie. Tu peux fermer cet onglet et revenir à '
            'CognicQuest.'
        : 'La connexion n’a pas abouti. Ferme cet onglet et réessaie '
            'depuis CognicQuest.';
    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..add(utf8.encode('<!doctype html><html lang="fr"><meta charset="utf-8">'
          '<title>CognicQuest</title>'
          '<body style="font-family:system-ui,sans-serif;background:#FAF8F5;'
          'color:#1E2A1A;display:grid;place-items:center;height:100vh;'
          'margin:0"><p>${const HtmlEscape().convert(message)}</p></body>'
          '</html>'));
    await response.close();
  }
}

class OAuthLoopbackException implements Exception {
  const OAuthLoopbackException(this.message);

  final String message;

  @override
  String toString() => message;
}
