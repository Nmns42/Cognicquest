import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/providers/auth_provider.dart';
import '../metacognition/data/metacognition_repository.dart';
import 'consent.dart';

/// Envoie au serveur la preuve des décisions de consentement (table
/// `consents`, ajout seul) et termine l'effacement serveur des données de
/// bien-être après un retrait fait hors ligne.
///
/// Module du `SyncCoordinator`, lancé avant les autres : une purge en
/// attente passe avant tout nouvel envoi.
class ConsentSync {
  ConsentSync({
    required SupabaseClient client,
    required String userId,
    required ConsentStore store,
    MetacognitionRepository? metacognition,
  })  : _client = client,
        _userId = userId,
        _store = store,
        _metacognition = metacognition;

  final SupabaseClient _client;
  final String _userId;
  final ConsentStore _store;
  final MetacognitionRepository? _metacognition;

  static const String _table = 'consents';

  Future<void> sync() async {
    if (await _store.purgeUser() == _userId) {
      await _metacognition?.purgeRemoteWellbeing();
      await _store.setPurgeUser(null);
    }

    // Décisions de ce compte, ou prises au bandeau avant connexion.
    final mine = [
      for (final r in await _store.pending())
        if (r.userId == null || r.userId == _userId) r,
    ];
    if (mine.isEmpty) return;
    await _client.from(_table).insert([
      for (final r in mine)
        {
          'user_id': _userId,
          'version': r.version,
          'wellbeing': r.wellbeing,
          'decided_at': r.decidedAt.toUtc().toIso8601String(),
        },
    ]);
    await _store.removePending(mine);
  }
}

/// `null` sans vraie session (déconnecté ou mode démo) : rien à envoyer.
final consentSyncProvider = Provider<ConsentSync?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ConsentSync(
    client: ref.watch(supabaseClientProvider),
    userId: user.id,
    store: ref.watch(consentStoreProvider),
    metacognition: ref.watch(metacognitionRepositoryProvider),
  );
});
