/// Entidade de perfil (DV-02 §9) — modelo de dados real do módulo,
/// diferente do AuthUserData mínimo do DV-01.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.city,
    required this.state,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? fullName;

  /// FASE SOCIAL 2 - `profiles.username`, nullable (contas antigas
  /// continuam sem username), único por comparação case-insensitive
  /// (`profiles_username_unique_idx`, sobre `lower(username)`).
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final String? city;
  final String? state;

  /// FASE SOCIAL 2 - mantidos por trigger em `followers`
  /// (`adjust_follow_counters`), nunca por `count()` em tempo de
  /// leitura. Somente leitura do lado do cliente - nenhum método deste
  /// domínio permite escrevê-los.
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? city,
    String? state,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      state: state ?? this.state,
      followersCount: followersCount,
      followingCount: followingCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
