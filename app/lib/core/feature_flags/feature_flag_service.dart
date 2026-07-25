import 'feature_flag.dart';
import 'feature_flag_cache.dart';
import 'feature_flag_repository.dart';

/// Orquestra [FeatureFlagRepository] + [FeatureFlagCache] (RC-03D) — é a
/// única classe que decide o que fazer quando o Supabase está
/// indisponível. Nenhum dos dois métodos de carga (`load`/`refresh`)
/// lança: uma falha nunca deve impedir o funcionamento do app (ver
/// RC-03D_FEATURE_FLAGS.md §Estratégia offline).
class FeatureFlagService {
  FeatureFlagService(this._repository, this._cache);

  final FeatureFlagRepository _repository;
  final FeatureFlagCache _cache;

  /// Busca as flags no Supabase e atualiza o cache. Retorna `true` se a
  /// busca teve sucesso, `false` se falhou — nos dois casos o método
  /// nunca lança. Em caso de falha, o cache permanece com o último valor
  /// conhecido (ou vazio, se esta foi a primeira tentativa); o app
  /// continua funcionando normalmente, só sem atualizar o estado das
  /// flags.
  Future<bool> load() async {
    try {
      final flags = await _repository.fetchAll();
      _cache.update(flags);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Alias semântico de [load] — mesma operação, nome mais claro quando
  /// chamado fora do bootstrap inicial (ex.: `AppFeatureFlags.refresh()`).
  Future<bool> refresh() => load();

  /// `true`/`false` conforme a flag [key]; [defaultValue] (padrão
  /// `false`) é usado quando a flag nunca foi carregada com sucesso ou
  /// não existe na tabela — comportamento conservador e uniforme, sem
  /// exceção por flag (nem mesmo `maintenance_mode`).
  bool isEnabled(String key, {bool defaultValue = false}) {
    return _cache.get(key)?.enabled ?? defaultValue;
  }

  FeatureFlag? get(String key) => _cache.get(key);

  Map<String, FeatureFlag> get all => _cache.flags;

  bool get hasLoaded => _cache.hasLoaded;
}
