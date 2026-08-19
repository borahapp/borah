import 'package:app/design_system/components/cards/app_card.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/restaurants/data/google_places_repository_impl.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/google_place_result.dart';
import 'package:app/features/restaurants/domain/google_places_repository.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/presentation/pages/search_google_restaurant_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGooglePlacesRepository extends Mock
    implements GooglePlacesRepository {}

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

GooglePlaceResult _place({String placeId = 'ChIJ123', String name = 'Madero'}) {
  return GooglePlaceResult(
    placeId: placeId,
    name: name,
    address: 'Av. XXXXX, Jundiaí - SP',
    latitude: -23.1,
    longitude: -46.8,
    types: const ['restaurant'],
  );
}

Restaurant _restaurant({String id = 'r-1'}) {
  return Restaurant(
    id: id,
    name: 'Madero',
    category: 'Restaurant',
    totalReviews: 0,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    googlePlaceId: 'ChIJ123',
  );
}

Widget _wrap({
  required MockGooglePlacesRepository placesRepository,
  required MockRestaurantRepository restaurantRepository,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SearchGoogleRestaurantPage()),
      GoRoute(
        path: '/restaurants/new',
        builder: (_, _) => const Scaffold(body: Text('Create Restaurant Page')),
      ),
      GoRoute(
        path: '/restaurants/:id',
        builder: (_, state) => Scaffold(
          body: Text('Restaurant Detail Page ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      googlePlacesRepositoryProvider.overrideWithValue(placesRepository),
      restaurantRepositoryProvider.overrideWithValue(restaurantRepository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockGooglePlacesRepository placesRepository;
  late MockRestaurantRepository restaurantRepository;

  setUp(() {
    placesRepository = MockGooglePlacesRepository();
    restaurantRepository = MockRestaurantRepository();
  });

  testWidgets('estado inicial mostra mensagem e link de cadastro manual', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        placesRepository: placesRepository,
        restaurantRepository: restaurantRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Busque pelo nome de um restaurante real.'),
      findsOneWidget,
    );
    expect(find.text('Cadastrar manualmente'), findsOneWidget);
  });

  testWidgets(
    'digitar não chama a busca antes do debounce - só depois de 500ms sem '
    'nova tecla',
    (tester) async {
      when(
        () => placesRepository.searchText('Madero'),
      ).thenAnswer((_) async => [_place()]);

      await tester.pumpWidget(
        _wrap(
          placesRepository: placesRepository,
          restaurantRepository: restaurantRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'M');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextFormField), 'Ma');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextFormField), 'Mad');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextFormField), 'Madero');

      // Ainda dentro do debounce - nenhuma chamada disparada.
      verifyNever(() => placesRepository.searchText(any()));

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Só a última tecla, depois do debounce, dispara 1 única busca.
      verify(() => placesRepository.searchText('Madero')).called(1);
    },
  );

  testWidgets('mostra os resultados retornados', (tester) async {
    when(
      () => placesRepository.searchText('Madero'),
    ).thenAnswer((_) async => [_place()]);

    await tester.pumpWidget(
      _wrap(
        placesRepository: placesRepository,
        restaurantRepository: restaurantRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Madero');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // "Madero" aparece 2x (campo de busca preenchido + card do
    // resultado) - o endereço só existe no card, então é a asserção
    // inequívoca de que o resultado foi renderizado.
    expect(find.text('Madero'), findsNWidgets(2));
    expect(find.text('Av. XXXXX, Jundiaí - SP'), findsOneWidget);
  });

  testWidgets('sem resultado mostra "Nenhum restaurante encontrado."', (
    tester,
  ) async {
    when(
      () => placesRepository.searchText('xyzxyzxyz'),
    ).thenAnswer((_) async => []);

    await tester.pumpWidget(
      _wrap(
        placesRepository: placesRepository,
        restaurantRepository: restaurantRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'xyzxyzxyz');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum restaurante encontrado.'), findsOneWidget);
  });

  testWidgets('erro de limite (429) mostra a mensagem específica', (
    tester,
  ) async {
    when(() => placesRepository.searchText('Madero')).thenThrow(
      const GooglePlacesRepositoryException(
        'Limite de consultas atingido. Tente novamente em alguns instantes.',
      ),
    );

    await tester.pumpWidget(
      _wrap(
        placesRepository: placesRepository,
        restaurantRepository: restaurantRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Madero');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Limite de consultas atingido. Tente novamente em alguns instantes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('erro de indisponibilidade mostra a mensagem específica', (
    tester,
  ) async {
    when(() => placesRepository.searchText('Madero')).thenThrow(
      const GooglePlacesRepositoryException(
        'Serviço temporariamente indisponível.',
      ),
    );

    await tester.pumpWidget(
      _wrap(
        placesRepository: placesRepository,
        restaurantRepository: restaurantRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Madero');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Serviço temporariamente indisponível.'), findsOneWidget);
  });

  testWidgets('selecionar um resultado já existente navega direto ao detalhe', (
    tester,
  ) async {
    when(
      () => placesRepository.searchText('Madero'),
    ).thenAnswer((_) async => [_place()]);
    when(
      () => restaurantRepository.findByGooglePlaceId('ChIJ123'),
    ).thenAnswer((_) async => _restaurant());

    await tester.pumpWidget(
      _wrap(
        placesRepository: placesRepository,
        restaurantRepository: restaurantRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Madero');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // `find.text('Madero')` seria ambíguo (campo de busca + card) - o
    // card do resultado é o único `AppCard` com esse texto.
    await tester.tap(find.widgetWithText(AppCard, 'Madero'));
    await tester.pumpAndSettle();

    expect(find.text('Restaurant Detail Page r-1'), findsOneWidget);
    expect(find.text('Este restaurante já existe no BORAH.'), findsOneWidget);
    verifyNever(
      () => restaurantRepository.create(
        createdBy: any(named: 'createdBy'),
        name: any(named: 'name'),
        category: any(named: 'category'),
      ),
    );
  });

  testWidgets(
    'selecionar um resultado novo cria o restaurante e navega ao detalhe',
    (tester) async {
      when(
        () => placesRepository.searchText('Madero'),
      ).thenAnswer((_) async => [_place()]);
      when(
        () => restaurantRepository.findByGooglePlaceId('ChIJ123'),
      ).thenAnswer((_) async => null);
      when(
        () => restaurantRepository.create(
          createdBy: any(named: 'createdBy'),
          name: any(named: 'name'),
          category: any(named: 'category'),
          address: any(named: 'address'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          googlePlaceId: any(named: 'googlePlaceId'),
        ),
      ).thenAnswer((_) async => _restaurant());

      await tester.pumpWidget(
        _wrap(
          placesRepository: placesRepository,
          restaurantRepository: restaurantRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Madero');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppCard, 'Madero'));
      await tester.pumpAndSettle();

      expect(find.text('Restaurant Detail Page r-1'), findsOneWidget);
      expect(find.text('Restaurante cadastrado.'), findsOneWidget);
    },
  );

  testWidgets('link "Cadastrar manualmente" navega para o formulário manual', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        placesRepository: placesRepository,
        restaurantRepository: restaurantRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar manualmente'));
    await tester.pumpAndSettle();

    expect(find.text('Create Restaurant Page'), findsOneWidget);
  });
}
