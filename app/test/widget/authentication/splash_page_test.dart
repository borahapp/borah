import 'package:app/core/lazy_sync/lazy_sync_dispatcher.dart';
import 'package:app/core/lazy_sync/lazy_sync_task.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/authentication/presentation/pages/splash_page.dart';
import 'package:app/features/authentication/presentation/states/auth_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthenticatedController extends AuthController {
  @override
  AuthStatus build() =>
      const Authenticated(userId: 'user-1', email: 'user@teste.com');

  @override
  Future<void> restoreSession() async {}
}

class _FakeUnauthenticatedController extends AuthController {
  @override
  AuthStatus build() => const Unauthenticated();

  @override
  Future<void> restoreSession() async {}
}

class _RecordingTask implements LazySyncTask {
  int callCount = 0;

  @override
  Future<void> run() async {
    callCount++;
  }
}

/// FASE C.4 - único ponto do app hoje que aciona `LazySyncDispatcher`
/// (ver doc-comment de `SplashPage._restoreAndRedirect`).
Widget _wrap({
  required AuthController Function() authControllerFactory,
  required List<LazySyncTask> lazySyncTasks,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashPage()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Login')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(authControllerFactory),
      lazySyncTasksProvider.overrideWithValue(lazySyncTasks),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets(
    'usuário autenticado: aciona LazySyncDispatcher.runAll() e navega '
    'para Home sem esperar por ele (melhor esforço)',
    (tester) async {
      final task = _RecordingTask();

      await tester.pumpWidget(
        _wrap(
          authControllerFactory: _FakeAuthenticatedController.new,
          lazySyncTasks: [task],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(task.callCount, 1);
    },
  );

  testWidgets(
    'usuário não autenticado: nunca aciona LazySyncDispatcher, navega '
    'para Login',
    (tester) async {
      final task = _RecordingTask();

      await tester.pumpWidget(
        _wrap(
          authControllerFactory: _FakeUnauthenticatedController.new,
          lazySyncTasks: [task],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(task.callCount, 0);
    },
  );
}
