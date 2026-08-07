import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _query;
  static const _limit = 20;

  Future<void> load({String? query}) {
    _query = query;
    _page = 1;
    return _run(const AdminRestaurantsLoading());
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! AdminRestaurantsLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(current, previousItems: current.result.items);
  }

  Future<void> updateStatus(
    String restaurantId, {
    required String status,
    required String actorId,
  }) async {
    final current = state;
    if (current is AdminRestaurantsLoaded) {
      state = AdminRestaurantsSaving(current.result);
    }
    try {
      await _restaurantRepository.updateAsAdmin(restaurantId, status: status);
      await _auditLogRepository.log(
        actorId: actorId,
        action: status == 'archived'
            ? 'archive_restaurant'
            : 'reactivate_restaurant',
        entity: 'restaurant',
        entityId: restaurantId,
        metadata: {'status': status},
      );
      // Volta para a página 1: mesma simplificação de
      // `NotificationsController.markAsRead` - re-buscar cada página já
      // acumulada individualmente para preservar 1 item editado não vale
      // a complexidade.
      _page = 1;
      await _run(const AdminRestaurantsLoading());
    } on RestaurantRepositoryException catch (e) {
      state = AdminRestaurantsError(e.message);
    } catch (_) {
      state = const AdminRestaurantsError(
        'Não foi possível atualizar o restaurante.',
      );
    }
  }

  Future<void> _run(
    AdminRestaurantsStatus loadingState, {
    List<Restaurant> previousItems = const [],
  }) async {
    state = loadingState;
    try {
      final result = await _restaurantRepository.listAllForAdmin(
        query: _query,
        page: _page,
        limit: _limit,
      );
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
      state = AdminRestaurantsError(e.message);
    } catch (_) {
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
