import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/avatars/user_avatar.dart';
import '../../application/user_profile_controller.dart';

/// Exibe o avatar do usuário. Como o bucket `avatars` é privado (AR-08),
/// resolve uma URL assinada temporária em vez de usar a `avatarPath` direta.
///
/// A renderização em si (placeholder vs. foto) delega a [UserAvatar]
/// (UI-02/UI-03) — só a resolução da URL assinada via
/// `userProfileControllerProvider` continua aqui, já que [UserAvatar] é
/// deliberadamente desacoplado de qualquer provider.
class ProfileAvatar extends ConsumerStatefulWidget {
  const ProfileAvatar({super.key, required this.avatarPath, this.radius = 40});

  final String? avatarPath;
  final double radius;

  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  Future<String?>? _future;

  @override
  void initState() {
    super.initState();
    _resolveUrl();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // RC-04E: antes, o Future era criado direto dentro de `build()` -
    // qualquer rebuild (mesmo sem o avatar ter mudado) recriava a
    // instância e fazia o `FutureBuilder` voltar ao estado de loading,
    // gerando flicker e chamadas de rede evitáveis a cada rebuild. Só
    // resolve de novo quando `avatarPath` de fato muda.
    if (oldWidget.avatarPath != widget.avatarPath) {
      _resolveUrl();
    }
  }

  void _resolveUrl() {
    final avatarPath = widget.avatarPath;
    _future = avatarPath == null || avatarPath.isEmpty
        ? null
        : ref
              .read(userProfileControllerProvider.notifier)
              .avatarDisplayUrl(avatarPath);
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return UserAvatar(radius: widget.radius);
    }

    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snapshot) {
        return UserAvatar(imageUrl: snapshot.data, radius: widget.radius);
      },
    );
  }
}
