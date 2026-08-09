import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../../notifications/data/notification_repository_impl.dart';
import '../../notifications/domain/app_notification.dart';
import '../../notifications/domain/notification_repository.dart';
import '../presentation/states/group_activity_feed_status.dart';

/// RC-03 F25 - aba "Atividade" de `GroupHubPage`. Mesmo padrão de
/// paginação-com-acumulação de `NotificationsController`, sem
/// `markAsRead`/`markAllAsRead` (não fazem sentido aqui - ver doc-comment
/// de `NotificationRepository.listGroupActivity`).
class GroupActivityFeedController extends Notifier<GroupActivityFeedStatus> {
  @override
  GroupActivityFeedStatus build() => const GroupActivityFeedInitial();

  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  String? _groupId;
  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> loadForGroup(String groupId) {
    _groupId = groupId;
    _page = 1;
    return _run(const GroupActivityFeedLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (_groupId == null ||
        current is! GroupActivityFeedLoaded ||
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

  Future<void> _run(
    GroupActivityFeedStatus loadingState, {
    List<AppNotification> previousItems = const [],
    required int requestId,
  }) async {
    if (_groupId == null) return;
    state = loadingState;
    try {
      final result = await _repository.listGroupActivity(
        _groupId!,
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const GroupActivityFeedEmpty()
          : GroupActivityFeedLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on NotificationRepositoryException catch (e) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = GroupActivityFeedError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const GroupActivityFeedError(
        'Não foi possível carregar a atividade do grupo.',
      );
    }
  }
}

final groupActivityFeedControllerProvider =
    NotifierProvider<GroupActivityFeedController, GroupActivityFeedStatus>(
      GroupActivityFeedController.new,
    );
