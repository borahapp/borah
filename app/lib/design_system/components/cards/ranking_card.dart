import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import 'app_card.dart';

/// Card de posição em ranking do BORAH (restaurantes ou usuários).
///
/// Achado real do levantamento do UI-02: `rankings_page.dart` e
/// `ranking_users_page.dart` já usam o mesmo padrão (`CircleAvatar`
/// com o número da posição + nome + subtítulo + valor à direita) como
/// `ListTile` cru, duplicado entre os dois arquivos.
class RankingCard extends StatelessWidget {
  const RankingCard({
    super.key,
    required this.position,
    required this.name,
    this.subtitle,
    this.trailingLabel,
    this.onTap,
  });

  final int position;
  final String name;
  final String? subtitle;

  /// Ex.: "4.5 (12)" ou "1.240 pts".
  final String? trailingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(child: Text('$position')),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailingLabel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(trailingLabel!, style: theme.textTheme.labelLarge),
          ],
        ],
      ),
    );
  }
}
