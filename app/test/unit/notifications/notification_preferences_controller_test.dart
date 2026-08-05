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

  test(
    'load sucesso -> NotificationPreferencesLoaded com as 2 categorias',
    () async {
      when(
        () => repository.isInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.social,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => repository.isInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.groups,
        ),
      ).thenAnswer((_) async => false);

      await container
          .read(notificationPreferencesControllerProvider.notifier)
          .load('user-1');

      final status = container.read(notificationPreferencesControllerProvider);
      expect(status, isA<NotificationPreferencesLoaded>());
      expect((status as NotificationPreferencesLoaded).socialEnabled, isTrue);
      expect(status.groupsEnabled, isFalse);
    },
  );

  test('load falha -> NotificationPreferencesError', () async {
    when(
      () => repository.isInAppEnabled(
        'user-1',
        NotificationPreferenceCategory.social,
      ),
    ).thenThrow(const NotificationPreferenceRepositoryException('Falha.'));
    when(
      () => repository.isInAppEnabled(
        'user-1',
        NotificationPreferenceCategory.groups,
      ),
    ).thenAnswer((_) async => true);

    await container
        .read(notificationPreferencesControllerProvider.notifier)
        .load('user-1');

    expect(
      container.read(notificationPreferencesControllerProvider),
      isA<NotificationPreferencesError>(),
    );
  });

  test(
    'toggle da categoria social altera só o social, preservando groups',
    () async {
      when(
        () => repository.isInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.social,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => repository.isInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.groups,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => repository.setInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.social,
          false,
        ),
      ).thenAnswer((_) async {});

      final notifier = container.read(
        notificationPreferencesControllerProvider.notifier,
      );
      await notifier.load('user-1');
      await notifier.toggle('user-1', NotificationPreferenceCategory.social);

      final status = container.read(notificationPreferencesControllerProvider);
      expect(status, isA<NotificationPreferencesLoaded>());
      expect((status as NotificationPreferencesLoaded).socialEnabled, isFalse);
      expect(status.groupsEnabled, isTrue);
      verify(
        () => repository.setInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.social,
          false,
        ),
      ).called(1);
    },
  );

  test(
    'toggle da categoria groups altera só o groups, preservando social',
    () async {
      when(
        () => repository.isInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.social,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => repository.isInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.groups,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => repository.setInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.groups,
          false,
        ),
      ).thenAnswer((_) async {});

      final notifier = container.read(
        notificationPreferencesControllerProvider.notifier,
      );
      await notifier.load('user-1');
      await notifier.toggle('user-1', NotificationPreferenceCategory.groups);

      final status = container.read(notificationPreferencesControllerProvider);
      expect(status, isA<NotificationPreferencesLoaded>());
      expect((status as NotificationPreferencesLoaded).socialEnabled, isTrue);
      expect(status.groupsEnabled, isFalse);
      verify(
        () => repository.setInAppEnabled(
          'user-1',
          NotificationPreferenceCategory.groups,
          false,
        ),
      ).called(1);
    },
  );
}
