import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../users/data/user_profile_repository_impl.dart';
import '../../users/domain/user_profile_repository.dart';
import '../presentation/states/admin_users_status.dart';

/// Gestão de Usuários (DV-08 §6) - apenas "Consultar" ("Visualizar
/// histórico" reaproveita `UserReviewsController` do DV-07 na tela de
/// detalhe). "Bloquear/Reativar" fora de escopo (decisão do DV-08).
class AdminUsersController extends Notifier<AdminUsersStatus> {
  @override
  AdminUsersStatus build() => const AdminUsersInitial();

  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  int _page = 1;
  String? _query;
  static const _limit = 20;

  Future<void> load({String? query}) {
    _query = query;
    _page = 1;
    return _run();
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! AdminUsersLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run();
  }

  Future<void> _run() async {
    state = const AdminUsersLoading();
    try {
      final result = await _repository.listAll(
        query: _query,
        page: _page,
        limit: _limit,
      );
      state = result.items.isEmpty
          ? const AdminUsersEmpty()
          : AdminUsersLoaded(result);
    } on UserProfileRepositoryException catch (e) {
      state = AdminUsersError(e.message);
    } catch (_) {
      state = const AdminUsersError('Não foi possível carregar os usuários.');
    }
  }
}

final adminUsersControllerProvider =
    NotifierProvider<AdminUsersController, AdminUsersStatus>(
      AdminUsersController.new,
    );
