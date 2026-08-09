import 'package:app/core/models/paged_result.dart';
import 'package:app/features/group_ranking/application/group_activity_feed_controller.dart';
import 'package:app/features/group_ranking/presentation/states/group_activity_feed_status.dart';
import 'package:app/features/notifications/data/notification_repository_impl.dart';
import 'package:app/features/notifications/domain/app_notification.dart';
import 'package:app/features/notifications/domain/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

AppNotification _item({String id = 'n-1'}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    type: 'new_event',
    title: 'Novo rolê',
    message: 'Um novo rolê foi criado: Cantina da Vila',
    payload: const {'group_id': 'g-1'},
    isRead: false,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockNotificationRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockNotificationRepository();
    container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é GroupActivityFeedInitial', () {
    expect(
      container.read(groupActivityFeedControllerProvider),
      isA<GroupActivityFeedInitial>(),
    );
  });

  test('loadForGroup com resultados -> GroupActivityFeedLoaded', () async {
    when(
      () => repository.listGroupActivity('g-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          PagedResult(items: [_item()], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(groupActivityFeedControllerProvider.notifier)
        .loadForGroup('g-1');

    expect(
      container.read(groupActivityFeedControllerProvider),
      isA<GroupActivityFeedLoaded>(),
    );
  });

  test('loadForGroup sem resultados -> GroupActivityFeedEmpty', () async {
    when(
      () => repository.listGroupActivity('g-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(groupActivityFeedControllerProvider.notifier)
        .loadForGroup('g-1');

    expect(
      container.read(groupActivityFeedControllerProvider),
      isA<GroupActivityFeedEmpty>(),
    );
  });

  test('loadForGroup com falha -> GroupActivityFeedError', () async {
    when(
      () => repository.listGroupActivity('g-1', page: 1, limit: 20),
    ).thenThrow(const NotificationRepositoryException('Falha ao carregar.'));

    await container
        .read(groupActivityFeedControllerProvider.notifier)
        .loadForGroup('g-1');

    expect(
      container.read(groupActivityFeedControllerProvider),
      isA<GroupActivityFeedError>(),
    );
  });

  test(
    'loadNextPage concatena os itens da nova página aos já carregados',
    () async {
      when(
        () => repository.listGroupActivity('g-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_item(id: 'n-1')],
          page: 1,
          limit: 20,
          hasNextPage: true,
        ),
      );
      when(
        () => repository.listGroupActivity('g-1', page: 2, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_item(id: 'n-2')],
          page: 2,
          limit: 20,
          hasNextPage: false,
        ),
      );

      final notifier = container.read(
        groupActivityFeedControllerProvider.notifier,
      );
      await notifier.loadForGroup('g-1');
      await notifier.loadNextPage();

      final status = container.read(groupActivityFeedControllerProvider);
      expect(status, isA<GroupActivityFeedLoaded>());
      expect(
        (status as GroupActivityFeedLoaded).result.items.map((n) => n.id),
        ['n-1', 'n-2'],
      );
    },
  );

  test(
    'falha ao buscar a página seguinte preserva os itens já carregados',
    () async {
      when(
        () => repository.listGroupActivity('g-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_item(id: 'n-1')],
          page: 1,
          limit: 20,
          hasNextPage: true,
        ),
      );
      when(
        () => repository.listGroupActivity('g-1', page: 2, limit: 20),
      ).thenThrow(const NotificationRepositoryException('Falha de rede.'));

      final notifier = container.read(
        groupActivityFeedControllerProvider.notifier,
      );
      await notifier.loadForGroup('g-1');
      await notifier.loadNextPage();

      final status = container.read(groupActivityFeedControllerProvider);
      expect(status, isA<GroupActivityFeedLoaded>());
      expect(
        (status as GroupActivityFeedLoaded).result.items.map((n) => n.id),
        ['n-1'],
      );
    },
  );
}
