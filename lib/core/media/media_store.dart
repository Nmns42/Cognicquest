import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../database/app_database.dart';
import '../database/sync_queue.dart';

/// Préfixe des références d'images déposées dans Storage.
const String mediaScheme = 'media://';

/// Images hors base : déposées dans le bucket privé `user_media`, référencées
/// dans le texte par `media://<user_id>/<fichier>`.
///
/// Local-first : [put] garde les octets dans [LocalMediaCache] et met
/// l'envoi en file ; l'image s'affiche aussitôt, même hors ligne. [read]
/// sert le cache, sinon télécharge (image venue d'un autre appareil) et la
/// garde pour la suite.
class MediaStore {
  MediaStore({
    required AppDatabase database,
    required SupabaseClient client,
    required String userId,
    bool syncEnabled = true,
  })  : _db = database,
        _client = client,
        _userId = userId,
        _syncEnabled = syncEnabled;

  final AppDatabase _db;
  final SupabaseClient _client;
  final String _userId;
  final bool _syncEnabled;

  static const String bucket = 'user_media';

  /// Taille maximale d'une image (limite du bucket).
  static const int maxBytes = 5 * 1024 * 1024;

  late final SyncQueue _queue = SyncQueue(_db);
  late final SerialSync _serialSync = SerialSync(_push);

  static bool isMediaRef(String source) => source.startsWith(mediaScheme);

  static String mimeOf(String? extension) =>
      switch (extension?.toLowerCase()) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  /// Enregistre une image et renvoie sa référence `media://…`.
  Future<String> put(Uint8List bytes, {String? extension}) async {
    final mime = mimeOf(extension);
    final ext = mime.split('/').last.replaceFirst('jpeg', 'jpg');
    final path = '$_userId/${_randomName()}.$ext';
    await _db.transaction(() async {
      await _db.into(_db.localMediaCache).insert(
            LocalMediaCacheCompanion.insert(
              path: path,
              userId: _userId,
              bytes: bytes,
              mimeType: mime,
              createdAt: DateTime.now(),
            ),
          );
      await _queue.enqueue(bucket, path, 'upload');
    });
    sync().catchError((_) {});
    return '$mediaScheme$path';
  }

  /// Octets d'une référence `media://…`, ou `null` si introuvable (hors
  /// ligne et jamais vue sur cet appareil, ou supprimée).
  Future<Uint8List?> read(String ref) async {
    if (!isMediaRef(ref)) return null;
    final path = ref.substring(mediaScheme.length);
    final cached = await (_db.select(_db.localMediaCache)
          ..where((t) => t.path.equals(path)))
        .getSingleOrNull();
    if (cached != null) return cached.bytes;
    if (!_syncEnabled) return null;
    try {
      final bytes = await _client.storage.from(bucket).download(path);
      await _db.into(_db.localMediaCache).insertOnConflictUpdate(
            LocalMediaCacheCompanion.insert(
              path: path,
              userId: _userId,
              bytes: bytes,
              mimeType: mimeOf(path.split('.').last),
              createdAt: DateTime.now(),
            ),
          );
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> sync() async {
    if (!_syncEnabled) return;
    await _serialSync();
  }

  Future<void> _push() => _queue.drain(bucket, (entry) async {
        final row = await (_db.select(_db.localMediaCache)
              ..where((t) => t.path.equals(entry.entityId)))
            .getSingleOrNull();
        if (row == null) return;
        if (row.userId != _userId) throw const SkipEntry();
        await _client.storage.from(bucket).uploadBinary(
              row.path,
              row.bytes,
              fileOptions: FileOptions(contentType: row.mimeType, upsert: true),
            );
      });

  static final Random _random = Random.secure();

  static String _randomName() => List.generate(
        16,
        (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
}

final mediaStoreProvider = Provider<MediaStore?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return MediaStore(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
    syncEnabled: ref.watch(currentUserProvider) != null,
  );
});

/// Octets d'une image `media://…`, mis en cache par Riverpod le temps de
/// l'affichage.
final mediaBytesProvider =
    FutureProvider.autoDispose.family<Uint8List?, String>((ref, source) async {
  final store = ref.watch(mediaStoreProvider);
  return store?.read(source);
});
