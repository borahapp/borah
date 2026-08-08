import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/paged_result.dart';
import '../../restaurants/data/restaurant_repository_impl.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../restaurants/domain/restaurant_repository.dart';
import '../data/audit_log_repository_impl.dart';
import '../domain/audit_log_repository.dart';
import '../presentation/states/admin_restaurants_status.dart';

/// Gestão de Restaurantes (DV-08 §6): editar/arquivar/reativar restaurantes
/// já existentes. "Aprovar cadastro" e "Gerenciar categorias" fora de
/// escopo (decisão do DV-08).
class AdminRestaurantsController extends Notifier<AdminRestaurantsStatus> {
  @override
  AdminRestaurantsStatus build() => const AdminRestaurantsInitial();

  RestaurantRepository get _restaurantRepository =>
      ref.read(restaurantRepositoryProvider);
  AuditLogRepository get _auditLogRepository =>
      ref.read(auditLogRepositoryProvider);

  int _page = 1;
  int _requestId = 0;
  String? _query;
  static const _limit = 20;

  Future<void> load({String? query}) {
    _query = query;
    _page = 1;
    return _run(const AdminRestaurantsLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! AdminRestaurantsLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  Future<void> updateStatus(
    String restaurantId, {
    required String status,
    required String actorId,
  }) async {
    // Reivindica a geração antes de qualquer `await`: enquanto a mutação
    // está em voo, um `loadNextPage` concorrente (scroll perto do fim)
    // reconhece que uma operação mais nova assumiu e descarta sua própria
    // resposta em vez de sobrescrever `Saving`/o resultado desta mutação.
    final requestId = ++_requestId;
    final current = state;
    if (current is AdminRestaurantsLoaded) {
      state = AdminRestaurantsSaving(current.result);
    }
    try {
      await _restaurantRepository.updateAsAdmin(restaurantId, status: status);
      try {
        await _auditLogRepository.log(
          actorId: actorId,
          action: status == 'archived'
              ? 'archive_restaurant'
              : 'reactivate_restaurant',
          entity: 'restaurant',
          entityId: restaurantId,
          metadata: {'status': status},
        );
      } catch (e, stackTrace) {
        // FASE C.2.2: best-effort - a ação principal (linha acima) já foi
        // persistida; uma falha só no registro de auditoria não pode
        // fazer a operação inteira parecer um erro para quem está
        // administrando (seria induzido a repetir algo que já
        // aconteceu). Mesmo padrão de
        // `AccountDeletionController.deleteAccount` - "best-effort não é
        // sinônimo de silencioso".
        AppLogger.warning(
          'Falha ao registrar auditoria de atualização de status de '
          'restaurante.',
          tag: 'administration/AdminRestaurantsController.updateStatus',
          error: e,
          stackTrace: stackTrace,
        );
      }
      // Se uma operação mais nova já assumiu enquanto a mutação estava em
      // voo, a mutação em si já foi persistida (efeito real, sempre
      // executado) - só o refresh de tela é descartado, para não
      // sobrescrever um estado mais recente com uma página 1 desatualizada.
      if (requestId != _requestId) return;
      // Volta para a página 1: mesma simplificação de
      // `NotificationsController.markAsRead` - re-buscar cada página já
      // acumulada individualmente para preservar 1 item editado não vale
      // a complexidade.
      _page = 1;
      await _run(const AdminRestaurantsLoading(), requestId: requestId);
    } on RestaurantRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = AdminRestaurantsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = const AdminRestaurantsError(
        'Não foi possível atualizar o restaurante.',
      );
    }
  }

  /// [requestId] coordena chamadas concorrentes (`loadNextPage`,
  /// `updateStatus`, `load`): só a escrita cujo `requestId` ainda bate com
  /// `_requestId` no momento em que o fetch resolve é aplicada - uma
  /// resposta mais antiga que chega depois de uma chamada mais nova já ter
  /// assumido é descartada silenciosamente.
  Future<void> _run(
    AdminRestaurantsStatus loadingState, {
    List<Restaurant> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _restaurantRepository.listAllForAdmin(
        query: _query,
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const AdminRestaurantsEmpty()
          : AdminRestaurantsLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on RestaurantRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      // Reverte `_page`: a página que falhou nunca chegou a ser aplicada,
      // então a próxima tentativa deve rebuscá-la, em vez de pular para a
      // seguinte.
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = AdminRestaurantsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const AdminRestaurantsError(
        'Não foi possível carregar os restaurantes.',
      );
    }
  }
}

final adminRestaurantsControllerProvider =
    NotifierProvider<AdminRestaurantsController, AdminRestaurantsStatus>(
      AdminRestaurantsController.new,
    );
