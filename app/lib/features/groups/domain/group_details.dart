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
}
