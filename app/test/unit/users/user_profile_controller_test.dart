import 'dart:typed_data';

import 'package:app/features/users/application/user_profile_controller.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:app/features/users/presentation/states/user_profile_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

UserProfile _profile({String? fullName}) {
  return UserProfile(
    id: 'user-1',
    fullName: fullName ?? 'Ana',
    username: null,
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    followersCount: 0,
    followingCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockUserProfileRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockUserProfileRepository();
    container = ProviderContainer(
      overrides: [userProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é ProfileInitial', () {
    expect(
      container.read(userProfileControllerProvider),
      isA<ProfileInitial>(),
    );
  });

  group('loadProfile', () {
    test('sucesso -> ProfileLoaded', () async {
      when(
        () => repository.getProfile('user-1'),
      ).thenAnswer((_) async => _profile());

      await container
          .read(userProfileControllerProvider.notifier)
          .loadProfile('user-1');

      final status = container.read(userProfileControllerProvider);
      expect(status, isA<ProfileLoaded>());
      expect((status as ProfileLoaded).profile.fullName, 'Ana');
    });

    test('falha -> ProfileError', () async {
      when(() => repository.getProfile('user-1')).thenThrow(
        const UserProfileRepositoryException('Perfil não encontrado.'),
      );

      await container
          .read(userProfileControllerProvider.notifier)
          .loadProfile('user-1');

      expect(
        container.read(userProfileControllerProvider),
        isA<ProfileError>(),
      );
    });
  });

  group('updateProfile', () {
    test('sucesso -> ProfileUpdateSuccess', () async {
      when(
        () => repository.updateProfile(
          'user-1',
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          city: any(named: 'city'),
          stateProvince: any(named: 'stateProvince'),
        ),
      ).thenAnswer((_) async => _profile(fullName: 'Ana Souza'));

      await container
          .read(userProfileControllerProvider.notifier)
          .updateProfile('user-1', fullName: 'Ana Souza');

      final status = container.read(userProfileControllerProvider);
      expect(status, isA<ProfileUpdateSuccess>());
      expect((status as ProfileUpdateSuccess).profile.fullName, 'Ana Souza');
    });

    test('falha -> ProfileError', () async {
      when(
        () => repository.updateProfile(
          'user-1',
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          city: any(named: 'city'),
          stateProvince: any(named: 'stateProvince'),
        ),
      ).thenThrow(const UserProfileRepositoryException('Falha ao atualizar.'));

      await container
          .read(userProfileControllerProvider.notifier)
          .updateProfile('user-1', fullName: 'Ana Souza');

      expect(
        container.read(userProfileControllerProvider),
        isA<ProfileError>(),
      );
    });
  });

  group('updateAvatar', () {
    test('sucesso -> ProfileUpdateSuccess', () async {
      when(
        () => repository.updateAvatar(
          'user-1',
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      ).thenAnswer((_) async => _profile());

      await container
          .read(userProfileControllerProvider.notifier)
          .updateAvatar('user-1', bytes: Uint8List(0), fileExtension: 'jpg');

      expect(
        container.read(userProfileControllerProvider),
        isA<ProfileUpdateSuccess>(),
      );
    });

    test('falha no upload -> ProfileError', () async {
      when(
        () => repository.updateAvatar(
          'user-1',
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      ).thenThrow(const UserProfileRepositoryException('Falha no upload.'));

      await container
          .read(userProfileControllerProvider.notifier)
          .updateAvatar('user-1', bytes: Uint8List(0), fileExtension: 'jpg');

      expect(
        container.read(userProfileControllerProvider),
        isA<ProfileError>(),
      );
    });
  });
}
