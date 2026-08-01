import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_repository_impl.dart';
import '../domain/group_repository.dart';
import '../presentation/states/edit_group_status.dart';

class EditGroupController extends Notifier<EditGroupStatus> {
  @override
  EditGroupStatus build() => const EditGroupInitial();

  GroupRepository get _repository => ref.read(groupRepositoryProvider);

  Future<void> update({
    required String id,
    required String name,
    String? description,
    String? photoUrl,
  }) async {
    state = const EditGroupSaving();
    try {
      final group = await _repository.update(
        id: id,
        name: name,
        description: description,
        photoUrl: photoUrl,
      );
      state = EditGroupSaveSuccess(group);
    } on GroupRepositoryException catch (e) {
      state = EditGroupError(e.message);
    } catch (_) {
      state = const EditGroupError('Não foi possível salvar o grupo.');
    }
  }
}

final editGroupControllerProvider =
    NotifierProvider<EditGroupController, EditGroupStatus>(
      EditGroupController.new,
    );
