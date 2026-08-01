import 'group.dart';
import 'group_member.dart';

/// Agregado de domínio: grupo + seus membros (GROUP-02B.1). Entidade
/// própria (não um record) por decisão explícita - base para expansões
/// futuras do domínio (estatísticas, rolês) que também vão precisar do
/// grupo e seus membros juntos.
class GroupDetails {
  const GroupDetails({required this.group, required this.members});

  final Group group;
  final List<GroupMember> members;

  /// Papel do usuário [userId] dentro deste grupo, ou `null` se não for
  /// membro (defensivo - toda tela que chama isto já sabe que o usuário
  /// é membro, já que só chegou aqui via `getById`, que a RLS já
  /// restringe a membros). Usado para decidir o que a UI de
  /// administração (BLOCO 2) mostra a cada usuário.
  GroupMember? ownRole(String? userId) {
    if (userId == null) return null;
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }
}
