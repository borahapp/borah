import 'package:flutter/material.dart';

import '../../../../design_system/components/avatars/user_avatar.dart';
import '../../../../design_system/components/badges/app_badge.dart';
import '../../domain/group.dart';

/// Linha de grupo reutilizada por Busca e "Grupos em destaque" (FASE
/// SOCIAL 3) - avatar, nome, contagem de membros. Sem botão de ação
/// (diferente de `PersonListTile`): o próprio toque na linha navega -
/// para `/groups/:id` se [isMember], para `/groups/:id/preview` caso
/// contrário (decisão do chamador, este widget só exibe o estado
/// "Você participa").
class GroupResultTile extends StatelessWidget {
  const GroupResultTile({
    super.key,
    required this.group,
    required this.isMember,
    this.onTap,
  });

  final Group group;
  final bool isMember;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final memberCount = group.memberCount ?? 0;
    final memberLabel = memberCount == 1 ? '1 membro' : '$memberCount membros';

    return ListTile(
      onTap: onTap,
      leading: UserAvatar(
        imageUrl: group.photoUrl,
        radius: 20,
        fallbackIcon: Icons.groups,
      ),
      title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(memberLabel),
      trailing: isMember
          ? const AppBadge(label: 'Você participa')
          : const Icon(Icons.chevron_right),
    );
  }
}
