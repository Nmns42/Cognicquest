import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_database.dart';
import 'remote_pagination.dart';

/// Recouvrement appliqué au curseur à chaque pull.
///
/// `updated_at = now()` vaut l'heure de *début* de la transaction serveur :
/// une écriture lente peut être validée après une autre plus récente, avec un
/// `updated_at` antérieur au curseur déjà avancé. Relire les deux dernières
/// minutes à chaque fois rattrape ces lignes ; les réappliquer est sans effet.
const Duration pullLookback = Duration(minutes: 2);

/// Changements distants depuis le dernier pull.
class RemoteDelta {
  const RemoteDelta({
    required this.changed,
    required this.remoteIds,
    required this.cursor,
  });

  /// Lignes complètes créées ou modifiées depuis le curseur (toutes au
  /// premier pull).
  final List<Map<String, dynamic>> changed;

  /// Identifiants de **toutes** les lignes distantes, pour détecter celles
  /// supprimées depuis un autre appareil. `null` si non demandé.
  final Set<String>? remoteIds;

  /// Nouveau curseur : plus grand `updated_at` vu, ou l'ancien si rien n'a
  /// changé. À enregistrer *dans la même transaction* que les lignes.
  final String? cursor;
}

/// Lecture / écriture des curseurs d'un utilisateur.
class PullCursors {
  const PullCursors(this._db, this._userId);

  final AppDatabase _db;
  final String _userId;

  Future<String?> read(String table) async {
    final row = await (_db.select(_db.syncCursors)
          ..where((t) =>
              t.userId.equals(_userId) & t.remoteTable.equals(table)))
        .getSingleOrNull();
    return row?.pulledUntil;
  }

  /// Oublie le curseur : le prochain pull relit toute la table. Sert après
  /// un refus d'écriture obsolète, quand la version serveur gagnante a pu
  /// être lue (puis ignorée car en attente d'envoi) avant le curseur actuel.
  Future<void> reset(String table) => (_db.delete(_db.syncCursors)
        ..where((t) => t.userId.equals(_userId) & t.remoteTable.equals(table)))
      .go();

  Future<void> write(String table, String? cursor) async {
    if (cursor == null) return;
    await _db.into(_db.syncCursors).insertOnConflictUpdate(
          SyncCursorsCompanion.insert(
            userId: _userId,
            remoteTable: table,
            pulledUntil: cursor,
          ),
        );
  }
}

/// Rapatrie les lignes modifiées depuis [since].
///
/// [rows] construit la requête des lignes complètes (filtrée sur
/// l'utilisateur) ; le filtre `updated_at` y est ajouté ici. [ids], s'il est
/// fourni, construit la requête légère des seuls identifiants : au premier
/// pull, elle est inutile puisque toutes les lignes arrivent déjà.
Future<RemoteDelta> fetchDelta({
  required PostgrestFilterBuilder<PostgrestList> Function() rows,
  PostgrestFilterBuilder<PostgrestList> Function()? ids,
  required String? since,
}) async {
  final changed = await fetchAllPages(() {
    final query = rows();
    if (since == null) return query;
    final from = DateTime.parse(since).toUtc().subtract(pullLookback);
    return query.gt('updated_at', from.toIso8601String());
  });

  Set<String>? remoteIds;
  if (ids != null) {
    remoteIds = since == null
        ? {for (final row in changed) row['id'] as String}
        : {for (final row in await fetchAllPages(ids)) row['id'] as String};
  }

  return RemoteDelta(
    changed: changed,
    remoteIds: remoteIds,
    cursor: _maxUpdatedAt(changed, since),
  );
}

String? _maxUpdatedAt(List<Map<String, dynamic>> rows, String? since) {
  var max = since == null ? null : DateTime.parse(since).toUtc();
  for (final row in rows) {
    final raw = row['updated_at'] as String?;
    if (raw == null) continue;
    final value = DateTime.parse(raw).toUtc();
    if (max == null || value.isAfter(max)) max = value;
  }
  return max?.toIso8601String();
}
