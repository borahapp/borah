import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/events/presentation/pages/create_event_page.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_details.dart';
import 'package:app/features/groups/domain/group_member.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/domain/restaurant_search_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class FakeRestaurantSearchFilters extends Fake
    implements RestaurantSearchFilters {}

GroupMember _member(String userId, String name) {
  return GroupMember(
    id: 'gm-$userId',
    userId: userId,
    role: 'member',
    fullName: name,
    avatarUrl: null,
  );
}

Restaurant _restaurant({String id = 'r-1', String name = 'Sushi Novo'}) {
  return Restaurant(
    id: id,
    name: name,
    category: 'Japonês',
    city: 'São Paulo',
    averageRating: null,
    totalReviews: 0,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  MockRestaurantRepository repository, {
  MockGroupRepository? groupRepository,
  MockEventRepository? eventRepository,
}) {
  if (groupRepository != null) {
    when(() => groupRepository.getById('g-1')).thenAnswer(
      (_) async => GroupDetails(
        group: const Group(
          id: 'g-1',
          name: 'Grupo',
          description: null,
          photoUrl: null,
          inviteCode: 'ABCDEFGH',
        ),
        members: [_member('user-1', 'Ana'), _member('user-2', 'Bruno')],
      ),
    );
  }
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const CreateEventPage(groupId: 'g-1'),
      ),
      GoRoute(
        path: '/restaurants/new',
        // UX-01: stub que simula exatamente o retorno de
        // `CreateRestaurantPage(returnToCaller: true)` em caso de
        // sucesso (`context.pop(next.restaurant)`) sem precisar montar
        // todo o formulário/repositório de restaurantes de novo - mesma
        // técnica de stub de destino já usada em
        // `restaurants_search_page_test.dart`.
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.pop(_restaurant()),
            child: const Text('Simular cadastro concluído'),
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      restaurantRepositoryProvider.overrideWithValue(repository),
      if (groupRepository != null)
        groupRepositoryProvider.overrideWithValue(groupRepository),
      if (eventRepository != null)
        eventRepositoryProvider.overrideWithValue(eventRepository),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRestaurantSearchFilters());
  });

  late MockRestaurantRepository repository;

  setUp(() {
    repository = MockRestaurantRepository();
    when(() => repository.suggestForGroup(any())).thenAnswer((_) async => []);
  });

  testWidgets(
    'busca sem resultado oferece cadastrar restaurante sem sair do fluxo',
    (tester) async {
      when(() => repository.search(any())).thenAnswer(
        (_) async => const PagedResult(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Sushi Novo');
      // ROLE-SEARCH-02: busca automática (debounce) - digitar já é
      // suficiente, sem precisar simular Enter.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum restaurante encontrado.'), findsOneWidget);
      expect(find.text('Cadastrar restaurante'), findsOneWidget);

      await tester.tap(find.text('Cadastrar restaurante'));
      await tester.pumpAndSettle();

      // Chegou na tela de cadastro sem perder o contexto anterior.
      expect(find.text('Simular cadastro concluído'), findsOneWidget);

      await tester.tap(find.text('Simular cadastro concluído'));
      await tester.pumpAndSettle();

      // Voltou para a Etapa 1 do mesmo CreateEventPage (grupo preservado)
      // com o restaurante recém-criado JÁ selecionado - "Continuar" para
      // a Etapa 2, não mais o campo de busca/lista de resultados. Nenhuma
      // busca nova foi disparada: o objeto devolvido por
      // `CreateRestaurantPage` já é suficiente, sem depender de nome
      // buscado bater com nome cadastrado.
      expect(find.text('Restaurante cadastrado.'), findsOneWidget);
      expect(find.textContaining('Japonês'), findsOneWidget);
      expect(find.text('Trocar restaurante'), findsOneWidget);
      expect(find.text('Nenhum restaurante encontrado.'), findsNothing);
      verify(() => repository.search(any())).called(1);
    },
  );

  group('ROLE-SEARCH-02 - busca automática (debounce)', () {
    testWidgets(
      'digitar sem pressionar Enter dispara a busca depois de 500ms de '
      'debounce',
      (tester) async {
        when(() => repository.search(any())).thenAnswer(
          (_) async => PagedResult(
            items: [_restaurant(name: 'Madero')],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Madero');

        // Menos de 500ms - ainda não deve ter disparado.
        await tester.pump(const Duration(milliseconds: 100));
        verifyNever(() => repository.search(any()));

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        verify(() => repository.search(any())).called(1);
        expect(find.text('Trocar restaurante'), findsNothing);
        expect(find.text('Madero'), findsWidgets);
      },
    );

    testWidgets(
      'digitar várias letras rapidamente resulta em apenas 1 busca (só a '
      'última tecla, depois do debounce)',
      (tester) async {
        when(() => repository.search(any())).thenAnswer(
          (_) async => PagedResult(
            items: [_restaurant(name: 'Madero')],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        final field = find.byType(TextFormField).first;
        await tester.enterText(field, 'M');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(field, 'Ma');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(field, 'Mad');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(field, 'Madero');

        verifyNever(() => repository.search(any()));

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        verify(() => repository.search(any())).called(1);
      },
    );

    testWidgets(
      'ENTER continua disparando a busca imediatamente, sem esperar o '
      'debounce',
      (tester) async {
        when(() => repository.search(any())).thenAnswer(
          (_) async => PagedResult(
            items: [_restaurant(name: 'Madero')],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Madero');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Já buscou via Enter, sem esperar os 500ms do debounce.
        verify(() => repository.search(any())).called(1);
        expect(find.text('Madero'), findsWidgets);

        // Enter cancela o debounce pendente - avançar o tempo não deve
        // disparar uma segunda busca redundante com a mesma query.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        verifyNever(() => repository.search(any()));
      },
    );

    testWidgets('apagar o texto cancela a busca pendente e limpa os resultados '
        'antigos imediatamente', (tester) async {
      when(() => repository.search(any())).thenAnswer(
        (_) async => PagedResult(
          items: [_restaurant(name: 'Madero')],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      final field = find.byType(TextFormField).first;
      await tester.enterText(field, 'Madero');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Madero'), findsWidgets);
      verify(() => repository.search(any())).called(1);

      await tester.enterText(field, '');
      await tester.pump();

      // Limpo na hora, sem esperar o debounce - nenhuma tela de
      // resultado/estado antigo permanece.
      expect(find.text('Nenhum restaurante encontrado.'), findsNothing);
      expect(find.text('Trocar restaurante'), findsNothing);

      // E o debounce cancelado não dispara uma nova busca depois.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      verifyNever(() => repository.search(any()));
    });

    testWidgets(
      'busca consecutiva rápida: só o resultado da última query buscada é '
      'exibido, mesmo se uma resposta antiga chegar depois',
      (tester) async {
        final maderoCompleter = Completer<PagedResult<Restaurant>>();
        when(
          () => repository.search(
            any(
              that: isA<RestaurantSearchFilters>().having(
                (f) => f.query,
                'query',
                'Madero',
              ),
            ),
          ),
        ).thenAnswer((_) => maderoCompleter.future);
        when(
          () => repository.search(
            any(
              that: isA<RestaurantSearchFilters>().having(
                (f) => f.query,
                'query',
                'Outback',
              ),
            ),
          ),
        ).thenAnswer(
          (_) async => PagedResult(
            items: [_restaurant(id: 'r-2', name: 'Outback')],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        final field = find.byType(TextFormField).first;
        await tester.enterText(field, 'Madero');
        await tester.pump(const Duration(milliseconds: 500));
        // Sem `pumpAndSettle()` aqui: a resposta de "Madero" foi deixada
        // pendente de propósito (`maderoCompleter` só completa mais
        // abaixo) - o spinner de loading indeterminado nunca se
        // estabilizaria sozinho.
        await tester.pump();

        await tester.enterText(field, 'Outback');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // "Madero" respondendo tarde não pode sobrescrever "Outback".
        maderoCompleter.complete(
          PagedResult(
            items: [_restaurant(id: 'r-1', name: 'Madero')],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Outback'), findsWidgets);
        expect(find.text('Madero'), findsNothing);
      },
    );
  });

  group('F36 - sugestão de rodízio', () {
    testWidgets('mostra a sugestão do membro que nunca organizou um rolê', (
      tester,
    ) async {
      final groupRepository = MockGroupRepository();
      final eventRepository = MockEventRepository();

      when(() => eventRepository.listByGroup('g-1')).thenAnswer(
        (_) async => [
          Event(
            id: 'e-1',
            groupId: 'g-1',
            restaurantId: 'r-1',
            organizerId: 'user-1',
            scheduledAt: DateTime(2026, 1, 1),
            status: 'completed',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          repository,
          groupRepository: groupRepository,
          eventRepository: eventRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Sugestão de rodízio: era a vez de Bruno.'),
        findsOneWidget,
      );
    });

    testWidgets('sem histórico de rolês, não mostra sugestão nenhuma', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sugestão de rodízio'), findsNothing);
    });
  });

  group('F13 - descoberta guiada por grupo', () {
    testWidgets('mostra restaurantes favoritos do grupo ainda não visitados', (
      tester,
    ) async {
      when(
        () => repository.suggestForGroup('g-1'),
      ).thenAnswer((_) async => [_restaurant(id: 'r-2', name: 'Cantina')]);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(
        find.text('Favoritos do grupo ainda não visitados'),
        findsOneWidget,
      );
      expect(find.text('Cantina'), findsOneWidget);
    });

    testWidgets('tocar na sugestão seleciona o restaurante', (tester) async {
      when(
        () => repository.suggestForGroup('g-1'),
      ).thenAnswer((_) async => [_restaurant(id: 'r-2', name: 'Cantina')]);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cantina'));
      await tester.pumpAndSettle();

      expect(find.text('Trocar restaurante'), findsOneWidget);
    });

    testWidgets('sem sugestão, não mostra a seção', (tester) async {
      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Favoritos do grupo ainda não visitados'), findsNothing);
    });
  });
}
