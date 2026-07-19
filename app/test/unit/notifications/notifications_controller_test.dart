import 'package:app/core/models/paged_result.dart';
import 'package:app/features/notifications/application/notifications_controller.dart';
import 'package:app/features/notifications/data/notification_repository_impl.dart';
import 'package:app/features/notifications/domain/app_notification.dart';
import 'package:app/features/notifications/domain/notification_repository.dart';
import 'package:app/features/notifications/presentation/states/notifications_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

AppNotification _notification({String id = 'n-1', bool isRead = false}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    type: 'new_follower',
    title: 'Novo seguidor',
    message: 'Alguém começou a seguir você.',
    payload: const {'follower_id': 'user-2'},
    isRead: isRead,
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

  test('estado inicial é NotificationsInitial', () {
    expect(
      container.read(notificationsControllerProvider),
      isA<NotificationsInitial>(),
    );
  });

  test('loadForUser com resultados -> NotificationsLoaded', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_notification()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(notificationsControllerProvider.notifier)
        .loadForUser('user-1');

    expect(
      container.read(notificationsControllerProvider),
      isA<NotificationsLoaded>(),
    );
  });

  test('loadForUser sem resultados -> NotificationsEmpty', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(notificationsControllerProvider.notifier)
        .loadForUser('user-1');

    expect(
      container.read(notificationsControllerProvider),
      isA<NotificationsEmpty>(),
    );
  });

  test('loadForUser com falha -> NotificationsError', () async {
    when(
      () => repository.listForUser('user-1', page: 1, limit: 20),
    ).thenThrow(const NotificationRepositoryException('Falha ao carregar.'));

    await container
        .read(notificationsControllerProvider.notifier)
        .loadForUser('user-1');

    expect(
      container.read(notificationsControllerProvider),
      isA<NotificationsError>(),
    );
  });

  test('markAsRead marca e recarrega a lista', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_notification()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(() => repository.markAsRead('n-1')).thenAnswer((_) async {});

    final notifier = container.read(notificationsControllerProvider.notifier);
    await notifier.loadForUser('user-1');
    await notifier.markAsRead('n-1');

    verify(() => repository.markAsRead('n-1')).called(1);
    expect(
      container.read(notificationsControllerProvider),
      isA<NotificationsLoaded>(),
    );
  });

  test('markAllAsRead chama o repositório e recarrega', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    when(() => repository.markAllAsRead('user-1')).thenAnswer((_) async {});

    final notifier = container.read(notificationsControllerProvider.notifier);
    await notifier.loadForUser('user-1');
    await notifier.markAllAsRead();

    verify(() => repository.markAllAsRead('user-1')).called(1);
  });
}
