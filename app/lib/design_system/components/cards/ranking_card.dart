import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_spacing.dart';
import 'app_card.dart';

/// Card de posição em ranking do BORAH (restaurantes ou usuários).
///
/// Achado real do levantamento do UI-02: `rankings_page.dart` e
/// `ranking_users_page.dart` já usam o mesmo padrão (`CircleAvatar`
/// com o número da posição + nome + subtítulo + valor à direita) como
/// `ListTile` cru, duplicado entre os dois arquivos.
///
/// Desde a IV-07, as 3 primeiras posições mostram a medalha oficial
/// (`medal_1`/`medal_2`/`medal_3`, "primeiro/segundo/terceiro lugar"
/// por definição do catálogo de ativos) em vez do número dentro de um
/// `CircleAvatar` - aplica-se automaticamente às duas telas de ranking
/// que já compartilham este componente. Posições 4+ continuam com o
/// número simples.
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

  static const _medalAssetByPosition = {
    1: 'assets/borah/ui/ranking/medal_1.svg',
    2: 'assets/borah/ui/ranking/medal_2.svg',
    3: 'assets/borah/ui/ranking/medal_3.svg',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medalAsset = _medalAssetByPosition[position];

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          medalAsset == null
              ? CircleAvatar(child: Text('$position'))
              : SvgPicture.asset(
                  medalAsset,
                  width: 40,
                  height: 40,
                  semanticsLabel: '$positionº lugar',
                ),
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
