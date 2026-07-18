/// Entidade de perfil (DV-02 §9) — modelo de dados real do módulo,
/// diferente do AuthUserData mínimo do DV-01.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.bio,
    required this.avatarUrl,
    required this.city,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final String? city;
  final String? state;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? city,
    String? state,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
