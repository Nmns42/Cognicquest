import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Export de toutes les données de l'utilisateur en JSON (RGPD, art. 15 et
/// 20 : accès et portabilité).
///
/// Lit la base locale, qui ne contient que le compte connecté (elle est
/// effacée à chaque déconnexion) et que la synchronisation complète depuis
/// le serveur. Chaque table devient une liste d'objets, dates en ISO 8601.
abstract final class UserDataExport {
  /// Version du format du fichier.
  static const int formatVersion = 1;

  /// Tables techniques de la synchronisation : sans valeur pour
  /// l'utilisateur.
  static const Set<String> technicalTables = {
    'sync_queue_entries',
    'sync_cursors',
    'sync_row_versions',
  };

  static const String _mediaTable = 'local_media_cache';

  static const ValueSerializer _serializer =
      ValueSerializer.defaults(serializeDateTimeValuesAsString: true);

  static Future<Map<String, Object?>> collect(
    AppDatabase db, {
    required String userId,
    String? email,
    Map<String, Object?> consent = const {},
    DateTime? now,
  }) async {
    final data = <String, Object?>{};
    for (final table in db.allTables) {
      final name = table.actualTableName;
      if (technicalTables.contains(name)) continue;
      final rows = await db.select(table).get();
      data[_label(name)] = [
        for (final row in rows)
          name == _mediaTable
              ? _media(row as LocalMediaCacheData)
              : (row as DataClass).toJson(serializer: _serializer),
      ];
    }
    return {
      'application': 'CognicQuest',
      'format_version': formatVersion,
      'exported_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'account': {'user_id': userId, 'email': email},
      'consent': consent,
      'data': data,
    };
  }

  /// JSON indenté, encodé en UTF-8.
  static Uint8List encode(Map<String, Object?> export) => Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(export)));

  static String fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'cognicquest-mes-donnees-'
        '${now.year}-${two(now.month)}-${two(now.day)}.json';
  }

  /// `local_notes` → `notes` : le préfixe ne dit rien à l'utilisateur.
  static String _label(String table) =>
      table.startsWith('local_') ? table.substring(6) : table;

  /// Images gardées sur l'appareil, contenu en base64.
  static Map<String, Object?> _media(LocalMediaCacheData row) => {
        'path': row.path,
        'mime_type': row.mimeType,
        'created_at': row.createdAt.toUtc().toIso8601String(),
        'base64': base64Encode(row.bytes),
      };
}
