import '../../../events/domain/event.dart';
import '../../../groups/domain/group.dart';

/// Estado da nova Home (FASE 01 da simplificação de produto) - sealed
/// class, mesmo shape de `GroupsListStatus`/`EventsListStatus`. Sem
/// paginação - `listMine()` não pagina, mesma decisão já tomada para
/// `GroupsListStatus`.
sealed class HomeStatus {
  const HomeStatus();
}

final class HomeInitial extends HomeStatus {
  const HomeInitial();
}

final class HomeLoading extends HomeStatus {
  const HomeLoading();
}

final class HomeLoaded extends HomeStatus {
  const HomeLoaded({required this.groups, this.heroEvent, this.heroEventGroup});

  /// Todos os grupos do usuário (seção "Meus grupos").
  final List<Group> groups;

  /// O rolê agendado mais próximo entre todos os grupos, já com dados
  /// completos de restaurante (via `EventRepository.getById`) - `null`
  /// quando nenhum grupo tem `nextEvent`. Deliberadamente só o mais
  /// próximo (não uma lista) - ver doc do `HomeController.load`.
  final Event? heroEvent;

  /// Grupo ao qual [heroEvent] pertence - necessário para o rótulo e
  /// para montar a rota de detalhe (`/groups/:groupId/events/:eventId`).
  /// Sempre não-nulo quando [heroEvent] não é nulo, e vice-versa.
  final Group? heroEventGroup;
}

final class HomeError extends HomeStatus {
  const HomeError(this.message);

  final String message;
}
