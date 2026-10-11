import 'package:drift/drift.dart';

import '../errors/data_failure.dart';
import 'app_database.dart';

/// Sérialise les synchronisations d'un repository.
///
/// Chaque écriture locale déclenche un envoi : sans ce garde-fou, cinq
/// déplacements rapides de carte lanceraient cinq synchronisations
/// concurrentes qui pousseraient les mêmes lignes. Un appel reçu pendant une
/// synchronisation en programme une seule de plus, pour ne pas oublier les
/// écritures arrivées entre-temps.
class SerialSync {
  SerialSync(this._run);

  final Future<void> Function() _run;
  Future<void>? _current;
  bool _rerun = false;

  Future<void> call() {
    if (_current != null) {
      _rerun = true;
      return _current!;
    }
    return _current = _loop().whenComplete(() => _current = null);
  }

  Future<void> _loop() async {
    do {
      _rerun = false;
      await _run();
    } while (_rerun);
  }
}

/// Levée par un `push` pour laisser une entrée en file sans la compter comme
/// un échec : typiquement une écriture d'un autre compte utilisé sur le même
/// appareil, qui sera envoyée quand ce compte se reconnectera.
class SkipEntry implements Exception {
  const SkipEntry();
}

/// Accès à la file [SyncQueueEntries], partagé par les repositories du Lot 10.
///
/// Les repositories des Lots 4 à 8 réimplémentent chacun ces quelques
/// requêtes ; on les factorise ici plutôt que de les copier une sixième fois.
class SyncQueue {
  const SyncQueue(this._db);

  final AppDatabase _db;

  /// Dépose une intention d'envoi. Une seule entrée par entité : dix
  /// modifications successives hors ligne ne produisent qu'un envoi.
  Future<void> enqueue(String table, String entityId, String operation) async {
    await remove(table, entityId);
    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityTable: table,
            entityId: entityId,
            operation: operation,
            queuedAt: DateTime.now(),
          ),
        );
  }

  /// Retire l'entrée en attente d'une entité, s'il y en a une.
  Future<void> remove(String table, String entityId) =>
      (_db.delete(_db.syncQueueEntries)
            ..where((t) =>
                t.entityTable.equals(table) & t.entityId.equals(entityId)))
          .go();

  /// Identifiants ayant une écriture locale pas encore envoyée. Le pull ne
  /// doit jamais les écraser avec la version serveur, plus ancienne.
  Future<Set<String>> pendingIds(String table) async {
    final rows = await (_db.select(_db.syncQueueEntries)
          ..where((t) => t.entityTable.equals(table)))
        .get();
    return {for (final row in rows) row.entityId};
  }

  /// Nombre total d'écritures en attente, toutes tables confondues.
  Stream<int> watchPendingCount() {
    final count = _db.syncQueueEntries.id.count();
    return (_db.selectOnly(_db.syncQueueEntries)..addColumns([count]))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// Envoie, dans l'ordre d'arrivée, les entrées de [table] via [push].
  ///
  /// Une entrée qui échoue reste dans la file avec son erreur. Hors ligne, on
  /// s'arrête aussitôt (les suivantes échoueraient pareil) en relançant
  /// l'erreur ; sinon on passe à la suivante, pour qu'une seule ligne
  /// refusée par le serveur ne bloque pas toute la synchronisation.
  Future<void> drain(
    String table,
    Future<void> Function(SyncQueueEntry entry) push,
  ) async {
    final pending = await (_db.select(_db.syncQueueEntries)
          ..where((t) => t.entityTable.equals(table))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();

    for (final entry in pending) {
      try {
        await push(entry);
        await (_db.delete(_db.syncQueueEntries)
              ..where((t) => t.id.equals(entry.id)))
            .go();
      } on SkipEntry {
        continue;
      } catch (error) {
        final failure = DataFailure.from(error);
        await (_db.update(_db.syncQueueEntries)
              ..where((t) => t.id.equals(entry.id)))
            .write(
          SyncQueueEntriesCompanion(
            attempts: Value(entry.attempts + 1),
            lastError: Value(failure.message),
          ),
        );
        if (failure.isOffline) throw failure;
      }
    }
  }
}
