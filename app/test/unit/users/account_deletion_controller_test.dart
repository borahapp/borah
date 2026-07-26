import 'package:app/core/storage/app_storage.dart';
import 'package:app/core/storage/storage_repository.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/users/application/account_deletion_controller.dart';
import 'package:app/features/users/data/account_deletion_repository_impl.dart';
import 'package:app/features/users/domain/account_deletion_repository.dart';
import 'package:app/features/users/presentation/states/account_deletion_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAccountDeletionRepository extends Mock
    implements AccountDeletionRepository {}

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockAccountDeletionRepository accountDeletionRepository;
  late MockStorageRepository storageRepository;
  late ProviderContainer container;

  setUp(() {
    authRepository = MockAuthRepository();
    accountDeletionRepository = MockAccountDeletionRepository();
    storageRepository = MockStorageRepository();
    AppStorage.debugServiceOverride = StorageService(storageRepository);

    when(
      () => authRepository.onAuthStateChange,
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        accountDeletionRepositoryProvider.overrideWithValue(
          accountDeletionRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() {
    AppStorage.debugServiceOverride = null;
  });

  void stubHappyPath() {
    when(
      () => authRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => accountDeletionRepository.deleteOwnAccount(),
    ).thenAnswer((_) async {});
    when(() => authRepository.signOut()).thenAnswer((_) async {});
  }

  test('estado inicial é AccountDeletionInitial', () {
    expect(
      container.read(accountDeletionControllerProvider),
      isA<AccountDeletionInitial>(),
    );
  });

  group('reautenticação', () {
    test(
      'senha incorreta (AuthRepositoryException) -> '
      'AccountDeletionReauthenticationError com a mensagem original',
      () async {
        when(
          () => authRepository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthRepositoryException('Senha incorreta.'));

        await container
            .read(accountDeletionControllerProvider.notifier)
            .deleteAccount(email: 'ana@borah.com', password: 'errada');

        final status = container.read(accountDeletionControllerProvider);
        expect(status, isA<AccountDeletionReauthenticationError>());
        expect(
          (status as AccountDeletionReauthenticationError).message,
          'Senha incorreta.',
        );
        verifyNever(() => accountDeletionRepository.deleteOwnAccount());
      },
    );

    test('erro genérico na reautenticação -> mensagem amigável', () async {
      when(
        () => authRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('boom'));

      await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(email: 'ana@borah.com', password: 'x');

      final status = container.read(accountDeletionControllerProvider);
      expect(status, isA<AccountDeletionReauthenticationError>());
      expect(
        (status as AccountDeletionReauthenticationError).message,
        'Não foi possível confirmar sua senha.',
      );
    });
  });

  group('exclusão', () {
    test('sucesso sem avatarPath -> não toca o Storage, chama signOut, '
        'AccountDeletionSuccess', () async {
      stubHappyPath();

      await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(email: 'ana@borah.com', password: 'certa');

      expect(
        container.read(accountDeletionControllerProvider),
        isA<AccountDeletionSuccess>(),
      );
      verifyNever(
        () => storageRepository.delete(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
        ),
      );
      verify(() => authRepository.signOut()).called(1);
    });

    test('sucesso com avatarPath -> apaga o avatar do Storage', () async {
      stubHappyPath();
      when(
        () => storageRepository.delete(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
        ),
      ).thenAnswer((_) async {});

      await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(
            email: 'ana@borah.com',
            password: 'certa',
            avatarPath: 'user-1/avatar.jpg',
          );

      verify(
        () => storageRepository.delete(
          bucket: 'avatars',
          path: 'user-1/avatar.jpg',
        ),
      ).called(1);
      expect(
        container.read(accountDeletionControllerProvider),
        isA<AccountDeletionSuccess>(),
      );
    });

    test('falha ao apagar o avatar não impede a exclusão da conta '
        '(best-effort)', () async {
      stubHappyPath();
      when(
        () => storageRepository.delete(
          bucket: any(named: 'bucket'),
          path: any(named: 'path'),
        ),
      ).thenThrow(Exception('falha de rede'));

      await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(
            email: 'ana@borah.com',
            password: 'certa',
            avatarPath: 'user-1/avatar.jpg',
          );

      expect(
        container.read(accountDeletionControllerProvider),
        isA<AccountDeletionSuccess>(),
      );
      verify(() => accountDeletionRepository.deleteOwnAccount()).called(1);
    });

    test('AccountDeletionRepositoryException -> AccountDeletionError com a '
        'mensagem original', () async {
      when(
        () => authRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(() => accountDeletionRepository.deleteOwnAccount()).thenThrow(
        const AccountDeletionRepositoryException('Falha no servidor.'),
      );

      await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(email: 'ana@borah.com', password: 'certa');

      final status = container.read(accountDeletionControllerProvider);
      expect(status, isA<AccountDeletionError>());
      expect((status as AccountDeletionError).message, 'Falha no servidor.');
      verifyNever(() => authRepository.signOut());
    });

    test('erro genérico na exclusão -> mensagem amigável', () async {
      when(
        () => authRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => accountDeletionRepository.deleteOwnAccount(),
      ).thenThrow(Exception('boom'));

      await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(email: 'ana@borah.com', password: 'certa');

      final status = container.read(accountDeletionControllerProvider);
      expect(status, isA<AccountDeletionError>());
      expect(
        (status as AccountDeletionError).message,
        'Não foi possível excluir sua conta. Tente novamente.',
      );
    });

    test('falha ao encerrar a sessão local não impede o sucesso '
        '(best-effort, a conta já foi excluída no servidor)', () async {
      when(
        () => authRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => accountDeletionRepository.deleteOwnAccount(),
      ).thenAnswer((_) async {});
      when(
        () => authRepository.signOut(),
      ).thenThrow(const AuthRepositoryException('Falha ao sair.'));

      await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(email: 'ana@borah.com', password: 'certa');

      expect(
        container.read(accountDeletionControllerProvider),
        isA<AccountDeletionSuccess>(),
      );
    });
  });

  test('reset() volta ao estado AccountDeletionInitial após um erro', () async {
    when(
      () => authRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthRepositoryException('Senha incorreta.'));

    final notifier = container.read(accountDeletionControllerProvider.notifier);
    await notifier.deleteAccount(email: 'ana@borah.com', password: 'errada');
    expect(
      container.read(accountDeletionControllerProvider),
      isA<AccountDeletionReauthenticationError>(),
    );

    notifier.reset();

    expect(
      container.read(accountDeletionControllerProvider),
      isA<AccountDeletionInitial>(),
    );
  });
}
