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

  /// FASE SOCIAL 3 - entrada instantânea num grupo `public`
  /// (`PublicGroupProfilePage`), sem código de convite. Mesmo
  /// `JoinGroupStatus` de [join] - reutiliza o mesmo controller em vez
  /// de criar um novo, já que o formato do estado (Saving/Success/Error)
  /// é idêntico para as duas formas de entrar num grupo.
  Future<void> joinPublic(String groupId) async {
    state = const JoinGroupSaving();
    try {
      final group = await _repository.joinPublicGroup(groupId);
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
