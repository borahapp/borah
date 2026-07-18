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
import '../../features/users/presentation/pages/change_avatar_page.dart';
import '../../features/users/presentation/pages/edit_profile_page.dart';
import '../../features/users/presentation/pages/profile_page.dart';
import '../../features/users/presentation/pages/settings_page.dart';

const _authRoutes = {
  '/login',
  '/signup',
  '/password-reset',
  '/email-verification',
};

/// Rotas que exigem usuário autenticado (DV-01 "proteção de rotas").
const _protectedRoutes = {
  '/home',
  '/profile',
  '/profile/edit',
  '/profile/avatar',
  '/settings',
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
      final isProtectedRoute = _protectedRoutes.contains(location);

      if (status is Authenticated && isAuthRoute) return '/home';
      if (status is! Authenticated && isProtectedRoute) return '/login';

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
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/avatar',
        builder: (context, state) => const ChangeAvatarPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

/// Placeholder até a implementação da Home real (fora do escopo do DV-01/DV-02).
class _BootstrapPlaceholderPage extends StatelessWidget {
  const _BootstrapPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('BORAH'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => GoRouter.of(context).push('/profile'),
              child: const Text('Ver perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
