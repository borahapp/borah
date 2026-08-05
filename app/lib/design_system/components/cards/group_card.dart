import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../avatars/user_avatar.dart';
import 'app_card.dart';

/// Card de grupo do BORAH.
///
/// Especificado em `RC03_DESIGN_GAP.md §1.3`/`§3` (item Core do
/// `RC03_FEATURE_GAP.md`, F46) para substituir o `ListTile` cru de
/// `groups_list_page.dart` (Sprint 3) — hoje a Home do app não tem
/// nenhum card dedicado a grupo, apesar de `RestaurantCard`/`RankingCard`
/// já existirem para os outros casos. Recebe dados primitivos (não a
/// entidade `Group`), mesma regra de desacoplamento já aplicada a
/// `RestaurantCard` (UI-06 §16.6: "nenhum componente importa uma
/// entidade de domínio de `features/`").
///
/// Não é consumido em nenhuma tela nesta rodada (Sprint 1) - a aplicação
/// em `groups_list_page.dart` é escopo da Sprint 3.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.name,
    required this.memberCount,
    this.photoUrl,
    this.accentColor,
    this.nextEventLabel,
    this.onTap,
  });

  final String name;
  final int memberCount;

  /// URL já resolvida da foto do grupo — `null`/vazia mostra o ícone
  /// padrão de [UserAvatar].
  final String? photoUrl;

  /// Cor de destaque do grupo, usada como fundo do avatar quando não há
  /// [photoUrl] (`RC03_DESIGN_GAP.md §1.3`: "foto/cor de destaque").
  /// Ignorado quando [photoUrl] é informado.
  final Color? accentColor;

  /// Ex.: "Próximo rolê: 12/08". `null` mostra "Sem rolês ainda" (convite
  /// implícito à ação, conforme `RC03_DESIGN_GAP.md §1.3`).
  final String? nextEventLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memberLabel = memberCount == 1
        ? '1 integrante'
        : '$memberCount integrantes';

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          UserAvatar(
            imageUrl: photoUrl,
            radius: 24,
            fallbackIcon: Icons.groups,
            backgroundColor: photoUrl == null ? accentColor : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(memberLabel, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  nextEventLabel ?? 'Sem rolês ainda',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
