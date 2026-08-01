import 'group.dart';
import 'group_details.dart';

/// Erro traduzido pela camada de dados - mesmo padrao de
/// `RestaurantRepositoryException`/`AuthRepositoryException` (nenhuma
/// classe base comum existe no projeto; cada feature define a sua).
class GroupRepositoryException implements Exception {
  const GroupRepositoryException(this.message);

  final String message;
}

/// Contrato do dominio, independente de Flutter e Supabase (AR-02).
/// `create` (GROUP-02A), `listMine` (GROUP-02B.0), `getById`
/// (GROUP-02B.1) e `joinByInviteCode` (ONBOARDING-01).
abstract interface class GroupRepository {
  Future<Group> create({
    required String name,
    String? description,
    String? photoUrl,
  });

  /// Grupos dos quais o usuário autenticado é membro, ordenados por
  /// atividade mais recente primeiro. Sem parâmetro de usuário - a RLS
  /// (`groups_select_members`, GROUP-01) já restringe o `SELECT` aos
  /// grupos de `auth.uid()`, então nenhuma cláusula adicional é
  /// necessária no cliente.
  Future<List<Group>> listMine();

  /// Grupo + membros (GROUP-02B.1). Lança [GroupRepositoryException] se
  /// o grupo não existir ou o usuário não for membro (a RLS de
  /// `groups`/`group_members` filtra antes disso).
  Future<GroupDetails> getById(String id);

  /// Entra em um grupo pelo código de convite (ONBOARDING-01). Se o
  /// usuário já for membro, `join_group_by_invite_code()` só retorna o
  /// grupo sem erro (idempotente - `on conflict do nothing`, GROUP-01) -
  /// não há um caso de "já é membro" para tratar aqui.
  Future<Group> joinByInviteCode(String inviteCode);
}
