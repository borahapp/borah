import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/data/group_repository_impl.dart';
import '../../groups/domain/group.dart';
import '../../groups/domain/group_repository.dart';
import '../presentation/states/featured_groups_status.dart';

/// "Grupos em destaque" (FASE SOCIAL 3, Pesquisa/Explorar) - só grupos
/// `public`, ordenados por `member_count`/`last_activity_at`
/// (`GroupRepository.listFeatured`, sem algoritmo). Paginação real (não
/// a técnica de "aumentar o limite" de `DiscoveryController`) - aqui é
/// uma única consulta determinística, não fontes heurísticas
/// combinadas, então acumular por página funciona normalmente, mesmo
/// padrão de `FollowListController`.
class FeaturedGroupsController extends Notifier<FeaturedGroupsStatus> {
  @override
  FeaturedGroupsStatus build() => const FeaturedGroupsInitial();

  GroupRepository get _repository => ref.read(groupRepositoryProvider);

  static const _limit = 10;
  int _page = 1;
  int _requestId = 0;

  Future<void> load() {
    _page = 1;
    return _run(const FeaturedGroupsLoading(), requestId: ++_requestId);
  }

  Future<void> loadMore() {
    final current = state;
    if (current is! FeaturedGroupsLoaded || !current.hasMore) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.groups,
      requestId: ++_requestId,
    );
  }

  Future<void> _run(
    FeaturedGroupsStatus loadingState, {
    List<Group> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listFeatured(page: _page, limit: _limit);
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const FeaturedGroupsEmpty()
          : FeaturedGroupsLoaded(items, hasMore: result.hasNextPage);
    } on GroupRepositoryException catch (e) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = FeaturedGroupsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const FeaturedGroupsError(
        'Não foi possível carregar grupos em destaque.',
      );
    }
  }
}

final featuredGroupsControllerProvider =
    NotifierProvider<FeaturedGroupsController, FeaturedGroupsStatus>(
      FeaturedGroupsController.new,
    );
