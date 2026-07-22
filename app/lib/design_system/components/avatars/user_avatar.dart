import 'package:flutter/material.dart';

/// Avatar de usuário do BORAH — componente de apresentação puro,
/// recebe a URL **já resolvida** da imagem.
///
/// Diferente de `features/users/presentation/widgets/profile_avatar.dart`
/// (`ProfileAvatar`), que resolve a URL assinada chamando
/// `userProfileControllerProvider` diretamente — acoplado a uma
/// feature específica, não é um componente de design system puro
/// (UI-06 §2: "independentes de regras de negócio"). `UserAvatar` não
/// depende de nenhum provider; quem chama resolve a URL antes.
///
/// `ProfilePage`/`PublicProfilePage` continuam usando `ProfileAvatar`
/// nesta rodada — migrá-las para `UserAvatar` fica para uma rodada
/// futura (nenhuma tela é alterada no UI-02).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackIcon = Icons.person,
  });

  /// URL já resolvida (ex.: signed URL do Storage) — `null`/vazia
  /// mostra [fallbackIcon].
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(radius: radius, child: Icon(fallbackIcon));
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl!),
    );
  }
}
