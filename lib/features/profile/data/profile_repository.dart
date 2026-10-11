import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/data_failure.dart';
import '../../../shared/models/profile_model.dart';
import '../../auth/providers/auth_provider.dart';

abstract interface class ProfileRepository {
  Future<Profile?> fetch();
  Future<Profile> updateName(String fullName);
}

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const String _table = 'profiles';

  @override
  Future<Profile?> fetch() async {
    try {
      // `maybeSingle` : un compte créé avant le trigger `handle_new_user`
      // n'a pas encore de ligne — ce n'est pas une erreur.
      final row =
          await _client.from(_table).select().eq('id', _userId).maybeSingle();
      return row == null ? null : Profile.fromJson(row);
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Future<Profile> updateName(String fullName) async {
    try {
      final row = await _client
          .from(_table)
          .update({'full_name': fullName.trim()})
          .eq('id', _userId)
          .select()
          .single();
      return Profile.fromJson(row);
    } catch (error) {
      throw DataFailure.from(error);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider), userId);
});
