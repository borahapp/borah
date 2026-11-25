import 'package:flutter/material.dart';

import '../../design_system/components/navigation/app_bottom_navigation.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/rankings/presentation/pages/rankings_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/social/presentation/pages/feed_page.dart';
import '../../features/users/presentation/pages/profile_page.dart';

/// FASE SOCIAL 1: shell de navegação pós-login em `/home`, conectando o
/// `AppBottomNavigation` às 5 telas centrais. `IndexedStack` preserva o
/// estado de cada aba ao trocar (evita recarregar dados/perder posição
/// de rolagem).
///
/// FASE 01 (simplificação de produto, auditoria aprovada): o 1º item
/// deixa de ser o Feed (`FeedPage`) e passa a ser a nova `HomePage`
/// (próximo rolê + meus grupos + CTAs de criação) - "a sensação ao abrir
/// o app deve ser 'o que eu faço agora', não 'o que meus amigos estão
/// fazendo'".
///
/// FASE SOCIAL 4 (ainda vigente): o 2º item é "Explorar" (`SearchPage`,
/// Pessoas/Grupos/Restaurantes) - "Meus Grupos" tem atalho próprio em
/// `ProfilePage`, além de aparecer diretamente na nova Home.
///
/// Rodada de melhorias pós-FASE 09 (pivot para o perfil individual/rede
/// social de gastronomia como centro do app): "Criar" sai da barra -
/// vira um botão dentro da própria `HomePage` (`AppTopBar.actions`),
/// que já é quem decide entre os fluxos de criação. No lugar, o Feed
/// volta a ter porta de entrada direta na navegação principal (3º
/// item) - decisão coerente com o perfil/avaliações individuais
/// passando a ser o centro do produto, não mais só os rolês em grupo.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _navIndex = 0;

  static const _pages = [
    HomePage(),
    SearchPage(),
    FeedPage(),
    RankingsPage(),
    ProfilePage(),
  ];

  static const _items = [
    AppBottomNavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Início',
    ),
    AppBottomNavigationItem(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: 'Explorar',
    ),
    AppBottomNavigationItem(
      icon: Icons.dynamic_feed_outlined,
      selectedIcon: Icons.dynamic_feed,
      label: 'Feed',
    ),
    AppBottomNavigationItem(
      icon: Icons.leaderboard_outlined,
      selectedIcon: Icons.leaderboard,
      label: 'Ranking',
    ),
    AppBottomNavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  void _onNavTap(int navIndex) => setState(() => _navIndex = navIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _navIndex, children: _pages),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _navIndex,
        items: _items,
        onTap: _onNavTap,
      ),
    );
  }
}
