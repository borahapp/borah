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
/// `create` (GROUP-02A), `listMine` (GROUP-02B.0) e `getById`
/// (GROUP-02B.1) - entrar em um grupo por convite continua exposto só
/// via `join_group_by_invite_code()` no backend (GROUP-01); nenhuma
/// tela chama isso ainda.
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
}
