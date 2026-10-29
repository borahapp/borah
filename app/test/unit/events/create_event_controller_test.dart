import 'package:app/core/analytics/analytics_event.dart';
import 'package:app/core/analytics/analytics_service.dart';
import 'package:app/core/analytics/app_analytics.dart';
import 'package:app/features/events/application/create_event_controller.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/events/presentation/states/create_event_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

class _RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> trackedEvents = [];

  @override
  Future<void> setup() async {}

  @override
  Future<void> track(AnalyticsEvent event) async {
    trackedEvents.add(event);
  }

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> reset() async {}
}

Event _event() {
  return Event(
    id: 'e-1',
    groupId: 'g-1',
    restaurantId: 'r-1',
    organizerId: 'u-organizer',
    scheduledAt: DateTime(2026, 8, 20, 20, 0),
    status: 'scheduled',
  );
}

void main() {
  late MockEventRepository repository;
  late ProviderContainer container;
  late _RecordingAnalyticsService analyticsService;

  setUp(() {
    repository = MockEventRepository();
    container = ProviderContainer(
      overrides: [eventRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    analyticsService = _RecordingAnalyticsService();
    AppAnalytics.debugServiceOverride = analyticsService;
    AppAnalytics.debugSendsEventsOverride = true;
  });

  tearDown(() {
    AppAnalytics.debugServiceOverride = null;
    AppAnalytics.debugSendsEventsOverride = null;
  });

  test('estado inicial é CreateEventInitial', () {
    expect(
      container.read(createEventControllerProvider),
      isA<CreateEventInitial>(),
    );
  });

  group('create', () {
    test('sucesso -> CreateEventSaveSuccess', () async {
      when(
        () => repository.create(
          groupId: any(named: 'groupId'),
          restaurantId: any(named: 'restaurantId'),
          scheduledAt: any(named: 'scheduledAt'),
        ),
      ).thenAnswer((_) async => _event());

      await container
          .read(createEventControllerProvider.notifier)
          .create(
            groupId: 'g-1',
            restaurantId: 'r-1',
            scheduledAt: DateTime(2026, 8, 20, 20, 0),
          );

      expect(
        container.read(createEventControllerProvider),
        isA<CreateEventSaveSuccess>(),
      );
    });

    test(
      'falha com EventRepositoryException -> CreateEventError com a mensagem original',
      () async {
        when(
          () => repository.create(
            groupId: any(named: 'groupId'),
            restaurantId: any(named: 'restaurantId'),
            scheduledAt: any(named: 'scheduledAt'),
          ),
        ).thenThrow(
          const EventRepositoryException('Você não é membro deste grupo.'),
        );

        await container
            .read(createEventControllerProvider.notifier)
            .create(
              groupId: 'g-1',
              restaurantId: 'r-1',
              scheduledAt: DateTime(2026, 8, 20, 20, 0),
            );

        final status = container.read(createEventControllerProvider);
        expect(status, isA<CreateEventError>());
        expect(
          (status as CreateEventError).message,
          'Você não é membro deste grupo.',
        );
      },
    );

    test(
      'falha inesperada -> CreateEventError com mensagem genérica',
      () async {
        when(
          () => repository.create(
            groupId: any(named: 'groupId'),
            restaurantId: any(named: 'restaurantId'),
            scheduledAt: any(named: 'scheduledAt'),
          ),
        ).thenThrow(Exception('erro de rede'));

        await container
            .read(createEventControllerProvider.notifier)
            .create(
              groupId: 'g-1',
              restaurantId: 'r-1',
              scheduledAt: DateTime(2026, 8, 20, 20, 0),
            );

        final status = container.read(createEventControllerProvider);
        expect(status, isA<CreateEventError>());
        expect(
          (status as CreateEventError).message,
          'Não foi possível criar o rolê.',
        );
      },
    );

    group('analytics (FASE 08)', () {
      test(
        'sucesso dispara trackEventCreated exatamente 1 vez com event_id/group_id/restaurant_id',
        () async {
          when(
            () => repository.create(
              groupId: any(named: 'groupId'),
              restaurantId: any(named: 'restaurantId'),
              scheduledAt: any(named: 'scheduledAt'),
            ),
          ).thenAnswer((_) async => _event());

          await container
              .read(createEventControllerProvider.notifier)
              .create(
                groupId: 'g-1',
                restaurantId: 'r-1',
                scheduledAt: DateTime(2026, 8, 20, 20, 0),
              );

          final event = analyticsService.trackedEvents.single;
          expect(event.name, 'event_created');
          expect(event.properties['event_id'], 'e-1');
          expect(event.properties['group_id'], 'g-1');
          expect(event.properties['restaurant_id'], 'r-1');
        },
      );

      test('falha não dispara trackEventCreated', () async {
        when(
          () => repository.create(
            groupId: any(named: 'groupId'),
            restaurantId: any(named: 'restaurantId'),
            scheduledAt: any(named: 'scheduledAt'),
          ),
        ).thenThrow(
          const EventRepositoryException('Você não é membro deste grupo.'),
        );

        await container
            .read(createEventControllerProvider.notifier)
            .create(
              groupId: 'g-1',
              restaurantId: 'r-1',
              scheduledAt: DateTime(2026, 8, 20, 20, 0),
            );

        expect(analyticsService.trackedEvents, isEmpty);
      });
    });
  });
}
