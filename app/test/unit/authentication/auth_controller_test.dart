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
    ).thenAnswer((_) => const Stream<AuthSessionUpdate>.empty());
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

  // RC-04E: eventos do stream de sessão além de signedIn/signedOut.
  group('onAuthStateChange - eventos do stream', () {
    test('evento passwordRecovery -> PasswordRecoveryInProgress', () async {
      when(() => repository.onAuthStateChange).thenAnswer(
        (_) => Stream.value((
          event: AuthSessionEvent.passwordRecovery,
          user: (userId: 'user-1', email: 'ana@borah.com'),
        )),
      );

      // O provider é lazy - precisa ser lido para o listener em build()
      // ser registrado e o valor do stream ser entregue (mesmo padrão de
      // "aquecimento" já usado em settings_page_test.dart, RC-04C).
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(authControllerProvider),
        isA<PasswordRecoveryInProgress>(),
      );
    });

    test(
      'erro no stream (link de recuperação inválido/expirado) -> AuthError',
      () async {
        when(() => repository.onAuthStateChange).thenAnswer(
          (_) => Stream<AuthSessionUpdate>.error(
            const AuthRepositoryException(
              'Este link expirou. Solicite um novo.',
            ),
          ),
        );

        container.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);

        final status = container.read(authControllerProvider);
        expect(status, isA<AuthError>());
        expect(
          (status as AuthError).message,
          'Este link expirou. Solicite um novo.',
        );
      },
    );
  });

  group('updatePassword', () {
    test('sucesso -> Authenticated', () async {
      when(() => repository.updatePassword(any())).thenAnswer((_) async {});
      when(
        () => repository.currentUser,
      ).thenReturn((userId: 'user-1', email: 'ana@borah.com'));

      await container
          .read(authControllerProvider.notifier)
          .updatePassword('novaSenha123');

      expect(container.read(authControllerProvider), isA<Authenticated>());
    });

    test('falha -> volta para PasswordRecoveryInProgress e guarda a mensagem '
        'de erro para consumo único', () async {
      when(() => repository.updatePassword(any())).thenThrow(
        const AuthRepositoryException(
          'A nova senha deve ser diferente da senha atual.',
        ),
      );

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.updatePassword('mesmaSenha');

      expect(
        container.read(authControllerProvider),
        isA<PasswordRecoveryInProgress>(),
      );
      expect(
        notifier.consumePasswordRecoveryError(),
        'A nova senha deve ser diferente da senha atual.',
      );
      expect(notifier.consumePasswordRecoveryError(), isNull);
    });
  });

  group('signOut', () {
    test('sucesso -> Unauthenticated', () async {
      when(() => repository.signOut()).thenAnswer((_) async {});

      await container.read(authControllerProvider.notifier).signOut();

      expect(container.read(authControllerProvider), isA<Unauthenticated>());
    });

    // RC-02: signOut() não expressa falha via `state` (evitaria redirect
    // indevido de rotas protegidas) - relança para o chamador tratar.
    test(
      'falha -> mantém o estado e relança AuthRepositoryException',
      () async {
        when(
          () => repository.signOut(),
        ).thenThrow(const AuthRepositoryException('Falha de rede.'));

        final notifier = container.read(authControllerProvider.notifier);
        final stateBefore = container.read(authControllerProvider);

        await expectLater(
          notifier.signOut(),
          throwsA(
            isA<AuthRepositoryException>().having(
              (e) => e.message,
              'message',
              'Falha de rede.',
            ),
          ),
        );
        expect(container.read(authControllerProvider), stateBefore);
      },
    );
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

  // Mesmo motivo de signOut(): reenviar não é uma transição de status de
  // autenticação, então o estado global nunca muda aqui.
  group('resendVerificationEmail', () {
    test('sucesso -> mantém o estado', () async {
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

    test(
      'falha -> mantém o estado e relança AuthRepositoryException',
      () async {
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
      },
    );
  });
}
