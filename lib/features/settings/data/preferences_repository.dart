import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_queue.dart';
import '../../auth/providers/auth_provider.dart';

/// Préférences synchronisées : chacune est une colonne jsonb de
/// `user_preferences`, et une colonne de [LocalPreferences].
enum PreferenceKey {
  settings('settings'),
  dashboardLayout('dashboard_layout');

  const PreferenceKey(this.column);

  /// Nom de la colonne côté serveur ; sert aussi d'identifiant dans la file.
  final String column;
}

/// Réglages et disposition du Dashboard en **local-first**, comme les autres
/// modules : SQLite est la source de vérité, Supabase un miroir.
///
/// Avant, ils n'existaient que sur le serveur : hors ligne, l'app revenait au
/// thème et à la disposition par défaut, et un choix fait sans réseau était
/// perdu.
class LocalFirstPreferencesRepository {
  LocalFirstPreferencesRepository({
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

  /// `false` sans vraie session (mode `DEV_BYPASS_AUTH`) : tout reste local,
  /// aucune requête ne part avec l'utilisateur fictif.
  final bool _syncEnabled;

  late final SyncQueue _queue = SyncQueue(_db);

  static const String table = 'user_preferences';

  /// Valeur locale de [key], puis chacune de ses modifications (choix de
  /// l'utilisateur ou valeur rapatriée du serveur). `null` : rien de choisi.
  Stream<Map<String, dynamic>?> watch(PreferenceKey key) =>
      (_db.select(_db.localPreferences)
            ..where((t) => t.userId.equals(_userId)))
          .watchSingleOrNull()
          .map((row) => _decode(row == null ? null : _read(row, key)))
          .distinct(_sameJson);

  /// Enregistre [json] sur l'appareil, puis l'envoie dès que possible.
  Future<void> save(PreferenceKey key, Map<String, dynamic> json) async {
    await _db.transaction(() async {
      await _write(key, jsonEncode(json));
      await _queue.enqueue(table, key.column, 'upsert');
    });
    _syncQuietly();
  }

  void _syncQuietly() {
    sync().catchError((_) {});
  }

  Future<void> sync() async {
    if (!_syncEnabled) return;
    await _serialSync();
  }

  late final SerialSync _serialSync = SerialSync(() async {
    await _queue.drain(table, _push);
    await _pull();
  });

  Future<void> _push(SyncQueueEntry entry) async {
    final key = PreferenceKey.values
        .where((k) => k.column == entry.entityId)
        .firstOrNull;
    if (key == null) return;
    final row = await _localRow();
    final value = row == null ? null : _decode(_read(row, key));
    if (value == null) return;

    await _client.from(table).upsert(
      {'user_id': _userId, key.column: value},
      onConflict: 'user_id',
    );
  }

  /// Rapatrie les préférences choisies sur un autre appareil. Une préférence
  /// encore en attente d'envoi n'est jamais écrasée par la version serveur,
  /// plus ancienne.
  Future<void> _pull() async {
    final remote = await _client
        .from(table)
        .select(PreferenceKey.values.map((k) => k.column).join(', '))
        .eq('user_id', _userId)
        .maybeSingle();
    if (remote == null) return;

    final pending = await _queue.pendingIds(table);
    for (final key in PreferenceKey.values) {
      if (pending.contains(key.column)) continue;
      final value = remote[key.column];
      if (value is! Map || value.isEmpty) continue;
      await _write(key, jsonEncode(value));
    }
  }

  Future<LocalPreference?> _localRow() => (_db.select(_db.localPreferences)
        ..where((t) => t.userId.equals(_userId)))
      .getSingleOrNull();

  Future<void> _write(PreferenceKey key, String json) async {
    await _db.into(_db.localPreferences).insert(
          LocalPreferencesCompanion.insert(userId: _userId),
          mode: InsertMode.insertOrIgnore,
        );
    await (_db.update(_db.localPreferences)
          ..where((t) => t.userId.equals(_userId)))
        .write(switch (key) {
      PreferenceKey.settings => LocalPreferencesCompanion(settings: Value(json)),
      PreferenceKey.dashboardLayout =>
        LocalPreferencesCompanion(dashboardLayout: Value(json)),
    });
  }

  static String? _read(LocalPreference row, PreferenceKey key) => switch (key) {
        PreferenceKey.settings => row.settings,
        PreferenceKey.dashboardLayout => row.dashboardLayout,
      };

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    final value = jsonDecode(raw);
    return value is Map && value.isNotEmpty
        ? Map<String, dynamic>.from(value)
        : null;
  }

  static bool _sameJson(Map<String, dynamic>? a, Map<String, dynamic>? b) =>
      jsonEncode(a) == jsonEncode(b);
}

final preferencesRepositoryProvider =
    Provider<LocalFirstPreferencesRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return LocalFirstPreferencesRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
    syncEnabled: ref.watch(currentUserProvider) != null,
  );
});
