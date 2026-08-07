import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../../users/data/user_profile_repository_impl.dart';
import '../../users/domain/user_profile.dart';
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
  int _requestId = 0;
  String? _query;
  static const _limit = 20;

  Future<void> load({String? query}) {
    _query = query;
    _page = 1;
    return _run(const AdminUsersLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! AdminUsersLoaded || !current.result.hasNextPage) {
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
  /// `state` - evita que um `loadNextPage` disparado durante uma nova
  /// busca (`_search`) produza um resultado final inconsistente, qualquer
  /// que seja a ordem das respostas.
  Future<void> _run(
    AdminUsersStatus loadingState, {
    List<UserProfile> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listAll(
        query: _query,
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const AdminUsersEmpty()
          : AdminUsersLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on UserProfileRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      if (previousItems.isNotEmpty) return;
      state = AdminUsersError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) return;
      state = const AdminUsersError('Não foi possível carregar os usuários.');
    }
  }
}

final adminUsersControllerProvider =
    NotifierProvider<AdminUsersController, AdminUsersStatus>(
      AdminUsersController.new,
    );
