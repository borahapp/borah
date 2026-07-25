import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'feedback_model.dart';
import 'feedback_repository.dart';
import 'feedback_service.dart';
import 'supabase_feedback_repository.dart';

/// Fachada estática de Feedback do BORAH (RC-03E) — mesmo padrão
/// arquitetural de `AppLogger`/`CrashReporting`/`AppAnalytics`/
/// `AppFeatureFlags` (RC-03A/B/C/D). Toda feature deve chamar só os
/// métodos daqui; nenhuma feature deve conhecer [FeedbackRepository]/
/// [FeedbackService] nem a tabela `feedback` diretamente.
///
/// Ao contrário de `AppFeatureFlags` (cujos métodos nunca lançam),
/// [submit] propaga [FeedbackRepositoryException] — existe sempre uma UI
/// real aguardando o resultado (ver `FeedbackController`, o caminho
/// recomendado para telas com Riverpod); esta fachada existe para o raro
/// caso de envio fora de uma árvore de widgets/`ProviderScope`.
abstract final class AppFeedback {
  /// Sobrescreve o serviço em testes (`test/`), no lugar do serviço
  /// padrão (Supabase real). Nunca deve ser usado em código de produção.
  @visibleForTesting
  static FeedbackService? debugServiceOverride;

  static FeedbackService? _defaultService;

  /// Criado sob demanda (não no carregamento da classe) para não exigir
  /// que `Supabase.instance.client` já exista no momento em que este
  /// arquivo é importado — só quando `AppFeedback` é de fato usado pela
  /// primeira vez, o que deve ocorrer depois de `initializeSupabase()`
  /// (ver `main.dart`).
  static FeedbackService get _service {
    return debugServiceOverride ??
        (_defaultService ??= FeedbackService(
          SupabaseFeedbackRepository(Supabase.instance.client),
        ));
  }

  /// Resolve e cacheia a versão do app uma única vez — chamar no
  /// bootstrap (`main.dart`), ao lado de `AppAnalytics.initialize()`/
  /// `AppFeatureFlags.initialize()`, antes do primeiro envio de
  /// feedback. Nunca lança (ver [FeedbackService.initializeAppVersion]).
  static Future<void> initialize() => FeedbackService.initializeAppVersion();

  /// Envia um novo feedback. Pode lançar [FeedbackRepositoryException] —
  /// quem chama fora do Riverpod é responsável por tratar a falha (o
  /// caminho recomendado dentro de widgets é `FeedbackController.submit`,
  /// que já traduz a exceção para um estado de UI).
  static Future<FeedbackModel> submit({
    required String userId,
    required String message,
    String? screenContext,
  }) {
    return _service.submit(
      userId: userId,
      message: message,
      screenContext: screenContext,
    );
  }
}
