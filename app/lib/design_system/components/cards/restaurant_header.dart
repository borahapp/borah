import 'package:flutter/material.dart';

import '../../tokens/app_gradients.dart';
import '../../tokens/app_icon_size.dart';
import '../../tokens/app_spacing.dart';
import '../avatars/user_avatar.dart';

/// Cabeçalho de contexto de restaurante do BORAH (RC-03, FASE A2 -
/// `BORAH_VISION_v2.0.md`).
///
/// Extraído de `submit_event_review_page.dart` (FASE A1) para virar
/// componente de Design System, por decisão explícita do usuário -
/// candidato direto de reuso em Feed, Memórias, Perfil e Histórico
/// (telas ainda não implementadas nesta rodada), sempre que uma tela
/// precisar comunicar "isto é sobre este restaurante, neste momento".
///
/// Recebe só primitivos (nome/legenda/foto já resolvidos), nunca uma
/// entidade de domínio (`Restaurant`/`Event`) - mesma regra já aplicada
/// a `GroupCard`/`EventCard`/`RestaurantCard`. Formatação de data (ou
/// qualquer outro texto de [subtitle]) é responsabilidade de quem
/// chama, nunca deste componente - `BORAH_VISION_v2.0.md`, Capítulo 12.
class RestaurantHeader extends StatelessWidget {
  const RestaurantHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.photoUrl,
  });

  final String name;

  /// Ex.: uma data já formatada ("04/08/2026"). Livre para outros
  /// contextos futuros (Feed/Memórias) mostrarem outra coisa aqui -
  /// por isso é texto genérico, não `DateTime`.
  final String? subtitle;

  /// URL já resolvida da foto do restaurante. `null`/vazia mostra o
  /// ícone padrão de [UserAvatar] sobre o gradiente.
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradients = AppGradients.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(gradient: gradients.purple),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: photoUrl,
            radius: AppIconSize.xl / 2,
            fallbackIcon: Icons.restaurant,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
