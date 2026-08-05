import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Avatar de usuário do BORAH — componente de apresentação puro,
/// recebe a URL **já resolvida** da imagem (ou os bytes, para preview
/// local antes do upload).
///
/// Diferente de `features/users/presentation/widgets/profile_avatar.dart`
/// (`ProfileAvatar`), que resolve a URL assinada chamando
/// `userProfileControllerProvider` diretamente — acoplado a uma
/// feature específica, não é um componente de design system puro
/// (UI-06 §2: "independentes de regras de negócio"). `UserAvatar` não
/// depende de nenhum provider; quem chama resolve a URL/bytes antes.
///
/// `ProfilePage`/`PublicProfilePage` continuam usando `ProfileAvatar`
/// nesta rodada — migrá-las para `UserAvatar` fica para uma rodada
/// futura (nenhuma tela é alterada no UI-02).
///
/// [imageBytes] (RC-03 Sprint 1, `RC03_DESIGN_GAP.md §1.4`) fecha a
/// unificação de avatar identificada no `RC03_UI_AUDIT.md §6` — antes
/// desta extensão, `change_avatar_page.dart` precisava de um
/// `CircleAvatar` cru à parte para mostrar o preview local (recém
/// selecionado, ainda sem URL) porque `UserAvatar` só aceitava
/// `NetworkImage`. A fusão de `change_avatar_page.dart` em
/// `edit_profile_page.dart` (Sprint 6) é quem efetivamente passa a usar
/// isso - nenhuma tela é alterada nesta rodada.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.radius = 24,
    this.fallbackIcon = Icons.person,
    this.backgroundColor,
  });

  /// URL já resolvida (ex.: signed URL do Storage). Ignorado quando
  /// [imageBytes] é informado.
  final String? imageUrl;

  /// Bytes de uma imagem selecionada localmente, ainda não enviada
  /// (preview pré-upload). Tem prioridade sobre [imageUrl] quando os
  /// dois são informados.
  final Uint8List? imageBytes;

  final double radius;
  final IconData fallbackIcon;

  /// Cor de fundo do círculo quando nenhuma imagem é exibida (ícone
  /// padrão). Ex.: `GroupCard` usa isso como "cor de destaque" do grupo
  /// quando não há foto (`RC03_DESIGN_GAP.md §1.3`: "foto/cor de
  /// destaque"). `null` mantém a cor padrão do tema.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(imageBytes!),
      );
    }
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(fallbackIcon),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl!),
    );
  }
}
