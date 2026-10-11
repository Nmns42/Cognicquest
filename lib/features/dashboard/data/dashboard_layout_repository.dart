import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/data_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_module.dart';

abstract interface class DashboardLayoutRepository {
  Future<DashboardLayout?> fetch();
  Future<void> save(DashboardLayout layout);
}

/// Persistance dans `user_preferences.dashboard_layout` (jsonb).
///
/// La table est volontairement générique : le Lot 9 (thème, taille de texte,
/// sons) y ajoutera ses colonnes sans nouvelle migration structurelle.
class SupabaseDashboardLayoutRepository implements DashboardLayoutRepository {
  const SupabaseDashboardLayoutRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const String _table = 'user_preferences';

  @override
  Future<DashboardLayout?> fetch() async {
    try {
      final row = await _client
          .from(_table)
          .select('dashboard_layout')
          .eq('user_id', _userId)
          .maybeSingle();

      final raw = row?['dashboard_layout'];
      if (raw is! Map) return null;
      return DashboardLayout.fromJson(Map<String, dynamic>.from(raw));
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Future<void> save(DashboardLayout layout) async {
    try {
      await _client.from(_table).upsert(
        {
          'user_id': _userId,
          'dashboard_layout': layout.toJson(),
        },
        onConflict: 'user_id',
      );
    } catch (error) {
      throw DataFailure.from(error);
    }
  }
}

final dashboardLayoutRepositoryProvider =
    Provider<DashboardLayoutRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return SupabaseDashboardLayoutRepository(
    ref.watch(supabaseClientProvider),
    userId,
  );
});
