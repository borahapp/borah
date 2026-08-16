import 'dart:typed_data';

import 'package:app/features/reviews/data/review_remote_datasource.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRemoteDatasource extends Mock
    implements ReviewRemoteDatasource {}

Map<String, dynamic> _row({
  String id = 'rv-1',
  String userId = 'user-2',
  String restaurantId = 'r-1',
  String restaurantName = 'Outback',
  String? restaurantCoverImage,
  // BETA-RELEASE-03: `restaurants` é um embed opcional (não `!inner`) -
  // `null` simula o PostgREST não resolvendo o embed (o cenário que antes
  // derrubava a linha inteira da lista com `!inner`; ver
  // `review_remote_datasource.dart`). `true` (padrão) simula o caso normal.
  bool includeRestaurant = true,
}) {
  return {
    'id': id,
    'restaurant_id': restaurantId,
    'user_id': userId,
    'rating': 4.5,
    'comment': 'Ótimo!',
    'likes_count': 3,
    'photos_count': 0,
    'created_at': '2026-01-03T00:00:00.000Z',
    'updated_at': '2026-01-03T00:00:00.000Z',
    'restaurants': includeRestaurant
        ? {
            'id': restaurantId,
            'name': restaurantName,
            'cover_image': restaurantCoverImage,
          }
        : null,
  };
}

Map<String, dynamic> _profileRow({
  required String id,
  String? fullName = 'Bruno Costa',
}) {
  return {'id': id, 'full_name': fullName, 'avatar_url': null};
}

void main() {
  late MockReviewRemoteDatasource datasource;
  late ReviewRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    datasource = MockReviewRemoteDatasource();
    repository = ReviewRepositoryImpl(datasource);
    when(() => datasource.fetchProfilesByIds(any())).thenAnswer((
      invocation,
    ) async {
      final ids = invocation.positionalArguments.first as List<String>;
      return ids.map((id) => _profileRow(id: id)).toList();
    });
  });

  group('listByRestaurant', () {
    test(
      'resolve autor e restaurante a partir do embed + fetchProfilesByIds em lote',
      () async {
        when(
          () => datasource.listByRestaurant('r-1', page: 1, limit: 20),
        ).thenAnswer((_) async => [_row(userId: 'user-2')]);

        final result = await repository.listByRestaurant(
          'r-1',
          page: 1,
          limit: 20,
        );

        final review = result.items.single;
        expect(review.restaurantName, 'Outback');
        expect(review.authorFullName, 'Bruno Costa');
        verify(() => datasource.fetchProfilesByIds(['user-2'])).called(1);
      },
    );

    test(
      'múltiplas reviews do mesmo autor disparam uma única consulta de perfis',
      () async {
        when(
          () => datasource.listByRestaurant('r-1', page: 1, limit: 20),
        ).thenAnswer(
          (_) async => [
            _row(id: 'rv-1', userId: 'user-2'),
            _row(id: 'rv-2', userId: 'user-2'),
          ],
        );

        final result = await repository.listByRestaurant(
          'r-1',
          page: 1,
          limit: 20,
        );

        expect(result.items, hasLength(2));
        verify(() => datasource.fetchProfilesByIds(['user-2'])).called(1);
      },
    );

    test('autor sem perfil correspondente não quebra a listagem', () async {
      when(
        () => datasource.listByRestaurant('r-1', page: 1, limit: 20),
      ).thenAnswer((_) async => [_row(userId: 'user-2')]);
      when(
        () => datasource.fetchProfilesByIds(['user-2']),
      ).thenAnswer((_) async => []);

      final result = await repository.listByRestaurant(
        'r-1',
        page: 1,
        limit: 20,
      );

      final review = result.items.single;
      expect(review.authorFullName, isNull);
      expect(review.restaurantName, 'Outback');
    });

    test('não busca perfis quando não há linhas', () async {
      when(
        () => datasource.listByRestaurant('r-1', page: 1, limit: 20),
      ).thenAnswer((_) async => []);

      final result = await repository.listByRestaurant(
        'r-1',
        page: 1,
        limit: 20,
      );

      expect(result.items, isEmpty);
      verifyNever(() => datasource.fetchProfilesByIds(any()));
    });
  });

  group('listByUser', () {
    test('resolve restaurante de cada review (podem ser diferentes)', () async {
      when(
        () => datasource.listByUser('user-2', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => [
          _row(id: 'rv-1', restaurantId: 'r-1', restaurantName: 'Outback'),
          _row(id: 'rv-2', restaurantId: 'r-2', restaurantName: 'Madero'),
        ],
      );

      final result = await repository.listByUser('user-2', page: 1, limit: 20);

      expect(result.items.map((r) => r.restaurantName), ['Outback', 'Madero']);
    });
  });

  group('getById', () {
    test('resolve autor e restaurante para uma única review', () async {
      when(
        () => datasource.fetchById('rv-1'),
      ).thenAnswer((_) async => _row(userId: 'user-2'));

      final review = await repository.getById('rv-1');

      expect(review.authorFullName, 'Bruno Costa');
      expect(review.restaurantName, 'Outback');
      verify(() => datasource.fetchProfilesByIds(['user-2'])).called(1);
    });
  });

  group('create', () {
    test(
      'review recém-criada já vem com autor/restaurante resolvidos',
      () async {
        when(
          () => datasource.insert(any()),
        ).thenAnswer((_) async => _row(id: 'rv-new', userId: 'user-1'));

        final review = await repository.create(
          restaurantId: 'r-1',
          userId: 'user-1',
          rating: 4.5,
          ambienceScore: 4,
          serviceScore: 4,
          foodScore: 5,
          costBenefitScore: 4,
        );

        expect(review.authorFullName, 'Bruno Costa');
        expect(review.restaurantName, 'Outback');
      },
    );
  });

  // BETA-RELEASE-03: regressão da causa raiz de BETA-RELEASE-02 - a lista
  // "Avaliações" ficava vazia porque `restaurants!inner` derrubava a linha
  // inteira sempre que o embed não resolvia. `restaurants(...)` (embed
  // opcional) preserva a review nesse caso - ver `_mapRow` em
  // `review_repository_impl.dart` e `_reviewsSelect` no datasource.
  group('BETA-RELEASE-03 - embed opcional de restaurants', () {
    test(
      'TESTE 1: embed de restaurant presente preenche nome e capa',
      () async {
        when(
          () => datasource.listByRestaurant('r-1', page: 1, limit: 20),
        ).thenAnswer(
          (_) async => [
            _row(
              restaurantName: 'Outback',
              restaurantCoverImage: 'https://cdn.example/outback.jpg',
            ),
          ],
        );

        final result = await repository.listByRestaurant(
          'r-1',
          page: 1,
          limit: 20,
        );

        final review = result.items.single;
        expect(review.restaurantName, 'Outback');
        expect(review.restaurantCoverImage, 'https://cdn.example/outback.jpg');
      },
    );

    test(
      'TESTE 2: embed de restaurant nulo não descarta a review nem lança',
      () async {
        when(
          () => datasource.listByRestaurant('r-1', page: 1, limit: 20),
        ).thenAnswer((_) async => [_row(includeRestaurant: false)]);

        final result = await repository.listByRestaurant(
          'r-1',
          page: 1,
          limit: 20,
        );

        expect(result.items, hasLength(1));
        final review = result.items.single;
        expect(review.restaurantName, isNull);
        expect(review.restaurantCoverImage, isNull);
      },
    );

    test(
      'TESTE 3: lista mista (embed presente + embed nulo) mantém as duas reviews',
      () async {
        when(
          () => datasource.listByRestaurant('r-1', page: 1, limit: 20),
        ).thenAnswer(
          (_) async => [
            _row(id: 'rv-1', userId: 'user-2', restaurantName: 'Outback'),
            _row(id: 'rv-2', userId: 'user-2', includeRestaurant: false),
          ],
        );

        final result = await repository.listByRestaurant(
          'r-1',
          page: 1,
          limit: 20,
        );

        expect(result.items, hasLength(2));
        expect(result.items[0].id, 'rv-1');
        expect(result.items[0].restaurantName, 'Outback');
        expect(result.items[1].id, 'rv-2');
        expect(result.items[1].restaurantName, isNull);
      },
    );

    test('TESTE 5 (paginação): page/limit continuam repassados sem alteração '
        'ao datasource mesmo com embed nulo', () async {
      when(
        () => datasource.listByRestaurant('r-1', page: 2, limit: 5),
      ).thenAnswer(
        (_) async => List.generate(
          6,
          (i) => _row(id: 'rv-$i', includeRestaurant: i.isEven),
        ),
      );

      final result = await repository.listByRestaurant(
        'r-1',
        page: 2,
        limit: 5,
      );

      verify(
        () => datasource.listByRestaurant('r-1', page: 2, limit: 5),
      ).called(1);
      expect(result.page, 2);
      expect(result.limit, 5);
      expect(result.hasNextPage, isTrue);
      expect(result.items, hasLength(5));
    });
  });

  group('update', () {
    test(
      'review atualizada continua com autor/restaurante resolvidos',
      () async {
        when(
          () => datasource.updatePatch('rv-1', any()),
        ).thenAnswer((_) async => _row(id: 'rv-1', userId: 'user-2'));

        final review = await repository.update(
          'rv-1',
          rating: 3.0,
          ambienceScore: 3,
          serviceScore: 3,
          foodScore: 3,
          costBenefitScore: 3,
        );

        expect(review.authorFullName, 'Bruno Costa');
        expect(review.restaurantName, 'Outback');
      },
    );
  });
}
