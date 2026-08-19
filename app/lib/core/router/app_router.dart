import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/animations/app_motion.dart';
import '../../design_system/components/feedback/error_state.dart';
import '../observability/crash_reporting.dart';
import '../../features/authentication/application/auth_controller.dart';
import '../../features/favorites/application/favorites_controller.dart';
import '../../features/gamification/application/gamification_profile_controller.dart';
import '../../features/groups/application/groups_list_controller.dart';
import '../../features/notifications/application/notification_preferences_controller.dart';
import '../../features/notifications/application/notifications_controller.dart';
import '../../features/social/application/feed_controller.dart';
import '../../features/users/application/user_profile_controller.dart';
import '../../features/authentication/presentation/pages/email_verification_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/new_password_page.dart';
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
import '../../features/event_reviews/domain/event_review.dart';
import '../../features/event_reviews/presentation/pages/submit_event_review_page.dart';
import '../../features/events/domain/event.dart';
import '../../features/events/presentation/pages/create_event_page.dart';
import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/events/presentation/pages/events_list_page.dart';
import '../../features/groups/application/pending_invite_controller.dart';
import '../../features/groups/domain/group.dart';
import '../../features/groups/presentation/pages/create_group_page.dart';
import '../../features/groups/presentation/pages/edit_group_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/pages/groups_list_page.dart';
import '../../features/groups/presentation/pages/join_group_page.dart';
import '../../features/groups/presentation/pages/public_group_profile_page.dart';
import '../../features/group_ranking/presentation/pages/group_hub_page.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/presentation/pages/notification_detail_page.dart';
import '../../features/notifications/presentation/pages/notification_preferences_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/rankings/presentation/pages/rankings_page.dart';
import '../../features/restaurants/presentation/pages/create_restaurant_page.dart';
import '../../features/restaurants/presentation/pages/restaurant_detail_page.dart';
import '../../features/restaurants/presentation/pages/restaurants_search_page.dart';
import '../../features/restaurants/presentation/pages/search_google_restaurant_page.dart';
import '../../features/reviews/presentation/pages/create_review_page.dart';
import '../../features/reviews/presentation/pages/edit_review_page.dart';
import '../../features/reviews/presentation/pages/review_detail_page.dart';
import '../../features/reviews/presentation/pages/reviews_list_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/social/presentation/pages/comments_page.dart';
import '../../features/social/presentation/pages/feed_page.dart';
import '../../features/social/presentation/pages/follow_list_page.dart';
import '../../features/social/presentation/pages/public_profile_page.dart';
import '../../features/social/presentation/states/follow_list_status.dart';
import '../../features/users/presentation/pages/change_avatar_page.dart';
import '../../features/users/presentation/pages/edit_profile_page.dart';
import '../../features/users/presentation/pages/profile_page.dart';
import '../../features/users/presentation/pages/settings_page.dart';
import 'home_shell_page.dart';

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
  '/groups',
  '/search',
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
    // Deep Link (auditoria de infraestrutura, achado nº1): sem isto, um
    // convite pendente que chega depois da decisão inicial de
    // navegação (corrida real entre `getInitialLink()` e
    // `SplashPage._restoreAndRedirect`, ou qualquer link recebido com o
    // app já parado numa tela) nunca reavalia `redirect` - o estado de
    // `PendingInviteController` mudava, mas nada mandava o GoRouter
    // olhar de novo. Mesmo padrão de `authControllerProvider` abaixo,
    // só que aqui não há nenhuma limpeza adicional a fazer - `redirect`
    // já sabe ler `PendingInviteController.existe` sozinho.
    ref.listen(pendingInviteControllerProvider, (previous, next) {
      notifyListeners();
    });

    ref.listen(authControllerProvider, (previous, next) {
      notifyListeners();
      // QA-14 (RC): esses providers não são `autoDispose` - trocar de
      // conta no mesmo processo do app (Sair -> Entrar com outra conta,
      // sem matar o app) sem isto deixava dados do usuário anterior
      // (grupos, favoritos, perfil, notificações) visíveis por um
      // instante na tela seguinte, até o próprio `load()` de cada
      // página sobrescrever - risco real de vazamento entre contas em
      // dispositivo compartilhado. Restrito aos providers que aparecem
      // imediatamente ao entrar (abas da Home + Perfil), sem depender
      // de nenhum id específico; providers "de detalhe" (grupo/rolê/
      // avaliação específicos) não têm esse risco prático, pois exigem
      // navegar até um item que só existiria na sessão anterior.
      if (previous is Authenticated && next is Unauthenticated) {
        ref.invalidate(groupsListControllerProvider);
        ref.invalidate(favoritesControllerProvider);
        ref.invalidate(userProfileControllerProvider);
        ref.invalidate(notificationsControllerProvider);
        ref.invalidate(notificationPreferencesControllerProvider);
        ref.invalidate(gamificationProfileControllerProvider);
        ref.invalidate(feedForYouControllerProvider);
        ref.invalidate(feedFollowingControllerProvider);
      }
    });
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
    // Sem isto, `initialLocation: '/'` acima é ignorado sempre que o app
    // abre a frio via Deep Link (`overridePlatformDefaultLocation` do
    // go_router é `false` por padrão, e nesse caso ele usa a rota crua da
    // plataforma - `WidgetsBinding.instance.platformDispatcher
    // .defaultRouteName`, preenchida direto pela URI do Intent) - quebra a
    // regra permanente de `core/deep_link/deep_link.dart` de que um Deep
    // Link nunca é uma rota de navegação literal: `borah://group/join`
    // virava a rota `/group/join`, que não existe (a rota real é
    // `/groups/join`), e caía no `errorBuilder`. Forçar `true` garante que
    // todo cold start - com ou sem Deep Link - sempre passe por `/`
    // (Splash), que é quem decide o redirecionamento, já considerando
    // sessão restaurada e convite pendente.
    overridePlatformDefaultLocation: true,
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) {
      // RC-03A: erro de navegação (rota desconhecida ou falha ao
      // construir uma página) - reporta ao Sentry com o mesmo tratamento
      // de qualquer outro erro capturado manualmente, e mostra um estado
      // de erro consistente com o resto do app em vez da tela de erro
      // padrão do GoRouter.
      CrashReporting.captureException(
        state.error ?? Exception('Rota desconhecida: ${state.uri}'),
        StackTrace.current,
        origin: 'go_router',
      );
      return Scaffold(
        body: ErrorState(
          message: 'Não foi possível abrir esta tela.',
          onRetry: () => context.go('/'),
        ),
      );
    },
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == '/') return null; // a Splash decide sozinha

      final status = ref.read(authControllerProvider);
      final isAuthRoute = _authRoutes.contains(location);

      // RC-04E: uma sessão de recuperação de senha nunca deve navegar
      // para nenhum outro lugar além de "Definir nova senha" - nem para
      // rotas protegidas (ainda não é bem um login), nem para
      // login/cadastro (o `redirect` abaixo trataria isso como
      // `Authenticated`, o que não é o caso).
      if (status is PasswordRecoveryInProgress) {
        return location == '/password-recovery' ? null : '/password-recovery';
      }
      if (location == '/password-recovery') {
        return status is Authenticated ? '/home' : '/login';
      }

      // Deep Link de convite de grupo: mesmo padrão de
      // `PasswordRecoveryInProgress` acima - o Router só consulta
      // "existe convite pendente?" (`PendingInviteController.existe`),
      // nunca interpreta a Uri que originou isso (já foi interpretada
      // antes, por `DeepLinkParser`/`DeepLinkDispatcher`). Checado antes
      // do redirecionamento padrão de rota de auth para `/home`, para
      // que um login/cadastro feito a partir de um link de convite vá
      // direto para "Entrar em grupo", não para a Home primeiro.
      if (status is Authenticated &&
          ref.read(pendingInviteControllerProvider.notifier).existe &&
          location != '/groups/join') {
        return '/groups/join';
      }

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
        path: '/password-recovery',
        builder: (context, state) => const NewPasswordPage(),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => const EmailVerificationPage(),
      ),
      // RC-04E: `/home` passa a ser o `HomeShellPage`, conectando a
      // navegação inferior (já existente, nunca usada até esta rodada) às
      // 4 telas centrais (Restaurantes/Feed/Favoritos/Perfil) - substitui
      // o antigo `_BootstrapPlaceholderPage` (placeholder de desenvolvedor)
      // sem depender de o usuário já seguir alguém (a aba inicial é
      // Restaurantes, que carrega conteúdo desde o primeiro acesso).
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShellPage(),
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
        // UX-01: `extra: true` só quando `CreateEventPage` chega aqui
        // (usuário sem o restaurante no catálogo, Etapa 1 de "Criar
        // rolê") - navegação normal (aba Restaurantes) nunca passa
        // `extra`, cai no default `false`. F12: também é o destino do
        // link "Cadastrar manualmente" de `SearchGoogleRestaurantPage`
        // (fallback, sem `extra`, mesmo default).
        builder: (context, state) =>
            CreateRestaurantPage(returnToCaller: state.extra as bool? ?? false),
      ),
      // F12 - Google Places API (New): destino do botão "Adicionar
      // restaurante" de `RestaurantsSearchPage`, no lugar de
      // `/restaurants/new` direto - busca restaurantes reais antes de
      // qualquer cadastro manual.
      GoRoute(
        path: '/restaurants/search-google',
        builder: (context, state) => const SearchGoogleRestaurantPage(),
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
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
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
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsListPage(),
      ),
      GoRoute(
        path: '/groups/new',
        builder: (context, state) => const CreateGroupPage(),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) => const JoinGroupPage(),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) => GroupDetailPage(
          groupId: state.pathParameters['id']!,
          // UX-01: `extra: true` só quando `CreateGroupPage` chega aqui
          // via `pushReplacement` - navegação normal (tocar num grupo na
          // lista) nunca passa `extra`, então cai no default `false`.
          justCreated: state.extra as bool? ?? false,
        ),
      ),
      GoRoute(
        path: '/groups/:id/edit',
        builder: (context, state) =>
            EditGroupPage(group: state.extra! as Group),
      ),
      // FASE SOCIAL 3: destino de quem encontrou um grupo público na
      // Busca/Explorar e ainda não é membro - distinto de `/groups/:id`
      // de propósito (aquela rota sempre assume que o usuário já é
      // membro, nada nela muda nesta fase).
      GoRoute(
        path: '/groups/:id/preview',
        builder: (context, state) =>
            PublicGroupProfilePage(groupId: state.pathParameters['id']!),
      ),
      // FASE B, Entrega 5: rota única do Group Hub - consolida as 2
      // rotas antigas (`/groups/:id/ranking`, `/groups/:id/stats`,
      // removidas). A aba inicial vem por `extra` (mesmo padrão já
      // usado para `justCreated`/`EditGroupPage` acima, não query
      // string - nunca usada neste router), default `0` (Ranking) se
      // omitido.
      GoRoute(
        path: '/groups/:id/hub',
        builder: (context, state) => GroupHubPage(
          groupId: state.pathParameters['id']!,
          initialTabIndex: state.extra as int? ?? 0,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/events',
        builder: (context, state) =>
            EventsListPage(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/events/new',
        builder: (context, state) =>
            CreateEventPage(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/events/:eventId',
        builder: (context, state) => EventDetailPage(
          eventId: state.pathParameters['eventId']!,
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/events/:eventId/review',
        builder: (context, state) {
          // RC-03 FASE A1: `extra` carrega o rolê completo (não só o
          // `id`) para contextualizar a tela de avaliação (nome/data/foto
          // do restaurante, sem nenhuma consulta nova) - ver
          // `_ReviewsSection._openReviewForm` em `event_detail_page.dart`.
          final extra =
              state.extra as ({Event event, EventReview? existingReview});
          return SubmitEventReviewPage(
            eventId: state.pathParameters['eventId']!,
            restaurantName: extra.event.restaurantName,
            scheduledAt: extra.event.scheduledAt,
            restaurantCoverImage: extra.event.restaurantCoverImage,
            existingReview: extra.existingReview,
          );
        },
      ),
    ],
  );
});
