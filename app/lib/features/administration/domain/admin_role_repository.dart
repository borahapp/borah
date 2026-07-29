import '../../../core/models/paged_result.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class AdminRoleRepositoryException implements Exception {
  const AdminRoleRepositoryException(this.message);

  final String message;
}

/// Papel administrativo de um usuário, com nome para exibição (DV-08 §3).
/// `fullName` nulo indica que o perfil não pôde ser resolvido (mesma
/// tolerância usada em `FollowerRepositoryImpl`).
class AdminRoleEntry {
  const AdminRoleEntry({
    required this.userId,
    required this.role,
    this.fullName,
  });

  final String userId;
  final String role;
  final String? fullName;
}

/// Contrato do domínio de RBAC (DV-08). Concessão/revogação de papéis é
/// autorizada por RLS (somente `super_admin`), não verificada aqui - uma
/// tentativa sem permissão chega como `AdminRoleRepositoryException`.
abstract interface class AdminRoleRepository {
  Future<String?> getRole(String userId);

  Future<PagedResult<AdminRoleEntry>> listAdmins({
    required int page,
    required int limit,
  });

  Future<void> grantRole(String userId, String role);

  Future<void> revokeRole(String userId);
}
