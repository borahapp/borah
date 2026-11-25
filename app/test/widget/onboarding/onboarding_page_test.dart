import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/authentication/presentation/states/auth_status.dart';
import 'package:app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Rastreia se `acknowledgeOnboardingShown()` foi chamado - mesmo
/// princípio de `_FakeAuthenticatedController` (splash_page_test.dart),
/// só que também observando esta chamada específica.
class _TrackingAuthController extends AuthController {
  bool acknowledgeCalled = false;

  @override
  AuthStatus build() =>
      const Authenticated(userId: 'user-1', email: 'user@teste.com');

  @override
  void acknowledgeOnboardingShown() {
    acknowledgeCalled = true;
  }
}

Widget _wrap(_TrackingAuthController controller) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authControllerProvider.overrideWith(() => controller)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late _TrackingAuthController controller;

  setUp(() {
    controller = _TrackingAuthController();
  });

  testWidgets('ao aparecer, já marca o tutorial como exibido '
      '(acknowledgeOnboardingShown)', (tester) async {
    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(controller.acknowledgeCalled, isTrue);
  });

  testWidgets('mostra o 1º slide e os botões "Pular"/"Próximo"', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(
      find.text('Avalie cada restaurante que você visitar'),
      findsOneWidget,
    );
    expect(find.text('Pular'), findsOneWidget);
    expect(find.text('Próximo'), findsOneWidget);
    expect(find.text('Começar'), findsNothing);
  });

  testWidgets('tocar em "Próximo" avança pelos 3 slides até "Começar"', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Organize rolês com seus grupos'), findsOneWidget);

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Mostre o seu perfil'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    expect(find.text('Próximo'), findsNothing);
  });

  testWidgets('tocar em "Começar" no último slide navega para /home', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    expect(find.text('Home Page'), findsOneWidget);
  });

  testWidgets('tocar em "Pular" no 1º slide navega direto para /home', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.text('Home Page'), findsOneWidget);
  });
}
