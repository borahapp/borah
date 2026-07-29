import 'package:flutter/material.dart';

/// Barra superior do BORAH — envolve `AppBar`. Título/cores vêm de
/// `Theme.of(context)` (`AppBarTheme` implícito do Material 3 + o
/// `TextTheme` do UI-01, que já usa Fredoka para títulos) — nenhum
/// estilo é declarado aqui.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
