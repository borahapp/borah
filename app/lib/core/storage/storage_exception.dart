/// Erro de Storage do BORAH (RC-04B) — único tipo de exceção usado por
/// toda a camada (`SupabaseStorageService`, `StorageService`,
/// `AppStorage`). Nunca carrega a mensagem interna bruta do Supabase —
/// sempre uma mensagem já traduzida para o usuário final.
///
/// Nomeado sem sufixo `Repository` (diferente de
/// `FeedbackRepositoryException`/`FeatureFlagRepositoryException`, RC-03)
/// porque esta exceção também é lançada pela camada de validação
/// (`StorageService`, antes de qualquer chamada ao Supabase) — não é
/// exclusiva da fronteira com o SDK.
class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => 'StorageException: $message';
}
