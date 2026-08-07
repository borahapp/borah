import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../avatars/user_avatar.dart';
import '../badges/app_badge.dart';
import 'app_card.dart';

/// Card de rolê (evento) do BORAH.
///
/// Especificado em `RC03_DESIGN_GAP.md §1.3`/`§3` (item Core do
/// `RC03_FEATURE_GAP.md`, F46) para substituir o `ListTile` cru que
/// `events_list_page.dart` usava para cada rolê — a mesma tela já usa
/// `AppCard` para os cards de Memórias, então a lista de rolês abaixo
/// deles destoava visualmente por comparação. Recebe dados primitivos,
/// mesma regra de `RestaurantCard`/`GroupCard`.
///
/// O selo de status reaproveita [AppBadge] (não um componente novo),
/// seguindo exatamente o padrão já em produção em
/// `event_detail_page.dart:238` (`AppBadge(label: event.statusLabel,
/// earned: false)`, oculto quando `status == 'scheduled'`).
///
/// Consumido em `events_list_page.dart` desde a FASE B0 (auditoria de
/// componentes RC-03) - `restaurantPhotoUrl` foi adicionado na mesma
/// rodada, ao notar que `GroupCard`, o componente irmão desta mesma
/// leva (F46), já tinha identidade visual própria e este não.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.restaurantName,
    required this.dateTimeLabel,
    required this.confirmedCount,
    required this.status,
    required this.statusLabel,
    this.restaurantPhotoUrl,
    this.onTap,
  });

  final String restaurantName;

  /// URL já resolvida da foto de capa do restaurante (mesmo dado de
  /// `Event.restaurantCoverImage`, FASE A1) — `null`/vazia mostra o
  /// ícone padrão de [UserAvatar]. Adicionado na auditoria do primeiro
  /// consumidor real (FASE B0): `GroupCard`, o componente irmão desta
  /// mesma leva (F46), já tinha essa identidade visual desde a Sprint
  /// 1 — sem ela aqui, `EventCard` era a única das duas "cards de
  /// identidade" do loop central sem nenhuma foto.
  final String? restaurantPhotoUrl;

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
          UserAvatar(
            imageUrl: restaurantPhotoUrl,
            radius: 24,
            fallbackIcon: Icons.restaurant,
          ),
          const SizedBox(width: AppSpacing.md),
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
