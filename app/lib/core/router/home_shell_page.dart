import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/navigation/app_bottom_navigation.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../features/gamification/presentation/pages/ranking_users_page.dart';
import '../../features/groups/presentation/pages/groups_list_page.dart';
import '../../features/social/presentation/pages/feed_page.dart';
import '../../features/users/presentation/pages/profile_page.dart';

/// FASE SOCIAL 1: shell de navegação pós-login em `/home`, conectando o
/// `AppBottomNavigation` às 4 telas centrais - Feed, Grupos, Rankings
/// (ranking de usuários por XP, `/gamification/ranking` - não o ranking
/// de restaurantes) e Perfil. `IndexedStack` preserva o estado de cada
/// aba ao trocar (evita recarregar dados/perder posição de rolagem).
///
/// Decisão de produto (FASE FEED SOCIAL, revertendo a decisão do BLOCO 9
/// que havia tirado o Feed da barra): o Feed volta a ser a Home - "a
/// sensação ao abrir o app deve ser 'quero ver o que meus amigos estão
/// fazendo', não 'quero procurar um restaurante'". Restaurantes e
/// Favoritos saem da barra principal (ambos continuam existindo, só
/// mudam de porta de entrada - ver `_openCreateSheet`/`profile_page.dart`).
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
    FeedPage(),
    GroupsListPage(),
    RankingUsersPage(),
    ProfilePage(),
  ];

  static const _items = [
    AppBottomNavigationItem(
      icon: Icons.dynamic_feed_outlined,
      selectedIcon: Icons.dynamic_feed,
      label: 'Feed',
    ),
    AppBottomNavigationItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Grupos',
    ),
    AppBottomNavigationItem(
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      label: 'Criar',
    ),
    AppBottomNavigationItem(
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      label: 'Rankings',
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
