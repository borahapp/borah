import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../badges/app_badge.dart';
import 'app_card.dart';

/// Card de rolê (evento) do BORAH.
///
/// Especificado em `RC03_DESIGN_GAP.md §1.3`/`§3` (item Core do
/// `RC03_FEATURE_GAP.md`, F46) para substituir o `ListTile` cru de
/// `events_list_page.dart` (Sprint 5) — a mesma tela já usa `AppCard`
/// para os cards de Memórias, então a lista de rolês abaixo deles hoje
/// destoa visualmente por comparação. Recebe dados primitivos, mesma
/// regra de `RestaurantCard`/`GroupCard`.
///
/// O selo de status reaproveita [AppBadge] (não um componente novo),
/// seguindo exatamente o padrão já em produção em
/// `event_detail_page.dart:238` (`AppBadge(label: event.statusLabel,
/// earned: false)`, oculto quando `status == 'scheduled'`).
///
/// Não é consumido em nenhuma tela nesta rodada (Sprint 1) - a aplicação
/// em `events_list_page.dart` é escopo da Sprint 5.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.restaurantName,
    required this.dateTimeLabel,
    required this.confirmedCount,
    required this.status,
    required this.statusLabel,
    this.onTap,
  });

  final String restaurantName;

  /// Já formatado pelo chamador (ex.: "12/08 às 20h").
  final String dateTimeLabel;

  final int confirmedCount;

  /// Valor bruto ('scheduled'/'completed'/'cancelled') - só decide se o
  /// selo aparece (oculto quando 'scheduled', mesmo critério de
  /// `event_detail_page.dart`). O texto exibido vem de [statusLabel].
  final String status;

  /// Rótulo já resolvido (ex.: `event.statusLabel` do domínio).
  final String statusLabel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmedLabel = confirmedCount == 1
        ? '1 confirmado'
        : '$confirmedCount confirmados';

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurantName,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (status != 'scheduled') ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppBadge(label: statusLabel, earned: false),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(dateTimeLabel, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(confirmedLabel, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
