import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'feature_flag.dart';
import 'feature_flag_cache.dart';
import 'feature_flag_service.dart';
import 'supabase_feature_flag_repository.dart';

/// Fachada estática de Feature Flags do BORAH (RC-03D) — mesmo padrão
/// arquitetural de `AppLogger`/`CrashReporting`/`AppAnalytics`
/// (RC-03A/B/C). Toda feature deve chamar só os métodos daqui; nenhuma
/// feature deve conhecer [FeatureFlagRepository]/[FeatureFlagService]
/// nem a tabela `feature_flags` diretamente.
///
/// Uso típico:
/// ```dart
/// // No bootstrap (main.dart), depois de initializeSupabase():
/// await AppFeatureFlags.initialize();
///
/// // Em qualquer lugar do app:
/// if (AppFeatureFlags.isEnabled('new_feed')) { ... }
/// ```
abstract final class AppFeatureFlags {
  /// Sobrescreve o serviço em testes (`test/`), no lugar do serviço
  /// padrão (Supabase real). Nunca deve ser usado em código de produção.
  @visibleForTesting
  static FeatureFlagService? debugServiceOverride;

  static FeatureFlagService? _defaultService;

  /// Criado sob demanda (não no carregamento da classe) para não exigir
  /// que `Supabase.instance.client` já exista no momento em que este
  /// arquivo é importado — só quando `AppFeatureFlags` é de fato usado
  /// pela primeira vez, o que deve ocorrer depois de
  /// `initializeSupabase()` (ver `main.dart`).
  static FeatureFlagService get _service {
    return debugServiceOverride ??
        (_defaultService ??= FeatureFlagService(
          SupabaseFeatureFlagRepository(Supabase.instance.client),
          FeatureFlagCache(),
        ));
  }

  /// Carrega as flags pela primeira vez — chamar uma única vez no
  /// bootstrap do app (`main.dart`), depois de `initializeSupabase()`.
  /// Nunca lança (ver [FeatureFlagService.load]).
  static Future<void> initialize() => _service.load();

  /// Força uma nova consulta ao Supabase, atualizando o cache. Nunca
  /// lança.
  static Future<void> refresh() => _service.refresh();

  /// `true`/`false` conforme a flag [key]. Retorna [defaultValue]
  /// (padrão `false`) quando a flag nunca foi carregada com sucesso ou
  /// não existe — nunca lança, nunca bloqueia.
  static bool isEnabled(String key, {bool defaultValue = false}) =>
      _service.isEnabled(key, defaultValue: defaultValue);

  /// A flag completa (com `description`/`updatedAt`), ou `null` se não
  /// carregada/inexistente.
  static FeatureFlag? get(String key) => _service.get(key);

  /// Todas as flags atualmente em cache.
  static Map<String, FeatureFlag> get all => _service.all;

  /// `true` assim que a primeira carga bem-sucedida acontece.
  static bool get hasLoaded => _service.hasLoaded;
}
