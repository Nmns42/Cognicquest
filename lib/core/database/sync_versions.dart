import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_database.dart';

/// Contrôle de version optimiste des envois.
///
/// Chaque ligne tirée ou poussée retient la version serveur (`updated_at`)
/// sur laquelle repose sa copie locale. Le push la renvoie dans
/// `updated_at` ; le trigger `reject_stale_write` refuse l'écriture (code
/// 40001) si la ligne a changé depuis sur le serveur, au lieu d'écraser la
/// version plus récente d'un autre appareil.
class SyncVersions {
  const SyncVersions(this._db);

  final AppDatabase _db;

  /// Corps d'upsert prêt à partir : l'éventuel `updated_at` du modèle
  /// (horloge de l'appareil) est remplacé par la version de base connue, ou
  /// retiré si la ligne n'a jamais été vue du serveur.
  Future<Map<String, dynamic>> stamp(
    String table,
    String id,
    Map<String, dynamic> body,
  ) async {
    final base = await read(table, id);
    return {
      for (final entry in body.entries)
        if (entry.key != 'updated_at') entry.key: entry.value,
      if (base != null) 'updated_at': base,
    };
  }

  Future<String?> read(String table, String id) async {
    final row = await (_db.select(_db.syncRowVersions)
          ..where((t) => t.remoteTable.equals(table) & t.entityId.equals(id)))
        .getSingleOrNull();
    return row?.serverUpdatedAt;
  }

  Future<void> record(String table, String id, String? serverUpdatedAt) async {
    if (serverUpdatedAt == null) return;
    await _db.into(_db.syncRowVersions).insertOnConflictUpdate(
          SyncRowVersionsCompanion.insert(
            remoteTable: table,
            entityId: id,
            serverUpdatedAt: serverUpdatedAt,
          ),
        );
  }

  Future<void> forget(String table, String id) =>
      (_db.delete(_db.syncRowVersions)
            ..where((t) => t.remoteTable.equals(table) & t.entityId.equals(id)))
          .go();
}

/// Refus du serveur : la ligne a été modifiée ailleurs depuis la version
/// envoyée.
bool isStaleWrite(Object error) =>
    error is PostgrestException && error.code == '40001';
