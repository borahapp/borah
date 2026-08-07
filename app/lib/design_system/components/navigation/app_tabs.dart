import 'package:flutter/material.dart';

/// Abas do BORAH — wrapper fino sobre `TabBar`/`TabBarView` nativos do
/// Material, com cor/tipografia vindas de `Theme.of(context)` (nunca
/// hardcoded), mesma regra de todo componente do design system.
///
/// Construído genérico o suficiente (lista de rótulo+conteúdo) para
/// servir qualquer tela com abas, sem parâmetros especulativos além do
/// que uma implementação simples exige.
///
/// Consumidor real desde a FASE B, Entrega 1: `GroupHubPage` ("Meu
/// Grupo", F23, `RC03_DESIGN_GAP.md §1.3`) - Ranking/Estatísticas/
/// Memórias. Construído adiantado na Sprint 1, antes de "Meu Grupo"
/// existir (não era dívida técnica na época, e a previsão se
/// confirmou).
class AppTabs extends StatelessWidget {
  const AppTabs({super.key, required this.tabs, this.initialIndex = 0});

  final List<AppTabItem> tabs;

  /// Aba aberta inicialmente - usado por `GroupHubPage` (FASE B,
  /// Entrega 5) para que os 2 pontos de entrada de
  /// `group_detail_page.dart` ("Ranking do grupo"/"Estatísticas")
  /// levem direto à aba correspondente. `0` preserva o comportamento
  /// original (primeira aba).
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
