import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Erreur de persistance traduite en message lisible par l'utilisateur.
///
/// Pendant du `AuthFailure` du Lot 1 : le mapping message-utilisateur est fait
/// une fois ici, jamais dans les pages.
class DataFailure implements Exception {
  const DataFailure(this.message, {this.code, this.isOffline = false});

  final String message;
  final String? code;

  /// Permet aux pages de proposer « Réessayer » plutôt qu'un message d'échec
  /// définitif, et servira de déclencheur à la file de synchronisation offline.
  final bool isOffline;

  factory DataFailure.from(Object error) {
    if (error is DataFailure) return error;

    if (error is SocketException || error is TimeoutException) {
      return const DataFailure(
        'Pas de connexion. Tes modifications seront à refaire une fois '
        'la connexion rétablie.',
        isOffline: true,
      );
    }

    if (error is PostgrestException) {
      return DataFailure(_messageForPostgrest(error), code: error.code);
    }

    if (error is AuthException) {
      return const DataFailure(
        'Ta session a expiré. Reconnecte-toi pour continuer.',
        code: 'session_expired',
      );
    }

    final raw = error.toString().toLowerCase();
    // Les deux dernières formes sont celles du web : le navigateur ne lève pas
    // de `SocketException`, seulement un `ClientException` du paquet http.
    if (raw.contains('failed host lookup') ||
        raw.contains('socketexception') ||
        raw.contains('connection closed') ||
        raw.contains('connection refused') ||
        raw.contains('network is unreachable') ||
        raw.contains('failed to fetch') ||
        raw.contains('xmlhttprequest error')) {
      return const DataFailure('Pas de connexion internet.', isOffline: true);
    }

    return const DataFailure(
      'Une erreur est survenue. Réessaie dans un instant.',
    );
  }

  static String _messageForPostgrest(PostgrestException error) {
    final code = error.code;
    final raw = error.message.toLowerCase();

    // 42P01 : table absente — typiquement schema.sql pas encore exécuté.
    if (code == '42P01' || raw.contains('does not exist')) {
      return 'La base de données n\'est pas initialisée. '
          'Exécute `supabase/schema.sql` dans ton projet Supabase.';
    }
    // 23505 : violation de contrainte d'unicité.
    if (code == '23505') {
      return 'Cet élément existe déjà.';
    }
    // 23503 : clé étrangère.
    if (code == '23503') {
      return 'Impossible : cet élément est rattaché à un autre.';
    }
    // 42501 / PGRST301 : RLS refuse l'opération.
    if (code == '42501' || code == 'PGRST301' || raw.contains('row-level security')) {
      return 'Tu n\'as pas les droits sur cet élément.';
    }

    return 'Une erreur est survenue. Réessaie dans un instant.';
  }

  @override
  String toString() => message;
}
