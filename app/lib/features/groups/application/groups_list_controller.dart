import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_repository_impl.dart';
import '../domain/group_repository.dart';
import '../presentation/states/groups_list_status.dart';

class GroupsListController extends Notifier<GroupsListStatus> {
  @override
  GroupsListStatus build() => const GroupsListInitial();

  GroupRepository get _repository => ref.read(groupRepositoryProvider);

  Future<void> load() async {
    state = const GroupsListLoading();
    try {
      final groups = await _repository.listMine();
      state = groups.isEmpty
          ? const GroupsListEmpty()
          : GroupsListLoaded(groups);
    } on GroupRepositoryException catch (e) {
      state = GroupsListError(e.message);
    } catch (_) {
      state = const GroupsListError('Não foi possível carregar seus grupos.');
    }
  }
}

final groupsListControllerProvider =
    NotifierProvider<GroupsListController, GroupsListStatus>(
      GroupsListController.new,
    );
