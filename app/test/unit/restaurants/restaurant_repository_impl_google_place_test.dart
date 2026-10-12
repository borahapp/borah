import 'package:app/features/restaurants/data/restaurant_remote_datasource.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class MockRestaurantRemoteDatasource extends Mock
    implements RestaurantRemoteDatasource {}

Map<String, dynamic> _row({
  String id = 'r-1',
  String? googlePlaceId = 'ChIJ123',
}) {
  return {
    'id': id,
    'name': 'Madero',
    'category': 'Restaurant',
    'description': null,
    'address': 'Av. XXXXX, Jundiaí - SP',
    'city': null,
    'state': null,
    'latitude': -23.1,
    'longitude': -46.8,
    'average_rating': null,
    'total_reviews': 0,
    'cover_image': null,
    'status': 'active',
    'created_by': 'user-1',
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-01T00:00:00.000Z',
    'google_place_id': googlePlaceId,
  };
}

void main() {
  late MockRestaurantRemoteDatasource datasource;
  late RestaurantRepositoryImpl repository;

  setUp(() {
    datasource = MockRestaurantRemoteDatasource();
    repository = RestaurantRepositoryImpl(datasource);
  });

  test('findByGooglePlaceId retorna o restaurante quando existe', () async {
    when(
      () => datasource.fetchByGooglePlaceId('ChIJ123'),
    ).thenAnswer((_) async => _row());

    final restaurant = await repository.findByGooglePlaceId('ChIJ123');

    expect(restaurant, isNotNull);
    expect(restaurant!.id, 'r-1');
    expect(restaurant.googlePlaceId, 'ChIJ123');
  });

  test('findByGooglePlaceId retorna null quando não existe', () async {
    when(
      () => datasource.fetchByGooglePlaceId('ChIJ-inexistente'),
    ).thenAnswer((_) async => null);

    final restaurant = await repository.findByGooglePlaceId('ChIJ-inexistente');

    expect(restaurant, isNull);
  });

  test(
    'create envia google_place_id ao datasource e mapeia de volta',
    () async {
      when(() => datasource.insert(any())).thenAnswer((_) async => _row());

      final restaurant = await repository.create(
        createdBy: 'user-1',
        name: 'Madero',
        category: 'Restaurant',
        address: 'Av. XXXXX, Jundiaí - SP',
        latitude: -23.1,
        longitude: -46.8,
        googlePlaceId: 'ChIJ123',
      );

      expect(restaurant.googlePlaceId, 'ChIJ123');
      final captured = verify(() => datasource.insert(captureAny())).captured;
      final sentData = captured.single as Map<String, dynamic>;
      expect(sentData['google_place_id'], 'ChIJ123');
    },
  );

  test('create sem googlePlaceId (cadastro manual) envia null', () async {
    when(
      () => datasource.insert(any()),
    ).thenAnswer((_) async => _row(googlePlaceId: null));

    final restaurant = await repository.create(
      createdBy: 'user-1',
      name: 'Bar do Zé',
      category: 'Bar',
    );

    expect(restaurant.googlePlaceId, isNull);
    final captured = verify(() => datasource.insert(captureAny())).captured;
    final sentData = captured.single as Map<String, dynamic>;
    expect(sentData['google_place_id'], isNull);
  });

  group('FASE 03 - corrida em create() por google_place_id (23505)', () {
    test(
      'violação de unicidade (23505) com googlePlaceId recupera o '
      'restaurante que venceu a corrida, em vez de propagar o erro',
      () async {
        when(() => datasource.insert(any())).thenThrow(
          const PostgrestException(message: 'duplicate key', code: '23505'),
        );
        when(
          () => datasource.fetchByGooglePlaceId('ChIJ123'),
        ).thenAnswer((_) async => _row());

        final restaurant = await repository.create(
          createdBy: 'user-1',
          name: 'Madero',
          category: 'Restaurant',
          googlePlaceId: 'ChIJ123',
        );

        expect(restaurant.id, 'r-1');
        expect(restaurant.googlePlaceId, 'ChIJ123');
      },
    );

    test('23505 sem googlePlaceId não é mascarado - erro genuinamente '
        'inesperado, propaga como RestaurantRepositoryException', () async {
      when(() => datasource.insert(any())).thenThrow(
        const PostgrestException(message: 'duplicate key', code: '23505'),
      );

      expect(
        () => repository.create(
          createdBy: 'user-1',
          name: 'Bar do Zé',
          category: 'Bar',
        ),
        throwsA(isA<RestaurantRepositoryException>()),
      );
      verifyNever(() => datasource.fetchByGooglePlaceId(any()));
    });

    test('erro do Postgres diferente de 23505 nunca é tratado como sucesso - '
        'propaga normalmente', () async {
      when(() => datasource.insert(any())).thenThrow(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );

      expect(
        () => repository.create(
          createdBy: 'user-1',
          name: 'Madero',
          category: 'Restaurant',
          googlePlaceId: 'ChIJ123',
        ),
        throwsA(isA<RestaurantRepositoryException>()),
      );
      verifyNever(() => datasource.fetchByGooglePlaceId(any()));
    });

    test('23505 recuperado, mas o concorrente some antes da releitura - '
        'propaga o erro original em vez de forjar um resultado', () async {
      when(() => datasource.insert(any())).thenThrow(
        const PostgrestException(message: 'duplicate key', code: '23505'),
      );
      when(
        () => datasource.fetchByGooglePlaceId('ChIJ123'),
      ).thenAnswer((_) async => null);

      expect(
        () => repository.create(
          createdBy: 'user-1',
          name: 'Madero',
          category: 'Restaurant',
          googlePlaceId: 'ChIJ123',
        ),
        throwsA(isA<RestaurantRepositoryException>()),
      );
    });
  });
}
