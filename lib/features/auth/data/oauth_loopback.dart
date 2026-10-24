// Serveur local de retour OAuth : dart:io hors web uniquement.
export 'oauth_loopback_stub.dart'
    if (dart.library.io) 'oauth_loopback_io.dart';
