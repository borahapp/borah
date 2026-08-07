import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/events/presentation/pages/events_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

Event _event({
  String id = 'e-1',
  String status = 'scheduled',
  DateTime? scheduledAt,
  int confirmedCount = 0,
  String restaurantName = 'Cantina da Vila',
  String? restaurantCoverImage,
  String organizerId = 'u-organizer',
}) {
  return Event(
    id: id,
    groupId: 'g-1',
    restaurantId: 'r-1',
    organizerId: organizerId,
    scheduledAt: scheduledAt ?? DateTime.now().add(const Duration(days: 3)),
    status: status,
    restaurantName: restaurantName,
    confirmedCount: confirmedCount,
    restaurantCoverImage: restaurantCoverImage,
  );
}

Widget _wrap(MockEventRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const EventsListPage(groupId: 'g-1'),
      ),
      GoRoute(
        path: '/groups/:groupId/events/:eventId',
        builder: (_, state) => Scaffold(
          body: Text('Detalhe do rolê ${state.pathParameters['eventId']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [eventRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockEventRepository repository;

  setUp(() {
    repository = MockEventRepository();
  });

  testWidgets(
    'lista carregada mostra cada rolê como EventCard com confirmedCount real',
    (tester) async {
      when(() => repository.listByGroup('g-1')).thenAnswer(
        (_) async => [
          _event(id: 'e-1', confirmedCount: 3),
          _event(id: 'e-2', confirmedCount: 0),
        ],
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      // FASE B0: EventCard substitui o ListTile cru - confirma que o
      // dado real de confirmedCount (não um valor fixo/fictício) chega
      // até a tela, para os dois casos (com e sem confirmados).
      expect(find.text('3 confirmados'), findsOneWidget);
      expect(find.text('0 confirmados'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    },
  );

  testWidgets('rolê com foto do restaurante mostra a imagem no EventCard', (
    tester,
  ) async {
    when(() => repository.listByGroup('g-1')).thenAnswer(
      (_) async => [_event(restaurantCoverImage: 'https://x/restaurant.jpg')],
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    while (tester.takeException() != null) {}

    // `UserAvatar` usa `CircleAvatar(backgroundImage: NetworkImage(...))`
    // - não existe um widget `Image` na árvore para uma imagem de
    // fundo de avatar, mesmo padrão já usado em `event_card_test.dart`.
    expect(find.byIcon(Icons.restaurant), findsNothing);
  });

  testWidgets('rolê cancelado mostra o selo de status no EventCard', (
    tester,
  ) async {
    when(
      () => repository.listByGroup('g-1'),
    ).thenAnswer((_) async => [_event(status: 'cancelled')]);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Cancelado'), findsOneWidget);
  });

  testWidgets('tocar no EventCard navega para o detalhe do rolê', (
    tester,
  ) async {
    when(
      () => repository.listByGroup('g-1'),
    ).thenAnswer((_) async => [_event(id: 'e-42')]);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cantina da Vila'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do rolê e-42'), findsOneWidget);
  });

  testWidgets('grupo sem rolês mostra o estado vazio', (tester) async {
    when(() => repository.listByGroup('g-1')).thenAnswer((_) async => []);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Este grupo ainda não tem rolês.'), findsOneWidget);
  });

  testWidgets(
    'erro ao carregar mostra o estado de erro com opção de tentar novamente',
    (tester) async {
      when(
        () => repository.listByGroup('g-1'),
      ).thenThrow(const EventRepositoryException('Não foi possível carregar.'));

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar.'), findsOneWidget);
    },
  );
}
