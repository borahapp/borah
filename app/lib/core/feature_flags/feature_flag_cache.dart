import 'feature_flag.dart';

/// Cache local, em memória, das Feature Flags (RC-03D) — evita consultar
/// o Supabase a cada `isEnabled()`. Escopo de sessão apenas (não
/// persiste em disco): recarregado do zero a cada início do app via
/// `AppFeatureFlags.initialize()`, decisão deliberada de simplicidade
/// (o app já carrega as flags no bootstrap, então persistência em disco
/// só economizaria a primeira leitura, com o custo de mais uma
/// dependência e mais uma fonte de dado potencialmente desatualizado).
class FeatureFlagCache {
  Map<String, FeatureFlag> _flags = const {};
  DateTime? _lastLoadedAt;

  /// `true` assim que a primeira carga bem-sucedida acontece — mesmo que
  /// uma tentativa de `refresh()` posterior falhe, o cache permanece
  /// "carregado" com o último valor conhecido.
  bool get hasLoaded => _lastLoadedAt != null;

  DateTime? get lastLoadedAt => _lastLoadedAt;

  Map<String, FeatureFlag> get flags => Map.unmodifiable(_flags);

  FeatureFlag? get(String key) => _flags[key];

  void update(List<FeatureFlag> flags) {
    _flags = {for (final flag in flags) flag.key: flag};
    _lastLoadedAt = DateTime.now().toUtc();
  }
}
