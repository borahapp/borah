import 'dart:async';

import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/authentication/presentation/pages/signup_page.dart';
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
      GoRoute(path: '/', builder: (_, _) => const SignupPage()),
      GoRoute(
        path: '/email-verification',
        builder: (_, _) =>
            const Scaffold(body: Text('Email Verification Page')),
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

  testWidgets('renderização inicial mostra os três campos e a ação', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.widgetWithText(FilledButton, 'Criar conta'), findsOneWidget);
  });

  testWidgets('campos vazios exibem erro de validação e não chamam signUp', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha deve ter ao menos 6 caracteres.'),
      findsOneWidget,
    );
    verifyNever(
      () => repository.signUp(
        name: any(named: 'name'),
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
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@borah.com');
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('erro no cadastro exibe snackbar com a mensagem', (tester) async {
    when(
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthRepositoryException('E-mail já utilizado.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@borah.com');
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail já utilizado.'), findsOneWidget);
  });

  testWidgets('cadastro concluído navega para verificação de e-mail', (
    tester,
  ) async {
    when(
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@borah.com');
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Email Verification Page'), findsOneWidget);
  });

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

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.widgetWithText(FilledButton, 'Criar conta'),
          findsOneWidget,
        );
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
