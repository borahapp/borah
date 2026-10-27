import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/notifications/application/unread_notifications_count_provider.dart';
import 'package:app/features/notifications/data/notification_repository_impl.dart';
import 'package:app/features/notifications/domain/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockNotificationRepository repository;

  setUp(() {
    repository = MockNotificationRepository();
  });

  test(
    'sem usuário autenticado, retorna 0 sem consultar o repositório - '
    'nunca expõe a contagem de uma sessão anterior após logout',
    () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(
        unreadNotificationsCountProvider.future,
      );

      expect(count, 0);
      verifyNever(() => repository.countUnread(any()));
    },
  );

  test(
    'com usuário autenticado, delega ao repositório pelo userId correto',
    () async {
      when(
        () => repository.countUnread('user-1'),
      ).thenAnswer((_) async => 4);
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(
        unreadNotificationsCountProvider.future,
      );

      expect(count, 4);
      verify(() => repository.countUnread('user-1')).called(1);
    },
  );

  test(
    'troca de usuário (ex.: logout -> login com outra conta) recalcula a '
    'contagem para o novo usuário, nunca mistura com a anterior',
    () async {
      when(
        () => repository.countUnread('user-1'),
      ).thenAnswer((_) async => 9);
      when(
        () => repository.countUnread('user-2'),
      ).thenAnswer((_) async => 1);

      final authState = StateProvider<String?>((ref) => 'user-1');
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWith((ref) => ref.watch(authState)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(unreadNotificationsCountProvider.future),
        9,
      );

      container.read(authState.notifier).state = 'user-2';

      expect(
        await container.read(unreadNotificationsCountProvider.future),
        1,
      );
    },
  );
}
