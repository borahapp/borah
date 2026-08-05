import 'package:flutter/material.dart';

/// Abas do BORAH — wrapper fino sobre `TabBar`/`TabBarView` nativos do
/// Material, com cor/tipografia vindas de `Theme.of(context)` (nunca
/// hardcoded), mesma regra de todo componente do design system.
///
/// Único uso previsto hoje é a tela unificada "Meu Grupo" (F23,
/// `RC03_DESIGN_GAP.md §1.3`, Sprint 8: Ranking/Estatísticas/Memórias em
/// abas) - construído genérico o suficiente (lista de rótulo+conteúdo)
/// para servir qualquer tela futura com abas, sem parâmetros
/// especulativos além do que uma implementação simples exige.
///
/// Não é consumido em nenhuma tela nesta rodada (Sprint 1).
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
