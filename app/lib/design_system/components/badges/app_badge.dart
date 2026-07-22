import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Selo/etiqueta do BORAH — nomeado `AppBadge` (não `Badge`) para não
/// colidir com a classe `Badge` do próprio Flutter, mesmo cuidado já
/// adotado no código para `GamificationBadge`/`EarnedBadge`
/// (`features/gamification/domain/gamification_badge.dart`, que este
/// componente pode exibir sem depender deles - recebe [label]/[icon]
/// já resolvidos, não a entidade de domínio).
///
/// Achado real do levantamento do UI-02:
/// `gamification_profile_page.dart` já distingue badge conquistado de
/// não conquistado com um ícone de troféu preenchido/contorno +
/// tingimento âmbar ad hoc. Este componente generaliza esse padrão
/// (conquistado = preenchido com `tertiary`; não conquistado = tom
/// neutro) para qualquer selo de status, não só gamificação.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.earned = true,
  });

  final String label;
  final IconData? icon;

  /// `false` renderiza em tom neutro (ex.: badge ainda não conquistado).
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = earned
        ? scheme.tertiary
        : scheme.surfaceContainerHighest;
    final foreground = earned ? scheme.onTertiary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.radiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
