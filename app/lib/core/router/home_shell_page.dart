import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/navigation/app_bottom_navigation.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../features/gamification/presentation/pages/ranking_users_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/users/presentation/pages/profile_page.dart';

/// FASE SOCIAL 1: shell de navegação pós-login em `/home`, conectando o
/// `AppBottomNavigation` às 4 telas centrais. `IndexedStack` preserva o
/// estado de cada aba ao trocar (evita recarregar dados/perder posição
/// de rolagem).
///
/// FASE 01 (simplificação de produto, auditoria aprovada): o 1º item
/// deixa de ser o Feed (`FeedPage`) e passa a ser a nova `HomePage`
/// (próximo rolê + meus grupos + CTAs de criação) - "a sensação ao abrir
/// o app deve ser 'o que eu faço agora', não 'o que meus amigos estão
/// fazendo'". O Feed **não foi removido**: código, tabelas e RPCs
/// continuam intactos (`features/social/`), só deixou de ter porta de
/// entrada na navegação principal - decisão reversível, documentada na
/// auditoria que precedeu esta fase.
///
/// FASE SOCIAL 4 (ainda vigente): o 2º item é "Explorar" (`SearchPage`,
/// Pessoas/Grupos/Restaurantes) - "Meus Grupos" tem atalho próprio em
/// `ProfilePage`, além de aparecer diretamente na nova Home.
///
/// A barra tem 5 itens, mas só 4 páginas: "Criar" (índice 2) nunca é
/// uma aba do `IndexedStack` - abre um `BottomSheet` com atalhos para
/// as ações de criação já existentes, sem mudar a aba selecionada.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  /// Índice dentro dos 5 itens da barra (0-4) - o que `AppBottomNavigation`
  /// mostra selecionado.
  int _navIndex = 0;

  static const _pages = [
    HomePage(),
    SearchPage(),
    RankingUsersPage(),
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
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      label: 'Criar',
    ),
    AppBottomNavigationItem(
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      label: 'Pontuação',
    ),
    AppBottomNavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  /// Converte o índice da barra (0-4, com "Criar" em 2) para o índice
  /// real do `IndexedStack` (0-3, só as 4 páginas).
  int get _pageIndex => _navIndex < 2 ? _navIndex : _navIndex - 1;

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      _openCreateSheet();
      return;
    }
    setState(() => _navIndex = navIndex);
  }

  /// Bottom sheet de "Criar" - 3 atalhos para fluxos já existentes,
  /// nenhuma tela nova de criação. Rolê e avaliação sempre pertencem a
  /// um grupo/restaurante específico, então levam primeiro para a
  /// escolha (Grupos/Restaurantes), não direto a um formulário.
  Future<void> _openCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Criar grupo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/groups/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Criar rolê'),
              subtitle: const Text('Escolha o grupo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/groups');
              },
            ),
            ListTile(
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text('Avaliar restaurante'),
              subtitle: const Text('Escolha o restaurante'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/restaurants');
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _navIndex,
        items: _items,
        onTap: _onNavTap,
      ),
    );
  }
}
