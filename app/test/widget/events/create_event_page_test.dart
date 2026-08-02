import 'package:app/core/models/paged_result.dart';
import 'package:app/features/events/presentation/pages/create_event_page.dart';
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

class FakeRestaurantSearchFilters extends Fake
    implements RestaurantSearchFilters {}

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

Widget _wrap(MockRestaurantRepository repository) {
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
    overrides: [restaurantRepositoryProvider.overrideWithValue(repository)],
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
      await tester.testTextInput.receiveAction(TextInputAction.done);
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
}
