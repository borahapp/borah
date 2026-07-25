import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/analytics/app_analytics.dart';
import 'core/feature_flags/app_feature_flags.dart';
import 'core/feedback/app_feedback.dart';
import 'core/network/supabase_client_provider.dart';
import 'core/observability/crash_reporting.dart';
import 'core/observability/sentry_provider_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    runApp(
      ProviderScope(
        observers: const [SentryProviderObserver()],
        child: const BorahApp(),
      ),
    );
  });
}
