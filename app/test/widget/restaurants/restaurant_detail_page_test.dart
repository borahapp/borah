import 'dart:async';

import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/favorites/data/favorite_repository_impl.dart';
import 'package:app/features/favorites/domain/favorite_repository.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:app/features/restaurants/presentation/pages/restaurant_detail_page.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

Restaurant _restaurant({
  String id = 'r-1',
  String name = 'Bar do Zé',
  double? averageRating = 4.5,
}) {
  return Restaurant(
    id: id,
    name: name,
    category: 'Bar',
    description: 'Um bar acolhedor no centro da cidade.',
    address: 'Rua das Flores, 123',
    city: 'São Paulo',
    state: 'SP',
    averageRating: averageRating,
    totalReviews: 8,
    status: 'active',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  MockRestaurantRepository restaurantRepository,
  MockFavoriteRepository favoriteRepository,
  MockReviewRepository reviewRepository,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const RestaurantDetailPage(restaurantId: 'r-1'),
      ),
      GoRoute(
        path: '/restaurants/:id/reviews',
        builder: (_, state) =>
            Scaffold(body: Text('Reviews Page ${state.pathParameters['id']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      restaurantRepositoryProvider.overrideWithValue(restaurantRepository),
      favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
      reviewRepositoryProvider.overrideWithValue(reviewRepository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockRestaurantRepository restaurantRepository;
  late MockFavoriteRepository favoriteRepository;
  late MockReviewRepository reviewRepository;

  setUp(() {
    restaurantRepository = MockRestaurantRepository();
    favoriteRepository = MockFavoriteRepository();
    reviewRepository = MockReviewRepository();
    when(
      () => reviewRepository.listRestaurantPhotos(any()),
    ).thenAnswer((_) async => []);
  });

  testWidgets('renderização inicial mostra os dados do restaurante', (
    tester,
  ) async {
    when(
      () => restaurantRepository.getById('r-1'),
    ).thenAnswer((_) async => _restaurant());
    when(
      () => favoriteRepository.isFavorited('user-1', 'r-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _wrap(restaurantRepository, favoriteRepository, reviewRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bar do Zé'), findsOneWidget);
    expect(find.text('Bar'), findsOneWidget);
    expect(find.text('Rua das Flores, 123, São Paulo, SP'), findsOneWidget);
    expect(find.text('4.5 (8 avaliações)'), findsOneWidget);
    expect(find.text('Um bar acolhedor no centro da cidade.'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Alterar foto de capa'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Ver avaliações'),
      findsOneWidget,
    );
  });

  testWidgets('estado de carregamento mostra indicador', (tester) async {
    final completer = Completer<Restaurant>();
    when(
      () => restaurantRepository.getById('r-1'),
    ).thenAnswer((_) => completer.future);
    when(
      () => favoriteRepository.isFavorited('user-1', 'r-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _wrap(restaurantRepository, favoriteRepository, reviewRepository),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_restaurant());
    await tester.pumpAndSettle();
  });

  testWidgets('estado de erro mostra a mensagem retornada pelo repositório', (
    tester,
  ) async {
    when(() => restaurantRepository.getById('r-1')).thenThrow(
      const RestaurantRepositoryException('Restaurante não encontrado.'),
    );
    when(
      () => favoriteRepository.isFavorited('user-1', 'r-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _wrap(restaurantRepository, favoriteRepository, reviewRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restaurante não encontrado.'), findsOneWidget);
  });

  testWidgets('ícone de favorito reflete estado favoritado', (tester) async {
    when(
      () => restaurantRepository.getById('r-1'),
    ).thenAnswer((_) async => _restaurant());
    when(
      () => favoriteRepository.isFavorited('user-1', 'r-1'),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(
      _wrap(restaurantRepository, favoriteRepository, reviewRepository),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('ícone de favorito reflete estado não favoritado', (
    tester,
  ) async {
    when(
      () => restaurantRepository.getById('r-1'),
    ).thenAnswer((_) async => _restaurant());
    when(
      () => favoriteRepository.isFavorited('user-1', 'r-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _wrap(restaurantRepository, favoriteRepository, reviewRepository),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('tocar no ícone alterna o estado de favorito', (tester) async {
    when(
      () => restaurantRepository.getById('r-1'),
    ).thenAnswer((_) async => _restaurant());
    when(
      () => favoriteRepository.isFavorited('user-1', 'r-1'),
    ).thenAnswer((_) async => false);
    when(
      () => favoriteRepository.addFavorite('user-1', 'r-1'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrap(restaurantRepository, favoriteRepository, reviewRepository),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    verify(() => favoriteRepository.addFavorite('user-1', 'r-1')).called(1);
  });

  testWidgets('"Ver avaliações" navega para a lista de avaliações', (
    tester,
  ) async {
    when(
      () => restaurantRepository.getById('r-1'),
    ).thenAnswer((_) async => _restaurant());
    when(
      () => favoriteRepository.isFavorited('user-1', 'r-1'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _wrap(restaurantRepository, favoriteRepository, reviewRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ver avaliações'));
    await tester.pumpAndSettle();

    expect(find.text('Reviews Page r-1'), findsOneWidget);
  });

  group('responsividade', () {
    for (final size in [
      const Size(320, 640),
      const Size(412, 915),
      const Size(768, 1024),
    ]) {
      testWidgets('renderiza sem overflow em ${size.width}x${size.height}', (
        tester,
      ) async {
        when(
          () => restaurantRepository.getById('r-1'),
        ).thenAnswer((_) async => _restaurant());
        when(
          () => favoriteRepository.isFavorited('user-1', 'r-1'),
        ).thenAnswer((_) async => false);

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(restaurantRepository, favoriteRepository, reviewRepository),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Bar do Zé'), findsOneWidget);
      });
    }
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    when(
      () => restaurantRepository.getById('r-1'),
    ).thenAnswer((_) async => _restaurant());
    when(
      () => favoriteRepository.isFavorited('user-1', 'r-1'),
    ).thenAnswer((_) async => false);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(restaurantRepository, favoriteRepository, reviewRepository),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });

  group('F14 - galeria de fotos', () {
    testWidgets('mostra as fotos agregadas das avaliações', (tester) async {
      when(
        () => restaurantRepository.getById('r-1'),
      ).thenAnswer((_) async => _restaurant());
      when(
        () => favoriteRepository.isFavorited('user-1', 'r-1'),
      ).thenAnswer((_) async => false);
      when(() => reviewRepository.listRestaurantPhotos(any())).thenAnswer(
        (_) async => ['https://x/photo1.jpg', 'https://x/photo2.jpg'],
      );

      await tester.pumpWidget(
        _wrap(restaurantRepository, favoriteRepository, reviewRepository),
      );
      await tester.pumpAndSettle();
      // `Image.network` sem servidor real no ambiente de teste - mesmo
      // padrão de drenagem de exceção já usado em
      // `event_detail_page_test.dart`.
      while (tester.takeException() != null) {}

      expect(find.text('Fotos de quem avaliou'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('sem fotos, não mostra a seção de galeria', (tester) async {
      when(
        () => restaurantRepository.getById('r-1'),
      ).thenAnswer((_) async => _restaurant());
      when(
        () => favoriteRepository.isFavorited('user-1', 'r-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        _wrap(restaurantRepository, favoriteRepository, reviewRepository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fotos de quem avaliou'), findsNothing);
    });
  });
}
