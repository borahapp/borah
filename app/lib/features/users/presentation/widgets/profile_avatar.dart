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
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, required this.avatarPath, this.radius = 40});

  final String? avatarPath;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (avatarPath == null || avatarPath!.isEmpty) {
      return UserAvatar(radius: radius);
    }

    return FutureBuilder<String?>(
      future: ref
          .read(userProfileControllerProvider.notifier)
          .avatarDisplayUrl(avatarPath),
      builder: (context, snapshot) {
        return UserAvatar(imageUrl: snapshot.data, radius: radius);
      },
    );
  }
}
