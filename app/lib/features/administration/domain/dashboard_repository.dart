import 'dashboard_kpis.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-01 em diante) -
/// nenhuma camada acima de `data/` conhece exceções do Supabase.
class DashboardRepositoryException implements Exception {
  const DashboardRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio do Dashboard/Relatórios (DV-08 §6) - "Relatórios"
/// foi dobrado aqui (mesmas contagens), sem uma tela separada com
/// gráficos que nada no projeto ainda sustenta (decisão da análise do DV-08).
abstract interface class DashboardRepository {
  Future<DashboardKpis> getKpis();
}
