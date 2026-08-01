import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_repository_impl.dart';
import '../domain/group_repository.dart';
import '../presentation/states/join_group_status.dart';

class JoinGroupController extends Notifier<JoinGroupStatus> {
  @override
  JoinGroupStatus build() => const JoinGroupInitial();

  GroupRepository get _repository => ref.read(groupRepositoryProvider);

  Future<void> join(String inviteCode) async {
    state = const JoinGroupSaving();
    try {
      final group = await _repository.joinByInviteCode(inviteCode);
      state = JoinGroupSaveSuccess(group);
    } on GroupRepositoryException catch (e) {
      state = JoinGroupError(e.message);
    } catch (_) {
      state = const JoinGroupError('Não foi possível entrar no grupo.');
    }
  }
}

final joinGroupControllerProvider =
    NotifierProvider<JoinGroupController, JoinGroupStatus>(
      JoinGroupController.new,
    );
