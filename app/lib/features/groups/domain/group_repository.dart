import 'group.dart';

/// Erro traduzido pela camada de dados - mesmo padrao de
/// `RestaurantRepositoryException`/`AuthRepositoryException` (nenhuma
/// classe base comum existe no projeto; cada feature define a sua).
class GroupRepositoryException implements Exception {
  const GroupRepositoryException(this.message);

  final String message;
}

/// Contrato do dominio, independente de Flutter e Supabase (AR-02).
/// Apenas `create` nesta sprint (GROUP-02A) - listar/entrar/detalhar
/// ficam para as proximas etapas do modulo Groups.
abstract interface class GroupRepository {
  Future<Group> create({
    required String name,
    String? description,
    String? photoUrl,
  });
}
