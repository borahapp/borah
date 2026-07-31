import 'group.dart';

/// Erro traduzido pela camada de dados - mesmo padrao de
/// `RestaurantRepositoryException`/`AuthRepositoryException` (nenhuma
/// classe base comum existe no projeto; cada feature define a sua).
class GroupRepositoryException implements Exception {
  const GroupRepositoryException(this.message);

  final String message;
}

/// Contrato do dominio, independente de Flutter e Supabase (AR-02).
/// `create`/`listMine` nesta sprint (GROUP-02A/GROUP-02B.0) -
/// entrar/detalhar ficam para as proximas etapas do modulo Groups.
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
}
