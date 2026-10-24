/// Web : pas de serveur local, le retour OAuth se fait par redirection de
/// la page elle-même.
class LoopbackOAuthReceiver {
  LoopbackOAuthReceiver();

  static bool get isNeeded => false;

  Future<String> start() => throw UnsupportedError('Indisponible sur le web');

  Future<String> waitForCode({Duration timeout = const Duration(minutes: 5)}) =>
      throw UnsupportedError('Indisponible sur le web');

  Future<void> close() async {}
}

class OAuthLoopbackException implements Exception {
  const OAuthLoopbackException(this.message);

  final String message;

  @override
  String toString() => message;
}
