import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/user_profile_controller.dart';

/// Exibe o avatar do usuário. Como o bucket `avatars` é privado (AR-08),
/// resolve uma URL assinada temporária em vez de usar a `avatarPath` direta.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, required this.avatarPath, this.radius = 40});

  final String? avatarPath;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (avatarPath == null || avatarPath!.isEmpty) {
      return CircleAvatar(radius: radius, child: const Icon(Icons.person));
    }

    return FutureBuilder<String?>(
      future: ref
          .read(userProfileControllerProvider.notifier)
          .avatarDisplayUrl(avatarPath),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) {
          return CircleAvatar(radius: radius, child: const Icon(Icons.person));
        }
        return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
      },
    );
  }
}
