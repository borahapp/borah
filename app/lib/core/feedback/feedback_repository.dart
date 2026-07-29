import 'feedback_model.dart';

/// Erro traduzido pela camada de dados (mesmo padrão já usado em todo o
/// app, ex. `FeatureFlagRepositoryException`) — nenhuma camada acima
/// conhece exceções do Supabase.
class FeedbackRepositoryException implements Exception {
  const FeedbackRepositoryException(this.message);

  final String message;
}

/// Contrato de acesso a dados de Feedback (RC-03E). Nenhuma feature deve
/// acessar a tabela `feedback` diretamente — toda comunicação passa por
/// esta interface (ou, mais acima, por [FeedbackService]/`AppFeedback`).
abstract interface class FeedbackRepository {
  /// Envia um novo feedback. Pode lançar [FeedbackRepositoryException] —
  /// ao contrário de Feature Flags (RC-03D), aqui existe uma tela real
  /// aguardando o resultado de forma síncrona, então a falha deve se
  /// propagar até quem chama (sempre [FeedbackService], nunca uma
  /// feature diretamente) decidir como exibir o erro.
  Future<FeedbackModel> submit({
    required String userId,
    required String message,
    String? screenContext,
    String? appVersion,
    String? environment,
  });
}
