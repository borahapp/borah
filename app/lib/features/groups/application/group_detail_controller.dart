import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_repository_impl.dart';
import '../domain/group_repository.dart';
import '../presentation/states/group_detail_status.dart';

class GroupDetailController extends Notifier<GroupDetailStatus> {
  @override
  GroupDetailStatus build() => const GroupDetailInitial();

  GroupRepository get _repository => ref.read(groupRepositoryProvider);

  Future<void> load(String id) async {
    state = const GroupDetailLoading();
    try {
      final details = await _repository.getById(id);
      state = GroupDetailLoaded(details);
    } on GroupRepositoryException catch (e) {
      state = GroupDetailError(e.message);
    } catch (_) {
      state = const GroupDetailError('Não foi possível carregar o grupo.');
    }
  }

  /// GROUP-02B.1: prepara o texto do convite - a página só dispara o
  /// compartilhamento nativo (`Share.share`), não decide o conteúdo.
  /// Retorna `null` se não houver grupo carregado (a página só oferece
  /// o botão de compartilhar quando o estado já é `GroupDetailLoaded`,
  /// então isso é só uma proteção defensiva).
  String? buildInviteShareMessage() {
    final current = state;
    if (current is! GroupDetailLoaded) return null;

    final group = current.details.group;
    return 'Entre no meu grupo "${group.name}" no BORAH! '
        'Use o código de convite: ${group.inviteCode}';
  }
}

final groupDetailControllerProvider =
    NotifierProvider<GroupDetailController, GroupDetailStatus>(
      GroupDetailController.new,
    );
