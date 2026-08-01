import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_ranking_repository_impl.dart';
import '../domain/group_ranking_repository.dart';
import '../presentation/states/group_ranking_status.dart';

class GroupRankingController extends Notifier<GroupRankingStatus> {
  @override
  GroupRankingStatus build() => const GroupRankingInitial();

  GroupRankingRepository get _repository => ref.read(groupRankingRepositoryProvider);

  Future<void> load(String groupId) async {
    state = const GroupRankingLoading();
    try {
      final entries = await _repository.listByGroup(groupId);
      state = GroupRankingLoaded(entries);
    } on GroupRankingRepositoryException catch (e) {
      state = GroupRankingError(e.message);
    } catch (_) {
      state = const GroupRankingError('Não foi possível carregar o ranking.');
    }
  }
}

final groupRankingControllerProvider =
    NotifierProvider<GroupRankingController, GroupRankingStatus>(
      GroupRankingController.new,
    );
