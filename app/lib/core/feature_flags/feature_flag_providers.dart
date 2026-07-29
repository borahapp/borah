import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/supabase_client_provider.dart';
import 'feature_flag.dart';
import 'feature_flag_repository.dart';
import 'feature_flag_service.dart';
import 'feature_flag_cache.dart';
import 'supabase_feature_flag_repository.dart';

/// Providers de acesso reativo às Feature Flags (RC-03D) — para telas
/// que precisam *reconstruir* quando o estado das flags muda. Uso
/// imperativo simples (ex.: um `if` dentro de um método) deve preferir
/// `AppFeatureFlags.isEnabled()`, que não exige um `WidgetRef`.
///
/// Mantém sua própria instância de [FeatureFlagService]/[FeatureFlagCache],
/// independente da instância usada por `AppFeatureFlags` — ambas
/// consultam a mesma tabela via RLS, mas cada uma cacheia separadamente
/// nesta rodada (nenhuma tela consome nenhuma das duas ainda; unificar
/// as duas instâncias fica para quando houver um consumidor real, ver
/// RC-03D_FEATURE_FLAGS.md §Limitações).
final featureFlagRepositoryProvider = Provider<FeatureFlagRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseFeatureFlagRepository(client);
});

final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService(
    ref.watch(featureFlagRepositoryProvider),
    FeatureFlagCache(),
  );
});

/// Estado do carregamento das flags (mesmo padrão sealed-class usado em
/// todas as features do app, ex. `FavoritesStatus`).
sealed class FeatureFlagsStatus {
  const FeatureFlagsStatus();
}

final class FeatureFlagsInitial extends FeatureFlagsStatus {
  const FeatureFlagsInitial();
}

final class FeatureFlagsLoading extends FeatureFlagsStatus {
  const FeatureFlagsLoading();
}

final class FeatureFlagsLoaded extends FeatureFlagsStatus {
  const FeatureFlagsLoaded(this.flags, {required this.degraded});

  final Map<String, FeatureFlag> flags;

  /// `true` quando a última tentativa de carregar/atualizar falhou e
  /// `flags` reflete um cache desatualizado (ou vazio, se nunca houve
  /// sucesso) — nunca um erro que bloqueia a tela, só um sinal
  /// informativo (RC-03D §Erros: o Supabase indisponível nunca impede o
  /// funcionamento do app).
  final bool degraded;
}

/// Carrega/atualiza as flags e expõe o estado atual de forma reativa.
/// `FeatureFlagService.load()` nunca lança — esta controller nunca
/// entra num estado de erro que bloqueie a tela, só reflete `degraded`.
class FeatureFlagsController extends Notifier<FeatureFlagsStatus> {
  @override
  FeatureFlagsStatus build() => const FeatureFlagsInitial();

  FeatureFlagService get _service => ref.read(featureFlagServiceProvider);

  Future<void> load() async {
    state = const FeatureFlagsLoading();
    final succeeded = await _service.load();
    state = FeatureFlagsLoaded(_service.all, degraded: !succeeded);
  }

  Future<void> refresh() => load();

  bool isEnabled(String key, {bool defaultValue = false}) =>
      _service.isEnabled(key, defaultValue: defaultValue);
}

final featureFlagsControllerProvider =
    NotifierProvider<FeatureFlagsController, FeatureFlagsStatus>(
      FeatureFlagsController.new,
    );
