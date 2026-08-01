import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/events/application/event_detail_controller.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_attendance.dart';
import 'package:app/features/events/domain/event_details.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/events/presentation/states/event_detail_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

Event _event({String status = 'scheduled'}) {
  return Event(
    id: 'e-1',
    groupId: 'g-1',
    restaurantId: 'r-1',
    scheduledAt: DateTime(2026, 8, 20, 20, 0),
    status: status,
    restaurantName: 'Bar do Zé',
    restaurantCategory: 'Bar',
    restaurantCity: 'São Paulo',
  );
}

EventDetails _details({
  String ownStatus = 'pending',
  String eventStatus = 'scheduled',
}) {
  return EventDetails(
    event: _event(status: eventStatus),
    attendances: [
      EventAttendance(
        id: 'a-1',
        userId: 'user-1',
        status: ownStatus,
        fullName: 'Você',
        avatarUrl: null,
      ),
      const EventAttendance(
        id: 'a-2',
        userId: 'user-2',
        status: 'confirmed',
        fullName: 'Maria',
        avatarUrl: null,
      ),
    ],
  );
}

void main() {
  late MockEventRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockEventRepository();
    container = ProviderContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue('user-1'),
      ],
    );
    addTearDown(container.dispose);
    when(
      () => repository.isGroupAdmin(
        groupId: any(named: 'groupId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => false);
  });

  test('estado inicial é EventDetailInitial', () {
    expect(
      container.read(eventDetailControllerProvider),
      isA<EventDetailInitial>(),
    );
  });

  group('load', () {
    test('sucesso -> EventDetailLoaded', () async {
      when(() => repository.getById('e-1')).thenAnswer((_) async => _details());

      await container
          .read(eventDetailControllerProvider.notifier)
          .load('e-1', 'g-1');

      final status = container.read(eventDetailControllerProvider);
      expect(status, isA<EventDetailLoaded>());
      expect((status as EventDetailLoaded).details.attendances, hasLength(2));
    });

    test('admin/owner do grupo -> canManage true', () async {
      when(() => repository.getById('e-1')).thenAnswer((_) async => _details());
      when(
        () => repository.isGroupAdmin(groupId: 'g-1', userId: 'user-1'),
      ).thenAnswer((_) async => true);

      await container
          .read(eventDetailControllerProvider.notifier)
          .load('e-1', 'g-1');

      final status = container.read(eventDetailControllerProvider);
      expect((status as EventDetailLoaded).canManage, isTrue);
    });

    test(
      'falha com EventRepositoryException -> EventDetailError sem details',
      () async {
        when(
          () => repository.getById('e-1'),
        ).thenThrow(const EventRepositoryException('Rolê não encontrado.'));

        await container
            .read(eventDetailControllerProvider.notifier)
            .load('e-1', 'g-1');

        final status = container.read(eventDetailControllerProvider);
        expect(status, isA<EventDetailError>());
        expect((status as EventDetailError).message, 'Rolê não encontrado.');
        expect(status.details, isNull);
      },
    );

    test(
      'falha inesperada -> EventDetailError com mensagem genérica',
      () async {
        when(
          () => repository.getById('e-1'),
        ).thenThrow(Exception('erro de rede'));

        await container
            .read(eventDetailControllerProvider.notifier)
            .load('e-1', 'g-1');

        final status = container.read(eventDetailControllerProvider);
        expect(status, isA<EventDetailError>());
        expect(
          (status as EventDetailError).message,
          'Não foi possível carregar o rolê.',
        );
      },
    );
  });

  group('confirm', () {
    test('sucesso -> presença própria fica confirmed', () async {
      when(() => repository.getById('e-1')).thenAnswer((_) async => _details());
      when(() => repository.confirmAttendance('a-1')).thenAnswer((_) async {});

      final notifier = container.read(eventDetailControllerProvider.notifier);
      await notifier.load('e-1', 'g-1');
      await notifier.confirm('a-1');

      final status = container.read(eventDetailControllerProvider);
      expect(status, isA<EventDetailLoaded>());
      final own = (status as EventDetailLoaded).details.attendances.first;
      expect(own.status, 'confirmed');
    });

    test(
      'falha -> reverte para o status anterior e emite EventDetailError com details',
      () async {
        when(
          () => repository.getById('e-1'),
        ).thenAnswer((_) async => _details());
        when(() => repository.confirmAttendance('a-1')).thenThrow(
          const EventRepositoryException('Não foi possível confirmar.'),
        );

        final notifier = container.read(eventDetailControllerProvider.notifier);
        await notifier.load('e-1', 'g-1');
        await notifier.confirm('a-1');

        final status = container.read(eventDetailControllerProvider);
        expect(status, isA<EventDetailError>());
        expect(
          (status as EventDetailError).message,
          'Não foi possível confirmar.',
        );
        expect(status.details, isNotNull);
        expect(status.details!.attendances.first.status, 'pending');
      },
    );

    test('sem rolê carregado -> não chama o repository', () async {
      await container
          .read(eventDetailControllerProvider.notifier)
          .confirm('a-1');

      verifyNever(() => repository.confirmAttendance(any()));
      expect(
        container.read(eventDetailControllerProvider),
        isA<EventDetailInitial>(),
      );
    });
  });

  group('decline', () {
    test('sucesso -> presença própria fica declined', () async {
      when(() => repository.getById('e-1')).thenAnswer((_) async => _details());
      when(() => repository.declineAttendance('a-1')).thenAnswer((_) async {});

      final notifier = container.read(eventDetailControllerProvider.notifier);
      await notifier.load('e-1', 'g-1');
      await notifier.decline('a-1');

      final status = container.read(eventDetailControllerProvider);
      expect(status, isA<EventDetailLoaded>());
      final own = (status as EventDetailLoaded).details.attendances.first;
      expect(own.status, 'declined');
    });

    test('falha inesperada -> reverte e emite mensagem genérica', () async {
      when(() => repository.getById('e-1')).thenAnswer((_) async => _details());
      when(
        () => repository.declineAttendance('a-1'),
      ).thenThrow(Exception('erro de rede'));

      final notifier = container.read(eventDetailControllerProvider.notifier);
      await notifier.load('e-1', 'g-1');
      await notifier.decline('a-1');

      final status = container.read(eventDetailControllerProvider);
      expect(status, isA<EventDetailError>());
      expect(
        (status as EventDetailError).message,
        'Não foi possível registrar sua resposta.',
      );
      expect(status.details!.attendances.first.status, 'pending');
    });
  });

  group('cancel', () {
    test('sucesso -> chama o repository e recarrega o rolê', () async {
      when(() => repository.getById('e-1')).thenAnswer((_) async => _details());
      when(() => repository.cancel('e-1')).thenAnswer((_) async {});

      final notifier = container.read(eventDetailControllerProvider.notifier);
      await notifier.load('e-1', 'g-1');
      await notifier.cancel('e-1');

      verify(() => repository.cancel('e-1')).called(1);
      verify(() => repository.getById('e-1')).called(2);
      expect(
        container.read(eventDetailControllerProvider),
        isA<EventDetailLoaded>(),
      );
    });

    test('falha -> EventDetailError preservando details e canManage', () async {
      when(() => repository.getById('e-1')).thenAnswer((_) async => _details());
      when(
        () => repository.isGroupAdmin(groupId: 'g-1', userId: 'user-1'),
      ).thenAnswer((_) async => true);
      when(() => repository.cancel('e-1')).thenThrow(
        const EventRepositoryException('Apenas admin/owner pode cancelar.'),
      );

      final notifier = container.read(eventDetailControllerProvider.notifier);
      await notifier.load('e-1', 'g-1');
      await notifier.cancel('e-1');

      final status = container.read(eventDetailControllerProvider);
      expect(status, isA<EventDetailError>());
      expect(
        (status as EventDetailError).message,
        'Apenas admin/owner pode cancelar.',
      );
      expect(status.details, isNotNull);
      expect(status.canManage, isTrue);
    });
  });

  group('reschedule', () {
    test('sem rolê carregado -> não chama o repository', () async {
      await container
          .read(eventDetailControllerProvider.notifier)
          .reschedule('e-1', DateTime(2026, 9, 1, 20, 0));

      verifyNever(
        () => repository.reschedule(
          eventId: any(named: 'eventId'),
          scheduledAt: any(named: 'scheduledAt'),
        ),
      );
    });
  });
}
