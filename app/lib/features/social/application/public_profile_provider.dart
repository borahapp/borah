import 'package:flutter_riverpod/flutter_riverpod.dart';

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
