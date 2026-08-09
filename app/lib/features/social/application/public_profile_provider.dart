import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_controller.dart';
import '../../gamification/data/gamification_repository_impl.dart';
import '../../gamification/domain/gamification_badge.dart';
import '../../gamification/domain/user_progress.dart';
import '../../groups/data/group_repository_impl.dart';
import '../../groups/domain/group.dart';
import '../../users/data/user_profile_repository_impl.dart';
import '../../users/domain/user_profile.dart';

/// Leitura pontual do perfil de um usuário arbitrário (Perfil público,
/// DV-07). Deliberadamente separado de `userProfileControllerProvider`
/// (DV-02): aquele é o controller de edição do PRÓPRIO perfil, com
/// estados de "Updating"/"UpdateSuccess" que não fazem sentido aqui, e
/// compartilhar a mesma instância causaria uma tela sobrescrever o
/// estado da outra. Depende de `UserProfileRepository` (domínio), não do
/// controller de apresentação do DV-02.
final publicProfileProvider = FutureProvider.family<UserProfile, String>((
  ref,
  userId,
) {
  return ref.watch(userProfileRepositoryProvider).getProfile(userId);
});

/// Nível/XP/badges de um usuário arbitrário (FASE SOCIAL 2). Não
/// reaproveita `gamificationProfileControllerProvider` (DV-10) de
/// propósito: aquele é um único `Notifier` global, e `ProfilePage`
/// (próprio usuário) fica montada em segundo plano dentro do
/// `IndexedStack` de `HomeShellPage` enquanto `PublicProfilePage` (de
/// outra pessoa) é empilhada por cima - as duas usando o mesmo
/// `Notifier` simultaneamente faria uma tela sobrescrever o estado da
/// outra ao voltar. `FutureProvider.family` isola por [userId] sem esse
/// risco, mesmo padrão de `publicProfileProvider` acima. A auditoria já
/// confirmou que `getProgress`/`listEarnedBadges` aceitam qualquer
/// `userId` e a RLS já é pública - nenhuma migration/RPC nova.
typedef PublicProfileGamification = ({
  UserProgress progress,
  List<GamificationBadge> allBadges,
  Set<String> earnedBadgeIds,
});

final publicProfileGamificationProvider =
    FutureProvider.family<PublicProfileGamification, String>((
      ref,
      userId,
    ) async {
      final repository = ref.watch(gamificationRepositoryProvider);
      final progress = await repository.getProgress(userId);
      final allBadges = await repository.listAllBadges();
      final earnedBadges = await repository.listEarnedBadges(userId);
      return (
        progress: progress,
        allBadges: allBadges,
        earnedBadgeIds: earnedBadges.map((e) => e.badge.id).toSet(),
      );
    });

/// Grupos em comum entre o usuário logado e [otherUserId] (FASE SOCIAL
/// 2) - ver `GroupRepository.listCommonGroups`. Sem usuário logado
/// (não deveria acontecer numa tela protegida), retorna lista vazia em
/// vez de lançar.
final publicProfileCommonGroupsProvider =
    FutureProvider.family<List<Group>, String>((ref, otherUserId) async {
      final currentUserId = ref.watch(currentUserIdProvider);
      if (currentUserId == null) return [];
      return ref
          .watch(groupRepositoryProvider)
          .listCommonGroups(currentUserId, otherUserId);
    });
