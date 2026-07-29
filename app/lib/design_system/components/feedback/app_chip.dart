import 'package:flutter/material.dart';

/// Chip do BORAH — nomeado `AppChip` (não `Chip`) para não colidir com
/// a classe `Chip` do próprio Flutter, mesmo cuidado já adotado no
/// código para `GamificationBadge`/`EarnedBadge`
/// (`features/gamification/domain/gamification_badge.dart`).
///
/// Envolve `ChoiceChip` — cores de seleção vêm inteiramente de
/// `Theme.of(context)` (Material 3 `ChipTheme`), nenhuma cor é
/// declarada aqui.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Ícone opcional exibido antes do rótulo.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 18),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
    );
  }
}
