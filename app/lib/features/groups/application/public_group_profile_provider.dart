import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_repository_impl.dart';
import '../domain/group.dart';

/// FASE SOCIAL 3 - leitura pontual de um grupo `public` para quem ainda
/// não é membro (`PublicGroupProfilePage`). Mesmo padrão de
/// `publicProfileProvider` (FASE SOCIAL 2, pessoas): `FutureProvider.family`
/// isolado por [groupId], não um controller - a tela é só leitura + um
/// botão de ação (`JoinGroupController`, já existente).
final publicGroupSummaryProvider = FutureProvider.family<Group, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).getPublicSummary(groupId);
});
