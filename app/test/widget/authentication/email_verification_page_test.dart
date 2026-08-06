import 'dart:async';

import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/authentication/presentation/pages/email_verification_page.dart';
import 'package:app/features/authentication/presentation/states/auth_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Semeia o `AuthStatus` diretamente, pulando o listener de
/// `onAuthStateChange` do `build()` real - mesma técnica já usada nas
/// rodadas anteriores para isolar o widget do bootstrap de autenticação.
class _SeededAuthController extends AuthController {
  _SeededAuthController(this._initial);

  final AuthStatus _initial;

  @override
  AuthStatus build() => _initial;
}

Widget _wrap(MockAuthRepository repository, {required AuthStatus initial}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const EmailVerificationPage()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Login Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authControllerProvider.overrideWith(() => _SeededAuthController(initial)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  testWidgets('sem e-mail pendente, o botão de reenvio fica desabilitado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(repository, initial: const Unauthenticated()),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Reenviar e-mail'),
    );
    expect(button.onPressed, isNull);
    verifyNever(() => repository.resendVerificationEmail(any()));
  });

  testWidgets('estado de carregamento mostra indicador no botão', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(
      () => repository.resendVerificationEmail(any()),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      _wrap(
        repository,
        initial: const EmailVerificationPending('ana@borah.com'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reenviar e-mail'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('reenvio com sucesso mostra snackbar de confirmação', (
    tester,
  ) async {
    when(
      () => repository.resendVerificationEmail(any()),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrap(
        repository,
        initial: const EmailVerificationPending('ana@borah.com'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reenviar e-mail'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail de confirmação reenviado.'), findsOneWidget);
    verify(() => repository.resendVerificationEmail('ana@borah.com')).called(1);
  });

  testWidgets('falha no reenvio mostra a mensagem retornada pelo repositório', (
    tester,
  ) async {
    when(() => repository.resendVerificationEmail(any())).thenThrow(
      const AuthRepositoryException(
        'Aguarde antes de solicitar um novo envio.',
      ),
    );

    await tester.pumpWidget(
      _wrap(
        repository,
        initial: const EmailVerificationPending('ana@borah.com'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reenviar e-mail'));
    await tester.pumpAndSettle();

    expect(
      find.text('Aguarde antes de solicitar um novo envio.'),
      findsOneWidget,
    );
  });

  testWidgets('"Voltar para o login" navega para a tela de Login', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        repository,
        initial: const EmailVerificationPending('ana@borah.com'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voltar para o login'));
    await tester.pumpAndSettle();

    expect(find.text('Login Page'), findsOneWidget);
  });

  testWidgets(
    'seta de voltar do AppTopBar também navega para a tela de Login',
    (tester) async {
      // RC-03 Sprint 2: esta tela só é alcançada via `context.go()`
      // (nunca `push()`), então `Navigator.canPop()` é sempre `false` -
      // sem `leading` explícito no `AppTopBar`, nenhuma seta apareceria.
      // Este teste existe para travar esse comportamento.
      await tester.pumpWidget(
        _wrap(
          repository,
          initial: const EmailVerificationPending('ana@borah.com'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppBar, 'Confirmação de e-mail'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    },
  );

  group('responsividade', () {
    for (final size in [
      const Size(320, 640),
      const Size(412, 915),
      const Size(768, 1024),
    ]) {
      testWidgets('renderiza sem overflow em ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            repository,
            initial: const EmailVerificationPending('ana@borah.com'),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.widgetWithText(OutlinedButton, 'Reenviar e-mail'),
          findsOneWidget,
        );
      });
    }
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(
        repository,
        initial: const EmailVerificationPending('ana@borah.com'),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });
}
