import 'dart:async';

import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/authentication/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget _wrap(MockAuthRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const LoginPage()),
      GoRoute(
        path: '/password-reset',
        builder: (_, _) => const Scaffold(body: Text('Password Reset Page')),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const Scaffold(body: Text('Signup Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthUserData?>.empty());
  });

  testWidgets('renderização inicial mostra título, campos e ações', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('BORAH'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('campos vazios exibem erro de validação e não chamam signIn', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('estado de carregamento mostra indicador no botão', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => completer.future);
    when(() => repository.currentUser).thenReturn(null);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@borah.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('erro de autenticação exibe snackbar com a mensagem', (
    tester,
  ) async {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthRepositoryException('Credenciais inválidas.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@borah.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'errada');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Credenciais inválidas.'), findsOneWidget);
  });

  testWidgets('"Criar conta" navega para a tela de cadastro', (tester) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Signup Page'), findsOneWidget);
  });

  group('responsividade', () {
    for (final size in [
      const Size(320, 640), // smartphone pequeno
      const Size(412, 915), // smartphone médio/grande
      const Size(768, 1024), // tablet
    ]) {
      testWidgets('renderiza sem overflow em ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('BORAH'), findsOneWidget);
      });
    }
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });
}
