import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_repository_impl.dart';
import '../domain/group_repository.dart';
import '../presentation/states/create_group_status.dart';

class CreateGroupController extends Notifier<CreateGroupStatus> {
  @override
  CreateGroupStatus build() => const CreateGroupInitial();

  GroupRepository get _repository => ref.read(groupRepositoryProvider);

  Future<void> create({
    required String name,
    String? description,
    String? photoUrl,
  }) async {
    state = const CreateGroupSaving();
    try {
      final group = await _repository.create(
        name: name,
        description: description,
        photoUrl: photoUrl,
      );
      state = CreateGroupSaveSuccess(group);
    } on GroupRepositoryException catch (e) {
      state = CreateGroupError(e.message);
    } catch (_) {
      state = const CreateGroupError('Não foi possível criar o grupo.');
    }
  }
}

final createGroupControllerProvider =
    NotifierProvider<CreateGroupController, CreateGroupStatus>(
      CreateGroupController.new,
    );
