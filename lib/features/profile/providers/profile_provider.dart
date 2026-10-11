import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_repository.dart';

/// Profil de l'utilisateur connecté.
///
/// Remplace le `const firstName = 'Admin'` codé en dur dans le Dashboard.
class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    if (repository == null) return null;
    return repository.fetch();
  }

  Future<void> updateName(String fullName) async {
    final repository = ref.read(profileRepositoryProvider);
    if (repository == null) return;

    final previous = state;
    state = AsyncValue.data(state.valueOrNull?.copyWith(fullName: fullName));
    try {
      state = AsyncValue.data(await repository.updateName(fullName));
    } catch (error, stackTrace) {
      state = AsyncValue<Profile?>.error(error, stackTrace)
          .copyWithPrevious(previous);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(
  ProfileNotifier.new,
);

/// Prénom affiché dans le Dashboard.
///
/// Repli en cascade : nom du profil → métadonnées de la session Google →
/// partie locale de l'email → chaîne vide (l'accueil dit alors simplement
/// « Bonjour ! », sans inventer de nom).
final displayNameProvider = Provider<String>((ref) {
  final profileName = ref.watch(profileProvider).valueOrNull?.firstName ?? '';
  if (profileName.isNotEmpty) return profileName;

  final user = ref.watch(currentUserProvider);
  if (user == null) return '';

  final metadataName = (user.userMetadata?['full_name'] ??
          user.userMetadata?['name']) as String?;
  if (metadataName != null && metadataName.trim().isNotEmpty) {
    return metadataName.trim().split(RegExp(r'\s+')).first;
  }

  final email = user.email ?? '';
  return email.isEmpty ? '' : email.split('@').first;
});
