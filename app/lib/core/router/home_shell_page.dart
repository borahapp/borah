import 'package:flutter/material.dart';

import '../../design_system/components/navigation/app_bottom_navigation.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/groups/presentation/pages/groups_list_page.dart';
import '../../features/restaurants/presentation/pages/restaurants_search_page.dart';
import '../../features/users/presentation/pages/profile_page.dart';

/// RC-04E: shell de navegação inicial pós-login em `/home`, conectando o
/// `AppBottomNavigation` às 4 telas mais centrais do app. `IndexedStack`
/// preserva o estado de cada aba ao trocar (evita recarregar dados/
/// perder posição de rolagem a cada troca).
///
/// Decisão de produto (BLOCO 9, pendente desde o relatório de
/// prontidão): "Feed" saiu da barra principal e "Grupos" entrou em seu
/// lugar - a home passa a refletir a identidade real do BORAH ("o
/// ranking dos seus rolês", organizado por grupos de amigos), não a de
/// um app de review de restaurante individual. `FeedPage` continua a
/// existir no código (perfis públicos ainda linkam para
/// seguidores/seguindo, DV-07) - só deixou de ser um destino da barra
/// inferior.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;

  static const _pages = [
    GroupsListPage(),
    RestaurantsSearchPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  static const _items = [
    AppBottomNavigationItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Grupos',
    ),
    AppBottomNavigationItem(
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
      label: 'Restaurantes',
    ),
    AppBottomNavigationItem(
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
      label: 'Favoritos',
    ),
    AppBottomNavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _index,
        items: _items,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
