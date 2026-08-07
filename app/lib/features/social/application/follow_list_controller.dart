import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../../users/domain/user_profile.dart';
import '../data/follower_repository_impl.dart';
import '../domain/follower_repository.dart';
import '../presentation/states/follow_list_status.dart';

/// Lista de seguidores OU seguindo de um usuário (DV-07 §6) - um único
/// controller parametrizado por `FollowListType`, mesmo padrão de
/// consolidar variações de uma mesma consulta em um método (ver
/// `RankingsController`/`FavoritesController`).
class FollowListController extends Notifier<FollowListStatus> {
  @override
  FollowListStatus build() => const FollowListInitial();

  FollowerRepository get _repository => ref.read(followerRepositoryProvider);

  String? _userId;
  FollowListType _type = FollowListType.followers;
  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> load(String userId, FollowListType type) {
    _userId = userId;
    _type = type;
    _page = 1;
    return _run(const FollowListLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! FollowListLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `FeedController._run`): só a resposta cujo `requestId` ainda bate com
  /// `_requestId` no momento em que o fetch resolve pode escrever em
  /// `state` - evita que um `loadNextPage` disparado durante um `load`
  /// produza um resultado final inconsistente, qualquer que seja a ordem
  /// das respostas.
  Future<void> _run(
    FollowListStatus loadingState, {
    List<UserProfile> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = _type == FollowListType.followers
          ? await _repository.listFollowers(
              _userId!,
              page: _page,
              limit: _limit,
            )
          : await _repository.listFollowing(
              _userId!,
              page: _page,
              limit: _limit,
            );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const FollowListEmpty()
          : FollowListLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on FollowerRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      // Reverte `_page`: a página que falhou nunca chegou a ser aplicada,
      // então a próxima tentativa deve rebuscá-la, em vez de pular para a
      // seguinte.
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = FollowListError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const FollowListError('Não foi possível carregar a lista.');
    }
  }
}

final followListControllerProvider =
    NotifierProvider<FollowListController, FollowListStatus>(
      FollowListController.new,
    );
