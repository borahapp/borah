import 'package:package_info_plus/package_info_plus.dart';

import '../environment/app_environment.dart';
import 'feedback_model.dart';
import 'feedback_repository.dart';
import 'feedback_sanitizer.dart';

/// Orquestra [FeedbackRepository] + sanitização de PII (RC-03E).
///
/// Ao contrário de [FeatureFlagService] (RC-03D, que nunca lança porque
/// não há nenhuma UI aguardando o resultado de forma síncrona), aqui
/// existe uma tela/diálogo real com estados de carregando/sucesso/erro
/// (ver RC-03E §Interface) — silenciar a falha tornaria "estados de
/// erro" e "permitir nova tentativa" impossíveis de atender. Por isso
/// [submit] deixa [FeedbackRepositoryException] se propagar; só a
/// camada de Riverpod (`FeedbackController`) a captura e traduz para um
/// estado de UI, mesmo padrão já usado em `AuthController`.
///
/// Decisão arquitetural (RC-03E, revisão pós-implementação): a versão do
/// app **não** é lida via `PackageInfo.fromPlatform()` a cada [submit] —
/// é resolvida uma única vez, no bootstrap, por [initializeAppVersion]
/// (chamado por `AppFeedback.initialize()`, mesmo padrão de
/// `AppAnalytics.initialize()`), e cacheada em [_appVersion], estático e
/// compartilhado por toda instância de `FeedbackService` (tanto a criada
/// pelo Riverpod quanto a da fachada estática — a versão do app é o
/// mesmo valor para o processo inteiro, ao contrário de Feature Flags,
/// que legitimamente podem divergir entre caches). Motivo original do
/// desenho anterior (buscar a versão a cada envio) foi descartado após
/// descobrir, através de um teste de widget do `FeedbackDialog`, que
/// `PackageInfo.fromPlatform()` **nunca resolve** dentro de um contexto
/// `testWidgets()` sem um handler de canal mockado (ao contrário de
/// `test()` puro, onde a chamada falha rápido e é capturada) — travando
/// `pumpAndSettle()` indefinidamente. Mover a leitura para um único
/// ponto no bootstrap resolve o problema pela raiz — nenhum teste
/// (unitário ou de widget) precisa mais tocar o plugin — e também evita
/// uma consulta redundante ao plugin a cada envio em produção.
class FeedbackService {
  FeedbackService(this._repository);

  final FeedbackRepository _repository;

  static String? _appVersion;

  /// Resolve e cacheia a versão do app uma única vez — chamar no
  /// bootstrap (`main.dart`, via `AppFeedback.initialize()`), antes do
  /// primeiro envio de feedback. Nunca lança: se o plugin falhar, a
  /// versão simplesmente fica indisponível (`null`), sem impedir o
  /// envio do feedback em si (mesmo espírito de `FeatureFlagService`).
  static Future<void> initializeAppVersion() async {
    _appVersion = await _readAppVersion();
  }

  static Future<String?> _readAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return null;
    }
  }

  /// `async` é necessário mesmo sem nenhum `await` no corpo: garante que
  /// uma exceção síncrona lançada por `_repository.submit` (ex.: mock em
  /// teste via `thenThrow`) seja automaticamente empacotada como
  /// rejeição da `Future` retornada, em vez de lançar sincronamente na
  /// chamada — mesma garantia que `FeedbackRepository.submit` documenta.
  Future<FeedbackModel> submit({
    required String userId,
    required String message,
    String? screenContext,
  }) async {
    return _repository.submit(
      userId: userId,
      message: sanitizeFeedbackMessage(message),
      screenContext: screenContext,
      appVersion: _appVersion,
      environment: AppEnvironment.environmentName,
    );
  }
}
