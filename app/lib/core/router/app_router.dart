import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/auth_controller.dart';
import '../../features/authentication/presentation/pages/email_verification_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/password_reset_page.dart';
import '../../features/authentication/presentation/pages/signup_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/states/auth_status.dart';

const _authRoutes = {
  '/login',
  '/signup',
  '/password-reset',
  '/email-verification',
};

/// Notifica o GoRouter quando o AuthStatus muda, sem recriar o router
/// inteiro (evita reset da pilha de navegação a cada mudança de estado).
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

/// Root router (AR-02). A Splash decide o redirecionamento inicial
/// (DV-01) — o redirect abaixo só protege rotas após a decisão inicial,
/// e nunca consulta o Supabase diretamente (lê apenas authControllerProvider).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == '/') return null; // a Splash decide sozinha

      final status = ref.read(authControllerProvider);
      final isAuthRoute = _authRoutes.contains(location);

      if (status is Authenticated && isAuthRoute) return '/home';
      if (status is! Authenticated && location == '/home') return '/login';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetPage(),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _BootstrapPlaceholderPage(),
      ),
    ],
  );
});

class _BootstrapPlaceholderPage extends StatelessWidget {
  const _BootstrapPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('BORAH')));
  }
}
