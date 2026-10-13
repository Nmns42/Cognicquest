import 'dart:io';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/database/sync_queue.dart';
import 'package:cognicquest/core/errors/data_failure.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plafond d'échecs de la file : une ligne refusée par le serveur ne doit ni
/// être retentée indéfiniment, ni bloquer les autres.
void main() {
  late AppDatabase db;
  late SyncQueue queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = SyncQueue(db);
  });

  tearDown(() => db.close());

  Future<SyncQueueEntry> entry(String id) => (db.select(db.syncQueueEntries)
        ..where((t) => t.entityId.equals(id)))
      .getSingle();

  test('une entrée refusée ne bloque pas les suivantes', () async {
    await queue.enqueue('t', 'bad', 'upsert');
    await queue.enqueue('t', 'good', 'upsert');
    final pushed = <String>[];

    await queue.drain('t', (e) async {
      if (e.entityId == 'bad') throw const DataFailure('refusé');
      pushed.add(e.entityId);
    });

    expect(pushed, ['good']);
    expect((await entry('bad')).attempts, 1);
    expect(await queue.pendingCount(), 1);
  });

  test('après maxAttempts refus, l\'entrée n\'est plus tentée', () async {
    await queue.enqueue('t', 'bad', 'upsert');
    var tries = 0;
    Future<void> refuse(SyncQueueEntry _) async {
      tries++;
      throw const DataFailure('refusé');
    }

    for (var i = 0; i < SyncQueue.maxAttempts + 3; i++) {
      await queue.drain('t', refuse);
    }

    expect(tries, SyncQueue.maxAttempts);
    expect((await entry('bad')).attempts, SyncQueue.maxAttempts);
    // Toujours en file : la déconnexion doit encore prévenir de sa perte.
    expect(await queue.pendingCount(), 1);
  });

  test('releaseParked accorde un seul nouvel essai', () async {
    await queue.enqueue('t', 'bad', 'upsert');
    var tries = 0;
    Future<void> refuse(SyncQueueEntry _) async {
      tries++;
      throw const DataFailure('refusé');
    }

    for (var i = 0; i < SyncQueue.maxAttempts; i++) {
      await queue.drain('t', refuse);
    }
    tries = 0;

    await queue.releaseParked();
    await queue.drain('t', refuse);
    await queue.drain('t', refuse);

    expect(tries, 1);
  });

  test('une nouvelle modification repart de zéro', () async {
    await queue.enqueue('t', 'bad', 'upsert');
    for (var i = 0; i < SyncQueue.maxAttempts; i++) {
      await queue.drain('t', (_) async => throw const DataFailure('refusé'));
    }

    await queue.enqueue('t', 'bad', 'upsert');

    expect((await entry('bad')).attempts, 0);
  });

  test('une coupure réseau ne compte pas comme un échec', () async {
    await queue.enqueue('t', 'a', 'upsert');

    for (var i = 0; i < SyncQueue.maxAttempts + 1; i++) {
      await expectLater(
        queue.drain('t', (_) async => throw const SocketException('down')),
        throwsA(isA<DataFailure>()),
      );
    }

    expect((await entry('a')).attempts, 0);
  });
}
