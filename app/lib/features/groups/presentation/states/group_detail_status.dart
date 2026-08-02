import '../../domain/group_details.dart';

/// Estado do Detalhe do Grupo (GROUP-02B.1), sealed class - mesmo
/// padrão de `RestaurantDetailStatus`/`ReviewDetailStatus`.
sealed class GroupDetailStatus {
  const GroupDetailStatus();
}

final class GroupDetailInitial extends GroupDetailStatus {
  const GroupDetailInitial();
}

final class GroupDetailLoading extends GroupDetailStatus {
  const GroupDetailLoading();
}

final class GroupDetailLoaded extends GroupDetailStatus {
  const GroupDetailLoaded(this.details);

  final GroupDetails details;
}

/// Carrega os detalhes (se já havia algum carregado) junto do erro -
/// mesmo padrão de `EventDetailError` (ROLÊ-03): uma falha ao
/// promover/remover/sair (BLOCO 2) não deve derrubar a tela inteira
/// para um erro de página cheia, já que o grupo continua carregado -
/// só a ação falhou. `details` só é `null` quando o próprio `load()`
/// inicial falha (nenhum grupo jamais foi carregado).
final class GroupDetailError extends GroupDetailStatus {
  const GroupDetailError(this.message, this.details);

  final String message;
  final GroupDetails? details;
}
