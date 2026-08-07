import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_repository_impl.dart';
import '../domain/group_repository.dart';
import '../presentation/states/group_detail_status.dart';

class GroupDetailController extends Notifier<GroupDetailStatus> {
  @override
  GroupDetailStatus build() => const GroupDetailInitial();

  GroupRepository get _repository => ref.read(groupRepositoryProvider);

  Future<void> load(String id) async {
    state = const GroupDetailLoading();
    try {
      final details = await _repository.getById(id);
      state = GroupDetailLoaded(details);
    } on GroupRepositoryException catch (e) {
      state = GroupDetailError(e.message, null);
    } catch (_) {
      state = const GroupDetailError(
        'Não foi possível carregar o grupo.',
        null,
      );
    }
  }

  /// GROUP-02B.1: prepara o texto do convite - a página só dispara o
  /// compartilhamento nativo (`Share.share`), não decide o conteúdo.
  /// Retorna `null` se não houver grupo carregado (a página só oferece
  /// o botão de compartilhar quando o estado já é `GroupDetailLoaded`,
  /// então isso é só uma proteção defensiva).
  ///
  /// Deep Link de convite (`borah://group/join?code=X`) incluído a
  /// partir daqui - quem recebe e já tem o app instalado entra direto,
  /// sem digitar o código; o código continua no texto para quem não
  /// reconhece o link (mesmo cliente que já ignorava um esquema
  /// customizado antes disso).
  String? buildInviteShareMessage() {
    final current = state;
    if (current is! GroupDetailLoaded) return null;

    final group = current.details.group;
    return 'Entre no meu grupo "${group.name}" no BORAH! '
        'borah://group/join?code=${group.inviteCode}\n'
        'Ou use o código de convite: ${group.inviteCode}';
  }

  /// Promove/rebaixa um membro (BLOCO 2). Recarrega do servidor após o
  /// sucesso - diferente de `EventDetailController.confirm/decline`
  /// (ROLÊ-03), aqui não há ganho de UX em atualização otimista (ação
  /// administrativa pontual, não um loop de 1 toque recorrente), então
  /// o caminho mais simples (recarregar) é o certo.
  Future<void> promoteToAdmin(String memberId) => _mutate(
    () => _repository.updateMemberRole(memberId: memberId, role: 'admin'),
  );

  Future<void> demoteToMember(String memberId) => _mutate(
    () => _repository.updateMemberRole(memberId: memberId, role: 'member'),
  );

  /// Remove outro membro do grupo (BLOCO 2, ação de admin/owner).
  Future<void> removeMember(String memberId) =>
      _mutate(() => _repository.removeMember(memberId));

  /// Sair do grupo (BLOCO 2) é deliberadamente diferente das ações
  /// acima: em vez de recarregar (o usuário deixou de ser membro, um
  /// `load()` subsequente falharia pela RLS), a própria operação é
  /// exposta para a página decidir - sucesso significa fechar a tela e
  /// voltar para a lista de grupos, não continuar mostrando este grupo.
  Future<void> leaveGroup(String memberId) =>
      _repository.removeMember(memberId);

  Future<void> _mutate(Future<void> Function() action) async {
    final current = state;
    final details = switch (current) {
      GroupDetailLoaded(:final details) => details,
      GroupDetailError(:final details) => details,
      _ => null,
    };
    if (details == null) return;

    try {
      await action();
      await load(details.group.id);
    } on GroupRepositoryException catch (e) {
      state = GroupDetailError(e.message, details);
    } catch (_) {
      state = GroupDetailError('Não foi possível concluir a ação.', details);
    }
  }
}

final groupDetailControllerProvider =
    NotifierProvider<GroupDetailController, GroupDetailStatus>(
      GroupDetailController.new,
    );
