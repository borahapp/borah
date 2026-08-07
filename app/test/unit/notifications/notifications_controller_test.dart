import 'dart:async';

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

  test('loadNextPage concatena os itens da nova página aos já carregados em '
      'vez de substituir a lista', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_notification(id: 'n-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(() => repository.listForUser('user-1', page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_notification(id: 'n-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(notificationsControllerProvider.notifier);
    await notifier.loadForUser('user-1');
    await notifier.loadNextPage();

    final status = container.read(notificationsControllerProvider);
    expect(status, isA<NotificationsLoaded>());
    expect((status as NotificationsLoaded).result.items.map((n) => n.id), [
      'n-1',
      'n-2',
    ]);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar NotificationsError', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_notification(id: 'n-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => repository.listForUser('user-1', page: 2, limit: 20),
    ).thenThrow(const NotificationRepositoryException('Falha de rede.'));

    final notifier = container.read(notificationsControllerProvider.notifier);
    await notifier.loadForUser('user-1');
    await notifier.loadNextPage();

    final status = container.read(notificationsControllerProvider);
    expect(status, isA<NotificationsLoaded>());
    expect((status as NotificationsLoaded).result.items.map((n) => n.id), [
      'n-1',
    ]);
  });

  test('concorrência entre loadNextPage e markAsRead: a resposta '
      'desatualizada do loadNextPage não sobrescreve o resultado mais '
      'recente da mutação', () async {
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_notification(id: 'n-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(notificationsControllerProvider.notifier);
    await notifier.loadForUser('user-1');

    // loadNextPage (página 2) fica pendente, controlado manualmente.
    final page2Completer = Completer<PagedResult<AppNotification>>();
    when(
      () => repository.listForUser('user-1', page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, a notificação é marcada como lida - markAsRead
    // reseta para a página 1 com o dado já atualizado.
    when(() => repository.markAsRead('n-1')).thenAnswer((_) async {});
    when(() => repository.listForUser('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_notification(id: 'n-1', isRead: true)],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    final markAsReadFuture = notifier.markAsRead('n-1');

    // A resposta da página 2 (mais antiga) chega DEPOIS de markAsRead
    // já ter assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [_notification(id: 'n-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await loadNextPageFuture;
    await markAsReadFuture;

    final status = container.read(notificationsControllerProvider);
    expect(status, isA<NotificationsLoaded>());
    final items = (status as NotificationsLoaded).result.items;
    expect(items.map((n) => n.id), ['n-1']);
    expect(items.single.isRead, isTrue);
  });
}
