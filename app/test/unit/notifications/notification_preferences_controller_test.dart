import 'package:app/features/notifications/application/notification_preferences_controller.dart';
import 'package:app/features/notifications/data/notification_preference_repository_impl.dart';
import 'package:app/features/notifications/domain/notification_preference_repository.dart';
import 'package:app/features/notifications/presentation/states/notification_preferences_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationPreferenceRepository extends Mock
    implements NotificationPreferenceRepository {}

void main() {
  late MockNotificationPreferenceRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockNotificationPreferenceRepository();
    container = ProviderContainer(
      overrides: [
        notificationPreferenceRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é NotificationPreferencesInitial', () {
    expect(
      container.read(notificationPreferencesControllerProvider),
      isA<NotificationPreferencesInitial>(),
    );
  });

  test('load sucesso -> NotificationPreferencesLoaded', () async {
    when(
      () => repository.isInAppEnabled('user-1'),
    ).thenAnswer((_) async => true);

    await container
        .read(notificationPreferencesControllerProvider.notifier)
        .load('user-1');

    final status = container.read(notificationPreferencesControllerProvider);
    expect(status, isA<NotificationPreferencesLoaded>());
    expect((status as NotificationPreferencesLoaded).inAppEnabled, isTrue);
  });

  test('load falha -> NotificationPreferencesError', () async {
    when(
      () => repository.isInAppEnabled('user-1'),
    ).thenThrow(const NotificationPreferenceRepositoryException('Falha.'));

    await container
        .read(notificationPreferencesControllerProvider.notifier)
        .load('user-1');

    expect(
      container.read(notificationPreferencesControllerProvider),
      isA<NotificationPreferencesError>(),
    );
  });

  test('toggle alterna o valor', () async {
    when(
      () => repository.isInAppEnabled('user-1'),
    ).thenAnswer((_) async => true);
    when(
      () => repository.setInAppEnabled('user-1', false),
    ).thenAnswer((_) async {});

    final notifier = container.read(
      notificationPreferencesControllerProvider.notifier,
    );
    await notifier.load('user-1');
    await notifier.toggle('user-1');

    final status = container.read(notificationPreferencesControllerProvider);
    expect(status, isA<NotificationPreferencesLoaded>());
    expect((status as NotificationPreferencesLoaded).inAppEnabled, isFalse);
    verify(() => repository.setInAppEnabled('user-1', false)).called(1);
  });
}
