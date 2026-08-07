import 'package:flutter/material.dart';

/// Abas do BORAH — wrapper fino sobre `TabBar`/`TabBarView` nativos do
/// Material, com cor/tipografia vindas de `Theme.of(context)` (nunca
/// hardcoded), mesma regra de todo componente do design system.
///
/// Único uso previsto hoje é a tela unificada "Meu Grupo" (F23,
/// `RC03_DESIGN_GAP.md §1.3`: Ranking/Estatísticas/Memórias em abas) -
/// construído genérico o suficiente (lista de rótulo+conteúdo) para
/// servir qualquer tela futura com abas, sem parâmetros especulativos
/// além do que uma implementação simples exige.
///
/// Ainda sem consumidor real (auditoria de componentes RC-03, FASE B0)
/// - **não é dívida técnica**: "Meu Grupo" continua sendo item Core
/// (`BORAH_VISION_v2.0.md`, Capítulo 11) e sua própria fase de
/// implementação ainda não foi aberta. Este componente é infraestrutura
/// construída deliberadamente adiantada para essa fase futura, não um
/// componente esquecido ou sem propósito.
class AppTabs extends StatelessWidget {
  const AppTabs({super.key, required this.tabs, this.initialIndex = 0});

  final List<AppTabItem> tabs;

  /// Aba aberta inicialmente (ex.: destino direto de uma notificação
  /// para "Memórias" em vez de "Ranking"). `0` preserva o comportamento
  /// original.
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Column(
        children: [
          TabBar(tabs: [for (final tab in tabs) Tab(text: tab.label)]),
          Expanded(
            child: TabBarView(children: [for (final tab in tabs) tab.child]),
          ),
        ],
      ),
    );
  }
}

/// Uma aba de [AppTabs]: rótulo + conteúdo.
class AppTabItem {
  const AppTabItem({required this.label, required this.child});

  final String label;
  final Widget child;
}
