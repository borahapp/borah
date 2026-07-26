import 'package:flutter/material.dart';

import '../../design_system/components/navigation/app_bottom_navigation.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/restaurants/presentation/pages/restaurants_search_page.dart';
import '../../features/social/presentation/pages/feed_page.dart';
import '../../features/users/presentation/pages/profile_page.dart';

/// RC-04E: shell de navegação inicial pós-login em `/home`, conectando o
/// `AppBottomNavigation` (já existente, nunca usado até esta rodada) às 4
/// telas mais centrais do app. Nenhuma delas é nova - só deixam de
/// depender do antigo placeholder de desenvolvedor para serem
/// alcançadas. `IndexedStack` preserva o estado de cada aba ao trocar
/// (evita recarregar dados/perder posição de rolagem a cada troca).
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;

  static const _pages = [
    RestaurantsSearchPage(),
    FeedPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  static const _items = [
    AppBottomNavigationItem(
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
      label: 'Restaurantes',
    ),
    AppBottomNavigationItem(
      icon: Icons.dynamic_feed_outlined,
      selectedIcon: Icons.dynamic_feed,
      label: 'Feed',
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
