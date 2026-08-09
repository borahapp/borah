/// Uma rotina de sincronização "melhor esforço" que reage à passagem do
/// tempo (não a um evento de banco real) - mesmo problema que
/// `core/deep_link/` resolve para links externos, mas para o caso em
/// que não existe nenhum INSERT/UPDATE para reagir (ex.: "a avaliação
/// coletiva de um rolê acabou de ficar liberada porque o horário
/// marcado já passou"). Sem Push Notification, sem scheduler (`pg_cron`
/// ou Edge Function agendada) - `run()` é chamada explicitamente pelo
/// cliente em pontos naturais de uso (hoje, só `SplashPage`), nunca por
/// conta própria.
abstract interface class LazySyncTask {
  /// Deve ser idempotente (pode ser chamada repetidas vezes sem
  /// duplicar efeito - cada implementação decide como) e nunca lançar
  /// de forma que impeça as demais tarefas de rodar -
  /// [LazySyncDispatcher] isola cada uma, mas a implementação também não
  /// deveria depender disso.
  Future<void> run();
}
