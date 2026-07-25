import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crash_reporting.dart';

/// Reporta ao Sentry qualquer provider que falhar (RC-03A — integração com
/// Riverpod). Registrado em `ProviderScope(observers: [...])` no
/// `main.dart` — nenhuma outra parte do app precisa (nem deve) reportar
/// erro de provider manualmente.
class SentryProviderObserver extends ProviderObserver {
  const SentryProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final providerName = provider.name ?? provider.runtimeType.toString();
    CrashReporting.captureException(
      error,
      stackTrace,
      origin: 'riverpod_provider:$providerName',
    );
  }
}
