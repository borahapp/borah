import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/authentication/presentation/states/auth_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthUserData?>.empty());
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é AuthInitial', () {
    expect(container.read(authControllerProvider), isA<AuthInitial>());
  });

  group('restoreSession', () {
    test('sem sessão salva -> Unauthenticated', () async {
      when(() => repository.currentUser).thenReturn(null);

      await container.read(authControllerProvider.notifier).restoreSession();

      expect(container.read(authControllerProvider), isA<Unauthenticated>());
    });

    test('com sessão salva -> Authenticated', () async {
      when(
        () => repository.currentUser,
      ).thenReturn((userId: 'user-1', email: 'a@borah.com'));

      await container.read(authControllerProvider.notifier).restoreSession();

      final status = container.read(authControllerProvider);
      expect(status, isA<Authenticated>());
      expect((status as Authenticated).userId, 'user-1');
    });
  });

  group('signIn', () {
    test('credenciais válidas -> Authenticated', () async {
      when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => repository.currentUser,
      ).thenReturn((userId: 'user-1', email: 'a@borah.com'));

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@borah.com', password: '123456');

      expect(container.read(authControllerProvider), isA<Authenticated>());
    });

    test('credenciais inválidas -> AuthError', () async {
      when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthRepositoryException('Invalid login credentials'));

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@borah.com', password: 'errada');

      expect(container.read(authControllerProvider), isA<AuthError>());
    });
  });

  group('signUp', () {
    test('cadastro válido -> EmailVerificationPending', () async {
      when(
        () => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await container
          .read(authControllerProvider.notifier)
          .signUp(name: 'Ana', email: 'ana@borah.com', password: '123456');

      final status = container.read(authControllerProvider);
      expect(status, isA<EmailVerificationPending>());
      expect((status as EmailVerificationPending).email, 'ana@borah.com');
    });

    test('confirmação de e-mail desabilitada (sessão criada imediatamente) '
        '-> Authenticated', () async {
      when(
        () => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => repository.currentUser,
      ).thenReturn((userId: 'user-1', email: 'ana@borah.com'));

      await container
          .read(authControllerProvider.notifier)
          .signUp(name: 'Ana', email: 'ana@borah.com', password: '123456');

      final status = container.read(authControllerProvider);
      expect(status, isA<Authenticated>());
      expect((status as Authenticated).userId, 'user-1');
    });

    test('e-mail já utilizado -> AuthError', () async {
      when(
        () => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthRepositoryException('User already registered'));

      await container
          .read(authControllerProvider.notifier)
          .signUp(name: 'Ana', email: 'ana@borah.com', password: '123456');

      expect(container.read(authControllerProvider), isA<AuthError>());
    });
  });

  group('signOut', () {
    test('sucesso -> Unauthenticated', () async {
      when(() => repository.signOut()).thenAnswer((_) async {});

      await container.read(authControllerProvider.notifier).signOut();

      expect(container.read(authControllerProvider), isA<Unauthenticated>());
    });

    test('falha -> relança AuthRepositoryException e mantém o estado anterior '
        '(RC-02: evita redirect indevido de rotas protegidas)', () async {
      when(
        () => repository.signOut(),
      ).thenThrow(const AuthRepositoryException('Falha de rede.'));

      final notifier = container.read(authControllerProvider.notifier);
      final stateBefore = container.read(authControllerProvider);

      await expectLater(
        notifier.signOut(),
        throwsA(isA<AuthRepositoryException>()),
      );
      expect(container.read(authControllerProvider), stateBefore);
    });
  });

  group('resendVerificationEmail', () {
    test('sucesso não altera o estado', () async {
      when(
        () => repository.resendVerificationEmail(any()),
      ).thenAnswer((_) async {});

      final notifier = container.read(authControllerProvider.notifier);
      final stateBefore = container.read(authControllerProvider);

      await notifier.resendVerificationEmail('ana@borah.com');

      expect(container.read(authControllerProvider), stateBefore);
      verify(
        () => repository.resendVerificationEmail('ana@borah.com'),
      ).called(1);
    });

    test('falha relança AuthRepositoryException e mantém o estado', () async {
      when(() => repository.resendVerificationEmail(any())).thenThrow(
        const AuthRepositoryException(
          'Aguarde antes de solicitar um novo envio.',
        ),
      );

      final notifier = container.read(authControllerProvider.notifier);
      final stateBefore = container.read(authControllerProvider);

      await expectLater(
        notifier.resendVerificationEmail('ana@borah.com'),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Aguarde antes de solicitar um novo envio.',
          ),
        ),
      );
      expect(container.read(authControllerProvider), stateBefore);
    });
  });

  group('requestPasswordReset', () {
    test('e-mail válido -> PasswordResetSent', () async {
      when(
        () => repository.requestPasswordReset(any()),
      ).thenAnswer((_) async {});

      await container
          .read(authControllerProvider.notifier)
          .requestPasswordReset('ana@borah.com');

      final status = container.read(authControllerProvider);
      expect(status, isA<PasswordResetSent>());
      expect((status as PasswordResetSent).email, 'ana@borah.com');
    });

    test('falha no envio -> AuthError', () async {
      when(
        () => repository.requestPasswordReset(any()),
      ).thenThrow(const AuthRepositoryException('User not found'));

      await container
          .read(authControllerProvider.notifier)
          .requestPasswordReset('inexistente@borah.com');

      expect(container.read(authControllerProvider), isA<AuthError>());
    });
  });
}
