import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/data/group_repository_impl.dart';
import '../../groups/domain/group_member.dart';
import '../data/event_repository_impl.dart';

/// RC-03 F36 - sugestão de "rodízio justo": quem, entre os membros do
/// grupo, não organiza um rolê há mais tempo (ou nunca organizou).
/// Puramente informativo - nunca uma trava (`create_event_page.dart`
/// continua permitindo qualquer membro criar o rolê, a sugestão é só
/// exibida). Implementado inteiramente no cliente, sem migration/RPC
/// nova: reaproveita `GroupRepository.getById` (membros) e
/// `EventRepository.listByGroup` (histórico de `organizerId`), ambos já
/// usados por outras telas - nenhum dado novo precisa ser buscado do
/// zero.
final rotationSuggestionProvider = FutureProvider.family<GroupMember?, String>((
  ref,
  groupId,
) async {
  final details = await ref.watch(groupRepositoryProvider).getById(groupId);
  if (details.members.length < 2) return null;

  final events = await ref.watch(eventRepositoryProvider).listByGroup(groupId);

  final lastOrganizedAt = <String, DateTime>{};
  for (final event in events) {
    final current = lastOrganizedAt[event.organizerId];
    if (current == null || event.scheduledAt.isAfter(current)) {
      lastOrganizedAt[event.organizerId] = event.scheduledAt;
    }
  }

  // Quem nunca organizou (sem entrada em `lastOrganizedAt`) sempre vence
  // qualquer data real - mesma prioridade de "está há mais tempo sem
  // escolher". Entre os que nunca organizaram, o primeiro da lista de
  // membros vence (ordem estável, sem outro critério de desempate
  // disponível). `details.members` nunca é reordenado por esta função.
  final neverOrganized = details.members
      .where((member) => !lastOrganizedAt.containsKey(member.userId))
      .toList();
  if (neverOrganized.isNotEmpty) return neverOrganized.first;

  var suggestion = details.members.first;
  var suggestionLastOrganizedAt = lastOrganizedAt[suggestion.userId]!;
  for (final member in details.members.skip(1)) {
    final memberLastOrganizedAt = lastOrganizedAt[member.userId]!;
    if (memberLastOrganizedAt.isBefore(suggestionLastOrganizedAt)) {
      suggestion = member;
      suggestionLastOrganizedAt = memberLastOrganizedAt;
    }
  }
  return suggestion;
});
