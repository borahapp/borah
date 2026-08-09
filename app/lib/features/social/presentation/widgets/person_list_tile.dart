import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../users/domain/user_profile.dart';
import '../../../users/presentation/widgets/profile_avatar.dart';
import '../../data/follower_repository_impl.dart';

/// Linha de pessoa reutilizada por Busca, "Você pode conhecer" e
/// Seguidores/Seguindo (FASE SOCIAL 2) - avatar, nome, `@username`
/// (omitido quando não existe), contador de seguidores e o botão
/// Seguir/Seguindo.
///
/// Não é um novo "controller de Follow" (pedido explícito do prompt da
/// fase): chama `FollowerRepository.follow`/`unfollow` diretamente e
/// mantém o estado local só desta linha - `FollowController` (DV-07)
/// continua sendo um único estado global, adequado para 1 tela de perfil
/// por vez, mas não para N linhas independentes numa lista.
class PersonListTile extends ConsumerStatefulWidget {
  const PersonListTile({
    super.key,
    required this.person,
    required this.currentUserId,
    required this.initialIsFollowing,
    this.onTap,
  });

  final UserProfile person;
  final String? currentUserId;
  final bool initialIsFollowing;
  final VoidCallback? onTap;

  @override
  ConsumerState<PersonListTile> createState() => _PersonListTileState();
}

class _PersonListTileState extends ConsumerState<PersonListTile> {
  late bool _isFollowing = widget.initialIsFollowing;
  bool _isSubmitting = false;

  @override
  void didUpdateWidget(PersonListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id ||
        oldWidget.initialIsFollowing != widget.initialIsFollowing) {
      _isFollowing = widget.initialIsFollowing;
    }
  }

  Future<void> _toggle() async {
    final currentUserId = widget.currentUserId;
    if (currentUserId == null || currentUserId == widget.person.id) return;

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(followerRepositoryProvider);
      if (_isFollowing) {
        await repository.unfollow(currentUserId, widget.person.id);
      } else {
        await repository.follow(currentUserId, widget.person.id);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnRow = widget.currentUserId == widget.person.id;
    final username = widget.person.username;

    return ListTile(
      onTap: widget.onTap,
      leading: ProfileAvatar(avatarPath: widget.person.avatarUrl, radius: 20),
      title: Text(
        widget.person.fullName?.isNotEmpty == true
            ? widget.person.fullName!
            : 'Sem nome',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (username != null && username.isNotEmpty) Text('@$username'),
          Text('${widget.person.followersCount} seguidores'),
        ],
      ),
      trailing: isOwnRow
          ? null
          : SizedBox(
              width: 112,
              child: AppOutlinedButton(
                label: _isFollowing ? 'Seguindo' : 'Seguir',
                isLoading: _isSubmitting,
                onPressed: _toggle,
              ),
            ),
    );
  }
}
