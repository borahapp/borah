import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository_impl.dart';
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
  static const _limit = 20;

  Future<void> loadForUser(String userId) {
    _userId = userId;
    _page = 1;
    return _run();
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_userId == null ||
        current is! NotificationsLoaded ||
        !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      await _run();
    } on NotificationRepositoryException catch (e) {
      state = NotificationsError(e.message);
    } catch (_) {
      state = const NotificationsError('Não foi possível marcar como lida.');
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    try {
      await _repository.markAllAsRead(_userId!);
      _page = 1;
      await _run();
    } on NotificationRepositoryException catch (e) {
      state = NotificationsError(e.message);
    } catch (_) {
      state = const NotificationsError(
        'Não foi possível marcar todas como lidas.',
      );
    }
  }

  Future<void> _run() async {
    if (_userId == null) return;
    state = const NotificationsLoading();
    try {
      final result = await _repository.listForUser(
        _userId!,
        page: _page,
        limit: _limit,
      );
      state = result.items.isEmpty
          ? const NotificationsEmpty()
          : NotificationsLoaded(result);
    } on NotificationRepositoryException catch (e) {
      state = NotificationsError(e.message);
    } catch (_) {
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
