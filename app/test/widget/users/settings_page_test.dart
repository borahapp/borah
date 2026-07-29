import 'dart:async';

import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:app/features/users/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

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
    ).thenAnswer((_) => const Stream<AuthSessionUpdate>.empty());
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

  group('Excluir conta (RC-04C)', () {
    late MockAuthRepository authenticatedRepository;
    late MockUserProfileRepository profileRepository;
    late ProviderContainer container;

    Widget wrapAuthenticated() {
      final router = GoRouter(
        initialLocation: '/',
        routes: [GoRoute(path: '/', builder: (_, _) => const SettingsPage())],
      );
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    setUp(() {
      authenticatedRepository = MockAuthRepository();
      profileRepository = MockUserProfileRepository();
      when(() => authenticatedRepository.onAuthStateChange).thenAnswer(
        (_) => Stream.value((
          event: AuthSessionEvent.signedIn,
          user: (userId: 'user-1', email: 'ana@borah.com'),
        )),
      );
      when(() => profileRepository.getProfile('user-1')).thenAnswer(
        (_) async => UserProfile(
          id: 'user-1',
          fullName: 'Ana',
          bio: null,
          avatarUrl: null,
          city: null,
          state: null,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authenticatedRepository),
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
        ],
      );
      addTearDown(container.dispose);
      // Aquece `authControllerProvider` (constrói o Notifier e registra o
      // listener do stream) ANTES do teste interagir - sem isso, a
      // primeira leitura aconteceria só dentro do `onTap`, no mesmo
      // instante síncrono em que o valor ainda seria `AuthInitial` (o
      // stream de autenticação só entrega seu valor num microtask
      // seguinte à inscrição).
      container.read(authControllerProvider);
    });

    testWidgets('tocar em "Excluir conta" abre o diálogo de confirmação', (
      tester,
    ) async {
      await tester.pumpWidget(wrapAuthenticated());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Excluir conta'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Esta ação é permanente'), findsOneWidget);
    });
  });
}
