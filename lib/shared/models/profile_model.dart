/// Offre souscrite — modèle économique du CdC (freemium B2C, abonnement pro
/// B2B). Sert de base au gating des fonctionnalités premium.
enum UserPlan {
  free('free', 'Gratuit'),
  premium('premium', 'Premium'),
  pro('pro', 'Professionnel');

  const UserPlan(this.value, this.label);

  final String value;
  final String label;

  static UserPlan fromValue(String? value) => switch (value) {
        'premium' => UserPlan.premium,
        'pro' => UserPlan.pro,
        _ => UserPlan.free,
      };
}

/// Profil applicatif adossé à `auth.users` (table `profiles`).
class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.plan = UserPlan.free,
  });

  final String id;
  final String? fullName;
  final String? avatarUrl;
  final UserPlan plan;

  /// Prénom d'affichage. Le Dashboard affichait « Admin » en dur ; on prend
  /// désormais le premier mot du nom complet, avec repli vide plutôt qu'un
  /// placeholder mensonger.
  String get firstName {
    final name = fullName?.trim() ?? '';
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  /// Initiales pour l'avatar, quand aucune image n'est disponible.
  String get initials {
    final name = fullName?.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        plan: UserPlan.fromValue(json['plan'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'avatar_url': avatarUrl,
      };

  Profile copyWith({String? fullName, String? avatarUrl, UserPlan? plan}) =>
      Profile(
        id: id,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        plan: plan ?? this.plan,
      );
}
