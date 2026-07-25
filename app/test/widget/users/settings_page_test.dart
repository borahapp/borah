import 'dart:async';

import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/users/presentation/pages/settings_page.dart';
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
      GoRoute(path: '/', builder: (_, _) => const SettingsPage()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const Scaffold(body: Text('Edit Profile Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Localiza o botão "Sair" de dentro do diálogo de confirmação -
/// evita ambiguidade com o `ListTile` de mesmo rótulo por trás do diálogo.
Finder _confirmButton() => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(TextButton, 'Sair'),
);

Future<void> _openLogoutDialog(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ListTile, 'Sair'));
  await tester.pumpAndSettle();
}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthUserData?>.empty());
  });

  testWidgets('tocar em "Sair" abre diálogo de confirmação', (tester) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await _openLogoutDialog(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    verifyNever(() => repository.signOut());
  });

  testWidgets('cancelar o diálogo não encerra a sessão', (tester) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await _openLogoutDialog(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => repository.signOut());
  });

  testWidgets('confirmar mostra indicador de carregamento durante o logout', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(() => repository.signOut()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await _openLogoutDialog(tester);
    await tester.tap(_confirmButton());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    verify(() => repository.signOut()).called(1);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('falha ao encerrar a sessão mostra snackbar e mantém a tela', (
    tester,
  ) async {
    when(
      () => repository.signOut(),
    ).thenThrow(const AuthRepositoryException('Falha de rede.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await _openLogoutDialog(tester);
    await tester.tap(_confirmButton());
    await tester.pumpAndSettle();

    expect(find.text('Falha de rede.'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('tocar em "Editar perfil" navega para a edição de perfil', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Editar perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile Page'), findsOneWidget);
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
        expect(find.widgetWithText(ListTile, 'Sair'), findsOneWidget);
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
