import 'package:flutter/material.dart';

/// Botão de ícone do BORAH — [tooltip] é **obrigatório**, não opcional.
///
/// Achado real do levantamento do UI-02: cerca de metade dos
/// `IconButton` do app não tinha `tooltip` (ex.: engrenagem de
/// configurações em `profile_page.dart`, ícone de troféu em
/// `gamification_profile_page.dart`), violando a acessibilidade mínima
/// já exigida desde o UI-01 §13 ("labels acessíveis"). Tornar o
/// `tooltip` um parâmetro obrigatório impede que essa lacuna se repita
/// em componentes novos.
///
/// Consome exclusivamente `Theme.of(context)` (cor/tamanho do ícone
/// seguem o `IconTheme` padrão do Material 3) — nenhuma cor é
/// declarada aqui.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Sobrescreve a cor do ícone (ex.: destacar um "favoritado"). Por
  /// padrão segue `IconTheme.of(context)`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
