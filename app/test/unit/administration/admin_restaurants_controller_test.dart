import 'package:app/core/models/paged_result.dart';
import 'package:app/features/administration/application/admin_restaurants_controller.dart';
import 'package:app/features/administration/data/audit_log_repository_impl.dart';
import 'package:app/features/administration/domain/audit_log_repository.dart';
import 'package:app/features/administration/presentation/states/admin_restaurants_status.dart';
import 'package:app/features/restaurants/data/restaurant_repository_impl.dart';
import 'package:app/features/restaurants/domain/restaurant.dart';
import 'package:app/features/restaurants/domain/restaurant_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class MockAuditLogRepository extends Mock implements AuditLogRepository {}

Restaurant _restaurant({String id = 'r-1', String status = 'active'}) {
  return Restaurant(
    id: id,
    name: 'Bar do Zé',
    category: 'Bar',
    totalReviews: 0,
    status: status,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockRestaurantRepository restaurantRepository;
  late MockAuditLogRepository auditLogRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    restaurantRepository = MockRestaurantRepository();
    auditLogRepository = MockAuditLogRepository();
    container = ProviderContainer(
      overrides: [
        restaurantRepositoryProvider.overrideWithValue(restaurantRepository),
        auditLogRepositoryProvider.overrideWithValue(auditLogRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é AdminRestaurantsInitial', () {
    expect(
      container.read(adminRestaurantsControllerProvider),
      isA<AdminRestaurantsInitial>(),
    );
  });

  test('load com resultados -> AdminRestaurantsLoaded', () async {
    when(
      () =>
          restaurantRepository.listAllForAdmin(query: null, page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(adminRestaurantsControllerProvider.notifier).load();

    expect(
      container.read(adminRestaurantsControllerProvider),
      isA<AdminRestaurantsLoaded>(),
    );
  });

  test('updateStatus arquiva e registra auditoria', () async {
    when(
      () =>
          restaurantRepository.listAllForAdmin(query: null, page: 1, limit: 20),
    ).thenAnswer(
      (_) async => PagedResult(
        items: [_restaurant()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => restaurantRepository.updateAsAdmin('r-1', status: 'archived'),
    ).thenAnswer((_) async => _restaurant(status: 'archived'));
    when(
      () => auditLogRepository.log(
        actorId: any(named: 'actorId'),
        action: any(named: 'action'),
        entity: any(named: 'entity'),
        entityId: any(named: 'entityId'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});

    final notifier = container.read(
      adminRestaurantsControllerProvider.notifier,
    );
    await notifier.load();
    await notifier.updateStatus('r-1', status: 'archived', actorId: 'admin-1');

    verify(
      () => restaurantRepository.updateAsAdmin('r-1', status: 'archived'),
    ).called(1);
    verify(
      () => auditLogRepository.log(
        actorId: 'admin-1',
        action: 'archive_restaurant',
        entity: 'restaurant',
        entityId: 'r-1',
        metadata: {'status': 'archived'},
      ),
    ).called(1);
  });
}
