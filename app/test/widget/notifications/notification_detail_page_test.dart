import 'package:app/features/notifications/data/notification_repository_impl.dart';
import 'package:app/features/notifications/domain/app_notification.dart';
import 'package:app/features/notifications/domain/notification_repository.dart';
import 'package:app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

AppNotification _notification({
  required String type,
  Map<String, dynamic>? payload,
  bool isRead = true,
}) {
  return AppNotification(
    id: 'n-1',
    userId: 'user-1',
    type: type,
    title: 'Avaliação liberada',
    message: 'A avaliação coletiva já pode ser enviada.',
    payload: payload,
    isRead: isRead,
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  AppNotification notification,
  MockNotificationRepository repository,
) {
  final router = GoRouter(
    initialLocation: '/notification',
    routes: [
      GoRoute(
        path: '/notification',
        builder: (_, _) => NotificationDetailPage(notification: notification),
      ),
      GoRoute(
        path: '/groups/:groupId/events/:eventId',
        builder: (context, state) => Scaffold(
          body: Text(
            'Detalhe do rolê ${state.pathParameters['eventId']} do grupo '
            '${state.pathParameters['groupId']}',
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockNotificationRepository repository;

  setUp(() {
    repository = MockNotificationRepository();
    when(() => repository.markAsRead(any())).thenAnswer((_) async {});
  });

  testWidgets(
    'FASE C.4 - event_review_open: tocar em "Ver" navega para o Detalhe '
    'do rolê (mesmo destino de new_event/event_attendance_response)',
    (tester) async {
      final notification = _notification(
        type: 'event_review_open',
        payload: {'event_id': 'e-1', 'group_id': 'g-1'},
      );

      await tester.pumpWidget(_wrap(notification, repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhe do rolê e-1 do grupo g-1'), findsOneWidget);
    },
  );

  testWidgets(
    'event_review_open sem group_id/event_id no payload: "Ver" não navega '
    'nem lança',
    (tester) async {
      final notification = _notification(
        type: 'event_review_open',
        payload: const {},
      );

      await tester.pumpWidget(_wrap(notification, repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ver'), findsOneWidget);
    },
  );
}
