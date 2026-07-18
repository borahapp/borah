/// Base type for domain/data-layer failures, kept independent of Flutter
/// and Supabase per AR-02 (o domínio não depende de nenhuma camada externa).
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Falha de conexão.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Falha no servidor.']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Erro inesperado.']);
}
