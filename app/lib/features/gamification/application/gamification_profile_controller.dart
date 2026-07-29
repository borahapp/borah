import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gamification_repository_impl.dart';
import '../domain/gamification_repository.dart';
import '../presentation/states/gamification_profile_status.dart';

/// Une "Perfil de Gamificação", "Conquistas" e "Badges" (DV-10 §6) em uma
/// única tela/controller: as três telas mostram o mesmo catálogo de
/// badges, apenas marcando o que já foi conquistado - mesma consolidação
/// já aplicada a Listagem+Busca no DV-03.
class GamificationProfileController
    extends Notifier<GamificationProfileStatus> {
  @override
  GamificationProfileStatus build() => const GamificationProfileInitial();

  GamificationRepository get _repository =>
      ref.read(gamificationRepositoryProvider);

  Future<void> loadForUser(String userId) async {
    state = const GamificationProfileLoading();
    try {
      final progress = await _repository.getProgress(userId);
      final allBadges = await _repository.listAllBadges();
      final earnedBadges = await _repository.listEarnedBadges(userId);

      state = GamificationProfileLoaded(
        progress: progress,
        allBadges: allBadges,
        earnedBadgeIds: earnedBadges.map((e) => e.badge.id).toSet(),
      );
    } on GamificationRepositoryException catch (e) {
      state = GamificationProfileError(e.message);
    } catch (_) {
      state = const GamificationProfileError(
        'Não foi possível carregar sua gamificação.',
      );
    }
  }
}

final gamificationProfileControllerProvider =
    NotifierProvider<GamificationProfileController, GamificationProfileStatus>(
      GamificationProfileController.new,
    );
