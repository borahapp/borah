import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/reviews/presentation/pages/reviews_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

Review _review({
  String id = 'rv-1',
  String userId = 'user-1',
  double rating = 4.5,
}) {
  return Review(
    id: id,
    restaurantId: 'r-1',
    userId: userId,
    rating: rating,
    likesCount: 0,
    photosCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void _stubList(MockReviewRepository repository, List<Review> items) {
  when(() => repository.listByRestaurant('r-1', page: 1, limit: 20)).thenAnswer(
    (_) async =>
        PagedResult(items: items, page: 1, limit: 20, hasNextPage: false),
  );
}

Widget _wrap(
  MockReviewRepository repository, {
  String currentUserId = 'user-1',
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const ReviewsListPage(restaurantId: 'r-1'),
      ),
      GoRoute(
        path: '/restaurants/:id/reviews/new',
        builder: (_, _) => const Scaffold(body: Text('Create Review Page')),
      ),
      GoRoute(
        path: '/reviews/:id/edit',
        builder: (_, state) => Scaffold(
          body: Text('Edit Review Page ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      reviewRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(currentUserId),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockReviewRepository repository;

  setUp(() {
    repository = MockReviewRepository();
  });

  testWidgets('1. usuário sem review -> ação "Avaliar restaurante"', (
    tester,
  ) async {
    _stubList(repository, [_review(id: 'rv-2', userId: 'user-2')]);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Avaliar restaurante'), findsOneWidget);
    expect(find.byTooltip('Editar minha avaliação'), findsNothing);
  });

  testWidgets('2. usuário com review -> ação "Editar minha avaliação"', (
    tester,
  ) async {
    _stubList(repository, [
      _review(id: 'rv-2', userId: 'user-2'),
      _review(id: 'rv-1', userId: 'user-1'),
    ]);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Editar minha avaliação'), findsOneWidget);
    expect(find.byTooltip('Avaliar restaurante'), findsNothing);
  });

  testWidgets(
    '3. tocar "Editar minha avaliação" abre a edição da review correta',
    (tester) async {
      _stubList(repository, [_review(id: 'rv-1', userId: 'user-1')]);
      when(
        () => repository.getById('rv-1'),
      ).thenAnswer((_) async => _review(id: 'rv-1', userId: 'user-1'));
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Editar minha avaliação'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Review Page rv-1'), findsOneWidget);
    },
  );

  testWidgets(
    '4. review de outro usuário continua normal, sem virar "Editar minha avaliação"',
    (tester) async {
      _stubList(repository, [_review(id: 'rv-2', userId: 'user-2')]);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Avaliar restaurante'), findsOneWidget);
      expect(find.byTooltip('Editar minha avaliação'), findsNothing);
    },
  );

  testWidgets('5. lista vazia -> "Avaliar restaurante"', (tester) async {
    _stubList(repository, []);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma avaliação ainda.'), findsOneWidget);
    expect(find.byTooltip('Avaliar restaurante'), findsOneWidget);
  });

  testWidgets(
    '6. múltiplas reviews -> localiza corretamente apenas a do usuário atual',
    (tester) async {
      _stubList(repository, [
        _review(id: 'rv-2', userId: 'user-2'),
        _review(id: 'rv-3', userId: 'user-3'),
        _review(id: 'rv-1', userId: 'user-1'),
        _review(id: 'rv-4', userId: 'user-4'),
      ]);
      when(
        () => repository.getById('rv-1'),
      ).thenAnswer((_) async => _review(id: 'rv-1', userId: 'user-1'));
      when(
        () => repository.listPhotoUrls('rv-1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => repository.isLikedByUser('rv-1', 'user-1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Editar minha avaliação'), findsOneWidget);

      await tester.tap(find.byTooltip('Editar minha avaliação'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Review Page rv-1'), findsOneWidget);
    },
  );
}
