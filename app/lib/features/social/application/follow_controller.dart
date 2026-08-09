import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/follower_repository_impl.dart';
import '../domain/follower_repository.dart';
import '../presentation/states/follow_status.dart';

/// Seguir/deixar de seguir um usuário específico (DV-07), usado pela tela
/// de Perfil público. Diferente do `FavoriteToggleController` (DV-06),
/// não há atualização otimista aqui - não solicitada para este módulo.
class FollowController extends Notifier<FollowStatus> {
  @override
  FollowStatus build() => const FollowInitial();

  FollowerRepository get _repository => ref.read(followerRepositoryProvider);

  Future<void> load(String followerId, String followingId) async {
    state = const FollowLoading();
    try {
      final isFollowing = await _repository.isFollowing(
        followerId,
        followingId,
      );
      state = FollowLoaded(isFollowing);
    } on FollowerRepositoryException catch (e) {
      state = FollowError(e.message);
    } catch (_) {
      state = const FollowError('Não foi possível verificar o status.');
    }
  }

  Future<void> toggle(String followerId, String followingId) async {
    // FASE SOCIAL 2 - defesa em profundidade: a UI já esconde o botão
    // Seguir no próprio perfil e o banco tem
    // `followers_no_self_follow` (CHECK), mas este controller não deve
    // depender só de quem o chama nunca passar os dois ids iguais.
    if (followerId == followingId) {
      state = const FollowError('Você não pode seguir a si mesmo.');
      return;
    }

    final current = state;
    final isFollowing = current is FollowLoaded ? current.isFollowing : false;

    state = const FollowLoading();
    try {
      if (isFollowing) {
        await _repository.unfollow(followerId, followingId);
      } else {
        await _repository.follow(followerId, followingId);
      }
      state = FollowLoaded(!isFollowing);
    } on FollowerRepositoryException catch (e) {
      state = FollowError(e.message);
    } catch (_) {
      state = const FollowError('Não foi possível atualizar o status.');
    }
  }
}

final followControllerProvider =
    NotifierProvider<FollowController, FollowStatus>(FollowController.new);
