import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gamification_repository_impl.dart';
import '../domain/gamification_repository.dart';
import '../presentation/states/ranking_users_status.dart';

/// Ranking de Usuários (DV-10 §5): Global e Entre Amigos via um único
/// método parametrizado, mesmo padrão do `FollowListController` (DV-07).
class RankingUsersController extends Notifier<RankingUsersStatus> {
  @override
  RankingUsersStatus build() => const RankingUsersInitial();

  GamificationRepository get _repository =>
      ref.read(gamificationRepositoryProvider);

  String? _userId;
  RankingUsersType _type = RankingUsersType.global;
  int _page = 1;
  static const _limit = 20;

  Future<void> load(String userId, RankingUsersType type) {
    _userId = userId;
    _type = type;
    _page = 1;
    return _run();
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! RankingUsersLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run();
  }

  Future<void> _run() async {
    state = const RankingUsersLoading();
    try {
      final result = _type == RankingUsersType.global
          ? await _repository.listGlobalRanking(page: _page, limit: _limit)
          : await _repository.listFriendsRanking(
              _userId!,
              page: _page,
              limit: _limit,
            );
      state = result.items.isEmpty
          ? const RankingUsersEmpty()
          : RankingUsersLoaded(result);
    } on GamificationRepositoryException catch (e) {
      state = RankingUsersError(e.message);
    } catch (_) {
      state = const RankingUsersError('Não foi possível carregar o ranking.');
    }
  }
}

final rankingUsersControllerProvider =
    NotifierProvider<RankingUsersController, RankingUsersStatus>(
      RankingUsersController.new,
    );
