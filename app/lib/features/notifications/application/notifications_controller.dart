import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../data/notification_repository_impl.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';
import '../presentation/states/notifications_status.dart';

/// Fluxo simples NotificationRepository -> Controller (mesmo padrão do
/// DV-01 em diante), sem use cases intermediários. Nunca cria uma
/// notificação - só lista e marca como lida (decisão 4 do DV-09).
class NotificationsController extends Notifier<NotificationsStatus> {
  @override
  NotificationsStatus build() => const NotificationsInitial();

  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  String? _userId;
  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> loadForUser(String userId) {
    _userId = userId;
    _page = 1;
    return _run(const NotificationsLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! NotificationsLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  Future<void> markAsRead(String id) async {
    // Reivindica a geração antes de qualquer `await` (mesmo mecanismo de
    // `AdminRestaurantsController.updateStatus`).
    final requestId = ++_requestId;
    try {
      await _repository.markAsRead(id);
      if (requestId != _requestId) return;
      // Volta para a página 1: manter a lista acumulada e só trocar o
      // status de leitura de 1 item exigiria re-buscar cada página já
      // carregada individualmente - mesma simplificação já aplicada em
      // `markAllAsRead`.
      _page = 1;
      await _run(const NotificationsLoading(), requestId: requestId);
    } on NotificationRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = NotificationsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = const NotificationsError('Não foi possível marcar como lida.');
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    final requestId = ++_requestId;
    try {
      await _repository.markAllAsRead(_userId!);
      if (requestId != _requestId) return;
      _page = 1;
      await _run(const NotificationsLoading(), requestId: requestId);
    } on NotificationRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = NotificationsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = const NotificationsError(
        'Não foi possível marcar todas como lidas.',
      );
    }
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `AdminRestaurantsController._run`).
  Future<void> _run(
    NotificationsStatus loadingState, {
    List<AppNotification> previousItems = const [],
    required int requestId,
  }) async {
    if (_userId == null) return;
    state = loadingState;
    try {
      final result = await _repository.listForUser(
        _userId!,
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const NotificationsEmpty()
          : NotificationsLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on NotificationRepositoryException catch (e) {
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
      state = NotificationsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const NotificationsError(
        'Não foi possível carregar as notificações.',
      );
    }
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsStatus>(
      NotificationsController.new,
    );
