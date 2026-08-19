import 'package:app/features/restaurants/data/restaurant_remote_datasource.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
}
