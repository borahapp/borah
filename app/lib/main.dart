import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/analytics/app_analytics.dart';
import 'core/deep_link/deep_link_dispatcher.dart';
import 'core/feature_flags/app_feature_flags.dart';
import 'core/feedback/app_feedback.dart';
import 'core/lazy_sync/lazy_sync_dispatcher.dart';
import 'core/network/supabase_client_provider.dart';
import 'core/observability/crash_reporting.dart';
import 'core/observability/sentry_provider_observer.dart';
import 'design_system/components/feedback/error_state.dart';
import 'features/events/application/event_review_sync_task.dart';
import 'features/groups/application/pending_invite_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // RC-04E: sem isso, uma exceção durante o build de um widget mostra a
  // tela de erro padrão do Flutter (texto técnico em inglês, sem a
  // identidade visual do app) em vez de um fallback amigável. O Sentry
  // já captura o erro normalmente antes deste builder rodar
  // (`FlutterError.onError`, instalado por `CrashReporting.run`).
  ErrorWidget.builder = (details) =>
      ErrorState(message: 'Algo deu errado. Tente novamente.');

  // RC-03A: initializeSupabase() e runApp() rodam dentro da zona de
  // captura do Sentry (ver CrashReporting.run) - qualquer erro durante o
  // bootstrap do app também é reportado, não só erros pós-inicialização.
  await CrashReporting.run(() async {
    await initializeSupabase();
    // RC-03C: precisa rodar depois de WidgetsFlutterBinding (usa
    // package_info_plus, que depende de um canal de plataforma) e antes
    // do primeiro evento de Analytics.
    await AppAnalytics.initialize();
    unawaited(AppAnalytics.trackAppOpen());
    // RC-03D: precisa rodar depois de initializeSupabase() (usa
    // Supabase.instance.client). Nunca lança - se o Supabase estiver
    // indisponível, o app sobe normalmente com o cache de flags vazio
    // (ver FeatureFlagService).
    unawaited(AppFeatureFlags.initialize());
    // RC-03E: resolve a versão do app uma única vez (nunca lança) para
    // anexar aos feedbacks enviados depois - não bloqueia o boot, pois
    // nenhum feedback pode ser enviado antes da primeira tela carregar.
    unawaited(AppFeedback.initialize());

    // Deep Link: o único lugar autorizado a conectar DeepLinkDispatcher
    // (core/) ao PendingInviteController real (features/groups/) - nem
    // um nem outro se conhecem diretamente (ver deep_link_dispatcher.
    // dart). ProviderContainer manual (em vez de ProviderScope direto)
    // é necessário para poder ler deepLinkDispatcherProvider uma única
    // vez, agora, no bootstrap - nunca dentro de uma página, widget ou
    // controller (ciclo de vida documentado na própria classe).
    final container = ProviderContainer(
      observers: const [SentryProviderObserver()],
      overrides: [
        deepLinkReceiversProvider.overrideWith(
          (ref) => [ref.read(pendingInviteControllerProvider.notifier)],
        ),
        // FASE C.4: mesmo princípio do override acima - core/lazy_sync/
        // nunca conhece EventReviewSyncTask (features/events/)
        // diretamente. Diferente de deepLinkReceiversProvider,
        // lazySyncDispatcherProvider não precisa ser lido aqui no
        // bootstrap (não abre nenhuma Stream/subscription própria -
        // `runAll()` é chamada sob demanda, hoje só por SplashPage).
        lazySyncTasksProvider.overrideWith((ref) => [EventReviewSyncTask(ref)]),
      ],
    );
    container.read(deepLinkDispatcherProvider);

    runApp(
      UncontrolledProviderScope(container: container, child: const BorahApp()),
    );
  });
}
