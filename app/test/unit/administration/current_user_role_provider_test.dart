import 'package:app/features/administration/application/current_user_role_provider.dart';
import 'package:app/features/administration/data/admin_role_repository_impl.dart';
import 'package:app/features/administration/domain/admin_role_repository.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRoleRepository extends Mock implements AdminRoleRepository {}

void main() {
  late MockAdminRoleRepository repository;

  setUp(() {
    repository = MockAdminRoleRepository();
  });

  test('sem usuário logado -> null, sem consultar o repositório', () async {
    final container = ProviderContainer(
      overrides: [
        adminRoleRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    final role = await container.read(currentUserRoleProvider.future);

    expect(role, isNull);
    verifyNever(() => repository.getRole(any()));
  });

  test('usuário logado e administrador -> retorna o papel', () async {
    when(() => repository.getRole('user-1')).thenAnswer((_) async => 'admin');
    final container = ProviderContainer(
      overrides: [
        adminRoleRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue('user-1'),
      ],
    );
    addTearDown(container.dispose);

    final role = await container.read(currentUserRoleProvider.future);

    expect(role, 'admin');
  });

  test('usuário logado sem papel administrativo -> null', () async {
    when(() => repository.getRole('user-2')).thenAnswer((_) async => null);
    final container = ProviderContainer(
      overrides: [
        adminRoleRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue('user-2'),
      ],
    );
    addTearDown(container.dispose);

    final role = await container.read(currentUserRoleProvider.future);

    expect(role, isNull);
  });
}
