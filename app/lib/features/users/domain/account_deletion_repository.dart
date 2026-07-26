/// Erro traduzido pela camada de dados — nenhuma camada acima de `data/`
/// conhece exceções do Supabase (mesmo padrão do DV-01/`UserProfileRepository`).
class AccountDeletionRepositoryException implements Exception {
  const AccountDeletionRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio, independente de Flutter e Supabase (AR-02).
///
/// Exclusão de conta (RC-04C — LGPD/RN-003) sempre se refere ao usuário
/// **autenticado no momento da chamada** — não existe (nem pode existir,
/// ver `delete_own_account()`, migration `20260725150000`) uma forma de
/// excluir a conta de outra pessoa por este caminho.
abstract interface class AccountDeletionRepository {
  Future<void> deleteOwnAccount();
}
