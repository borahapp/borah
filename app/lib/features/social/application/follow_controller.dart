import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../users/application/user_profile_controller.dart';
import '../data/follower_repository_impl.dart';
import '../domain/follower_repository.dart';
import '../presentation/states/follow_status.dart';
import 'feed_controller.dart';
import 'public_profile_provider.dart';

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
      _refreshDependentState(followerId, followingId);
    } on FollowerRepositoryException catch (e) {
      state = FollowError(e.message);
    } catch (_) {
      state = const FollowError('Não foi possível atualizar o status.');
    }
  }

  /// 2B.3-G (fix do F2 da auditoria 2B.3-F): `followers`/`following_count`
  /// mudaram de verdade no backend - atualiza os providers que dependem
  /// dessa relação em vez de esperar o usuário sair e voltar para a aba
  /// (que não reexecutaria `initState` mesmo assim, já que `HomeShellPage`
  /// mantém as 4 páginas vivas num `IndexedStack`). `ref.watch` continua
  /// reativo em widgets escondidos-mas-montados, então isto já é
  /// suficiente sem tocar no `IndexedStack` ou introduzir polling.
  void _refreshDependentState(String followerId, String followingId) {
    ref.read(userProfileControllerProvider.notifier).loadProfile(followerId);
    ref.invalidate(publicProfileProvider(followingId));
    ref.read(feedFollowingControllerProvider.notifier).refresh();
  }
}

final followControllerProvider =
    NotifierProvider<FollowController, FollowStatus>(FollowController.new);
