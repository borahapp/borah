/// Membro de um grupo (GROUP-02B.1) - dados vêm de `group_members`
/// (`role`) + `profiles` (`fullName`/`avatarUrl`), duas tabelas
/// distintas sem FK direta entre si (mesma limitação já documentada em
/// `FollowerRemoteDatasource` - `group_members.user_id`/`profiles.id`
/// referenciam `auth.users` independentemente, sem relação que o
/// PostgREST possa usar num embed).
class GroupMember {
  const GroupMember({
    required this.id,
    required this.userId,
    required this.role,
    required this.fullName,
    required this.avatarUrl,
  });

  /// `id` de `group_members` (não de `profiles`/`auth.users`) - usado
  /// para promover/remover (BLOCO 2), sempre por `id` da linha, nunca
  /// por `user_id`+`group_id` compostos, mesmo padrão de update/delete
  /// "por id, RLS resolve a permissão" já usado em `event_attendances`.
  final String id;

  final String userId;

  /// Valor real do banco (`owner`/`admin`/`member`, `text + check` -
  /// GROUP-01). Nunca exibido diretamente ao usuário - ver [roleLabel].
  final String role;

  final String? fullName;
  final String? avatarUrl;

  /// Tradução do papel para exibição (PT-BR). O banco continua em
  /// inglês - só a apresentação muda.
  String get roleLabel => switch (role) {
    'owner' => 'Proprietário',
    'admin' => 'Administrador',
    _ => 'Membro',
  };

  bool get isOwner => role == 'owner';
  bool get isAdminOrOwner => role == 'owner' || role == 'admin';
}
