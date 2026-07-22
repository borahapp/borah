import 'package:flutter/material.dart';

/// Item de destino do [AppBottomNavigation].
class AppBottomNavigationItem {
  const AppBottomNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Navegação inferior do BORAH — envolve o `NavigationBar` do Material
/// 3. Cores/indicador vêm de `Theme.of(context)`.
///
/// Achado real do levantamento do UI-02: não existe nenhum shell de
/// navegação inferior hoje — `/home` é um placeholder explícito
/// (`_BootstrapPlaceholderPage` em `core/router/app_router.dart`) com
/// uma lista de `TextButton`s de navegação ad hoc. Este componente
/// fica pronto para quando a Home real for construída; nenhuma tela é
/// conectada a ele nesta rodada.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
    );
  }
}
