import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/animations/app_motion.dart';
import '../../design_system/components/buttons/app_text_button.dart';
import '../../features/authentication/application/auth_controller.dart';
import '../../features/authentication/presentation/pages/email_verification_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/password_reset_page.dart';
import '../../features/authentication/presentation/pages/signup_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/states/auth_status.dart';
import '../../features/administration/presentation/pages/admin_dashboard_page.dart';
import '../../features/administration/presentation/pages/admin_restaurants_page.dart';
import '../../features/administration/presentation/pages/admin_roles_page.dart';
import '../../features/administration/presentation/pages/admin_users_page.dart';
import '../../features/administration/presentation/pages/audit_log_page.dart';
import '../../features/administration/presentation/pages/moderation_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/gamification/presentation/pages/gamification_profile_page.dart';
import '../../features/gamification/presentation/pages/ranking_users_page.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/presentation/pages/notification_detail_page.dart';
import '../../features/notifications/presentation/pages/notification_preferences_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/rankings/presentation/pages/rankings_page.dart';
import '../../features/restaurants/presentation/pages/create_restaurant_page.dart';
import '../../features/restaurants/presentation/pages/restaurant_detail_page.dart';
import '../../features/restaurants/presentation/pages/restaurants_search_page.dart';
import '../../features/reviews/presentation/pages/create_review_page.dart';
import '../../features/reviews/presentation/pages/edit_review_page.dart';
import '../../features/reviews/presentation/pages/review_detail_page.dart';
import '../../features/reviews/presentation/pages/reviews_list_page.dart';
import '../../features/social/presentation/pages/comments_page.dart';
import '../../features/social/presentation/pages/feed_page.dart';
import '../../features/social/presentation/pages/follow_list_page.dart';
import '../../features/social/presentation/pages/public_profile_page.dart';
import '../../features/social/presentation/states/follow_list_status.dart';
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

/// Prefixos de rota que exigem usuário autenticado (DV-01 "proteção de
/// rotas"). Prefixo (não igualdade exata) para cobrir sub-rotas e rotas
/// com parâmetro, como `/restaurants/:id`.
const _protectedRoutePrefixes = [
  '/home',
  '/profile',
  '/settings',
  '/restaurants',
  '/reviews',
  '/rankings',
  '/favorites',
  '/feed',
  '/users',
  '/admin',
  '/notifications',
  '/gamification',
];

bool _isProtectedRoute(String location) {
  return _protectedRoutePrefixes.any(
    (prefix) => location == prefix || location.startsWith('$prefix/'),
  );
}

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
      if (status is! Authenticated && _isProtectedRoute(location)) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashPage(),
          transitionDuration: AppMotion.scaled(context, AppMotion.slow),
          reverseTransitionDuration: AppMotion.scaled(context, AppMotion.slow),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AppMotion.standard,
              ),
              child: child,
            );
          },
        ),
      ),
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
      GoRoute(
        path: '/restaurants',
        builder: (context, state) => const RestaurantsSearchPage(),
      ),
      GoRoute(
        path: '/restaurants/new',
        builder: (context, state) => const CreateRestaurantPage(),
      ),
      GoRoute(
        path: '/restaurants/:id',
        builder: (context, state) =>
            RestaurantDetailPage(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/restaurants/:id/reviews',
        builder: (context, state) =>
            ReviewsListPage(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/restaurants/:id/reviews/new',
        builder: (context, state) =>
            CreateReviewPage(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reviews/:id',
        builder: (context, state) =>
            ReviewDetailPage(reviewId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reviews/:id/edit',
        builder: (context, state) =>
            EditReviewPage(reviewId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/rankings',
        builder: (context, state) => const RankingsPage(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(path: '/feed', builder: (context, state) => const FeedPage()),
      GoRoute(
        path: '/reviews/:id/comments',
        builder: (context, state) =>
            CommentsPage(reviewId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (context, state) =>
            PublicProfilePage(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/users/:id/followers',
        builder: (context, state) => FollowListPage(
          userId: state.pathParameters['id']!,
          type: FollowListType.followers,
        ),
      ),
      GoRoute(
        path: '/users/:id/following',
        builder: (context, state) => FollowListPage(
          userId: state.pathParameters['id']!,
          type: FollowListType.following,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/admin/restaurants',
        builder: (context, state) => const AdminRestaurantsPage(),
      ),
      GoRoute(
        path: '/admin/moderation',
        builder: (context, state) => const ModerationPage(),
      ),
      GoRoute(
        path: '/admin/roles',
        builder: (context, state) => const AdminRolesPage(),
      ),
      GoRoute(
        path: '/admin/audit-logs',
        builder: (context, state) => const AuditLogPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/notifications/preferences',
        builder: (context, state) => const NotificationPreferencesPage(),
      ),
      GoRoute(
        path: '/notifications/:id',
        builder: (context, state) => NotificationDetailPage(
          notification: state.extra! as AppNotification,
        ),
      ),
      GoRoute(
        path: '/gamification',
        builder: (context, state) => const GamificationProfilePage(),
      ),
      GoRoute(
        path: '/gamification/ranking',
        builder: (context, state) => const RankingUsersPage(),
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
            AppTextButton(
              label: 'Ver perfil',
              onPressed: () => GoRouter.of(context).push('/profile'),
            ),
            AppTextButton(
              label: 'Ver restaurantes',
              onPressed: () => GoRouter.of(context).push('/restaurants'),
            ),
            AppTextButton(
              label: 'Ver ranking',
              onPressed: () => GoRouter.of(context).push('/rankings'),
            ),
            AppTextButton(
              label: 'Ver favoritos',
              onPressed: () => GoRouter.of(context).push('/favorites'),
            ),
            AppTextButton(
              label: 'Ver feed',
              onPressed: () => GoRouter.of(context).push('/feed'),
            ),
            AppTextButton(
              label: 'Painel administrativo',
              onPressed: () => GoRouter.of(context).push('/admin'),
            ),
            AppTextButton(
              label: 'Ver notificações',
              onPressed: () => GoRouter.of(context).push('/notifications'),
            ),
            AppTextButton(
              label: 'Gamificação',
              onPressed: () => GoRouter.of(context).push('/gamification'),
            ),
          ],
        ),
      ),
    );
  }
}
