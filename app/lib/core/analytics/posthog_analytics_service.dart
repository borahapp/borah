import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../environment/app_environment.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';

/// Única classe do projeto que importa `package:posthog_flutter`
/// diretamente (RC-03C) — qualquer troca de provedor de Analytics no
/// futuro deve trocar só este arquivo, nunca `AppAnalytics` nem as
/// features. Segue exatamente o mesmo papel que `CrashReporting`
/// desempenha para o Sentry (RC-03A): a única fronteira com o SDK.
///
/// Toda chamada é protegida por `try/catch` — Analytics nunca deve
/// derrubar nem atrasar o app por causa de uma falha do SDK (canal de
/// plataforma indisponível, SDK não inicializado, erro de rede interno
/// etc.). Diferente do Sentry (cujo `Hub` padrão é um no-op puro em
/// Dart quando não inicializado), o `Posthog()` do pacote
/// `posthog_flutter` lança `MissingPluginException` se chamado sem um
/// canal de plataforma registrado — este `try/catch` é o que dá à nossa
/// camada a mesma garantia de "nunca lança" que o Sentry já tinha
/// nativamente.
class PostHogAnalyticsService implements AnalyticsService {
  @override
  Future<void> setup() async {
    try {
      // `Posthog().setup()` já no-opa graciosamente (log de debug, sem
      // lançar) quando `projectToken` está vazio — mesmo comportamento
      // do `SentryOptions.dsn` vazio na RC-03A. Não é preciso nenhum
      // gate extra aqui além do já feito por `AppAnalytics` (ambiente).
      final config = PostHogConfig(AppEnvironment.postHogApiKey)
        ..host = AppEnvironment.postHogHost
        ..debug = kDebugMode
        // Eventos de app_open/lifecycle já são emitidos explicitamente
        // por `AppAnalytics.trackAppOpen()` (chamado uma vez no
        // bootstrap) - desabilitar a captura automática evita um evento
        // nativo duplicado e divergente da nossa própria convenção de
        // campos.
        ..captureApplicationLifecycleEvents = false
        // Session Replay e Surveys são produtos do PostHog fora do
        // escopo desta rodada (Product Analytics) - mantidos desligados
        // deliberadamente.
        ..sessionReplay = false
        ..surveys = false;
      // Autocaptura de erro do próprio PostHog já vem desligada por
      // padrão (PostHogErrorTrackingConfig()) - não tocada aqui de
      // propósito, para não haver dúvida sobre qual SDK está de fato
      // instalando FlutterError.onError/PlatformDispatcher.onError (é
      // só o Sentry, RC-03A).
      await Posthog().setup(config);
    } catch (_) {
      // Silencioso de propósito - ver doc da classe.
    }
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    try {
      await Posthog().capture(
        eventName: event.name,
        properties: flattenAnalyticsEventForPostHog(event),
      );
    } catch (_) {
      // Silencioso de propósito - ver doc da classe.
    }
  }

  @override
  Future<void> identify(String userId) async {
    try {
      await Posthog().identify(userId: userId);
    } catch (_) {
      // Silencioso de propósito - ver doc da classe.
    }
  }

  @override
  Future<void> reset() async {
    try {
      await Posthog().reset();
    } catch (_) {
      // Silencioso de propósito - ver doc da classe.
    }
  }
}

/// Achata um [AnalyticsEvent] no formato de `properties` plano esperado
/// por `Posthog().capture()` (a API do SDK não aceita o `properties`
/// aninhado do nosso próprio modelo canônico). Extraída como função pura
/// e pública para ser testável isoladamente — `Posthog()` lança
/// `MissingPluginException` em ambiente de teste sem um canal de
/// plataforma registrado (diferente do Sentry, cujo Hub padrão é um
/// no-op puro em Dart), então o restante desta classe não é exercitado
/// diretamente por teste unitário.
@visibleForTesting
Map<String, Object> flattenAnalyticsEventForPostHog(AnalyticsEvent event) {
  final flat = <String, Object>{
    'environment': event.environment,
    'version': event.appVersion,
    'timestamp_utc': event.timestamp.toIso8601String(),
  };
  if (event.screen != null) flat['screen'] = event.screen!;
  if (event.userId != null) flat['user_id'] = event.userId!;
  for (final entry in event.properties.entries) {
    final value = entry.value;
    if (value != null) flat[entry.key] = value;
  }
  return flat;
}
