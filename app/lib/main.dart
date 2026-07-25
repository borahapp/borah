import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
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

    runApp(
      ProviderScope(
        observers: const [SentryProviderObserver()],
        child: const BorahApp(),
      ),
    );
  });
}
