import '../../../core/models/paged_result.dart';
import 'group.dart';
import 'group_details.dart';

/// Erro traduzido pela camada de dados - mesmo padrao de
/// `RestaurantRepositoryException`/`AuthRepositoryException` (nenhuma
/// classe base comum existe no projeto; cada feature define a sua).
class GroupRepositoryException implements Exception {
  const GroupRepositoryException(this.message);

  final String message;
}

/// Contrato do dominio, independente de Flutter e Supabase (AR-02).
/// `create` (GROUP-02A), `listMine` (GROUP-02B.0), `getById`
/// (GROUP-02B.1), `joinByInviteCode` (ONBOARDING-01) e `update`/
/// `updateMemberRole`/`removeMember` (BLOCO 2 - administração).
abstract interface class GroupRepository {
  /// FASE SOCIAL 3 - [visibility] default `'private'` (mesmo default da
  /// RPC `create_group()`) - chamar sem o parâmetro preserva o
  /// comportamento de sempre, nenhum grupo passa a ser `public` sem
  /// escolha explícita do criador.
  Future<Group> create({
    required String name,
    String? description,
    String? photoUrl,
    String visibility = 'private',
  });

  /// Grupos dos quais o usuário autenticado é membro, ordenados por
  /// atividade mais recente primeiro. Sem parâmetro de usuário - a RLS
  /// (`groups_select_members`, GROUP-01) já restringe o `SELECT` aos
  /// grupos de `auth.uid()`, então nenhuma cláusula adicional é
  /// necessária no cliente.
  Future<List<Group>> listMine();

  /// Grupo + membros (GROUP-02B.1). Lança [GroupRepositoryException] se
  /// o grupo não existir ou o usuário não for membro (a RLS de
  /// `groups`/`group_members` filtra antes disso).
  Future<GroupDetails> getById(String id);

  /// Entra em um grupo pelo código de convite (ONBOARDING-01). Se o
  /// usuário já for membro, `join_group_by_invite_code()` só retorna o
  /// grupo sem erro (idempotente - `on conflict do nothing`, GROUP-01) -
  /// não há um caso de "já é membro" para tratar aqui.
  Future<Group> joinByInviteCode(String inviteCode);

  /// Edita nome/descrição/foto do grupo (BLOCO 2). Só admin/owner - a
  /// RLS (`groups_update_admin`, GROUP-01) já garante isso; a UI só
  /// mostra a ação para quem `GroupDetails.ownRole` diz ser admin/owner.
  Future<Group> update({
    required String id,
    required String name,
    String? description,
    String? photoUrl,
  });

  /// Promove/rebaixa um membro (BLOCO 2). [memberId] é o `id` da linha
  /// de `group_members`, nunca `userId`+`groupId` (RLS resolve
  /// permissão pelo `id`). [role] deve ser `'admin'` ou `'member'` - a
  /// RLS (`group_members_update_owner`) já bloqueia tentativas de
  /// definir `'owner'` ou de alterar a própria linha do owner.
  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  });

  /// Remove um membro do grupo, ou o próprio usuário saindo (BLOCO 2) -
  /// mesma operação para os dois casos; a RLS
  /// (`group_members_delete_self_or_admin`, GROUP-01) decide se é
  /// permitido: o próprio membro sempre pode remover a si mesmo, ou um
  /// admin/owner pode remover qualquer membro exceto o owner.
  Future<void> removeMember(String memberId);

  /// Transfere a propriedade do grupo para outro membro (FASE C.1). Só o
  /// owner atual pode chamar - a RPC `transfer_group_ownership`
  /// (`security definer`) verifica isso e atualiza `groups.owner_id` e o
  /// papel das duas linhas de `group_members` envolvidas atomicamente
  /// (o chamador vira `admin`, o alvo vira `owner`). Depois de transferir,
  /// o próprio `removeMember` (acima) passa a permitir que o ex-owner
  /// saia do grupo, sem nenhuma mudança nele - a RLS que hoje bloqueia
  /// `removeMember` para `role = 'owner'` deixa de se aplicar.
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerMemberId,
  });

  /// Exclui o grupo (FASE C.1). Só o owner - a RLS (`groups_delete_owner`,
  /// já existente desde o GROUP-01, nunca usada até agora) garante isso.
  /// Único caminho de saída para um owner que é o único membro do grupo
  /// (não há para quem transferir); cascata de FK (`group_members`/
  /// `events`/`event_attendances`/`event_reviews`, todas `on delete
  /// cascade`) já apaga tudo relacionado ao grupo.
  Future<void> delete(String groupId);

  /// FASE SOCIAL 2 - grupos que [currentUserId] e [otherUserId] têm em
  /// comum, para a seção "Grupos em comum" do Perfil público. Sem RLS
  /// nova: a policy `group_members_select_members` (GROUP-01) já
  /// permite ver todas as linhas de um grupo do qual o usuário
  /// autenticado é membro, não só a própria linha - então basta cruzar
  /// os grupos de [currentUserId] com a presença de [otherUserId] neles.
  Future<List<Group>> listCommonGroups(
    String currentUserId,
    String otherUserId,
  );

  /// FASE SOCIAL 3 - busca de grupos `public` por nome (Pesquisa/
  /// Explorar), mesmo padrão `ilike` de `FollowerRepository.searchProfiles`/
  /// `RestaurantRepository.search`. Grupos `private` nunca aparecem -
  /// tanto por filtro explícito quanto pela RLS (`groups_select_members`),
  /// defesa em profundidade. Grupos dos quais o usuário já é membro são
  /// excluídos (ver `PersonListTile`-equivalente desta fase,
  /// `GroupResultTile` - "Você participa" no lugar de "Entrar").
  Future<PagedResult<Group>> search(
    String query, {
    required int page,
    required int limit,
  });

  /// FASE SOCIAL 3 - "Grupos em destaque" (Explorar) - só grupos
  /// `public`, ordenados por `member_count` e depois `last_activity_at`
  /// (nenhum algoritmo, mesmos 2 sinais já existentes/criados nesta
  /// fase). Grupos dos quais o usuário já é membro são excluídos, mesma
  /// regra de `search`.
  Future<PagedResult<Group>> listFeatured({
    required int page,
    required int limit,
  });

  /// FASE SOCIAL 3 - dados básicos de um grupo `public` para quem ainda
  /// não é membro (`PublicGroupProfilePage`) - só a linha de `groups`
  /// (nome/foto/descrição/`memberCount`), nunca a lista de membros
  /// (`group_members` continua fechada a não-membros, decisão de
  /// produto desta fase).
  Future<Group> getPublicSummary(String groupId);

  /// FASE SOCIAL 3 - entra instantaneamente num grupo `public`, sem
  /// código de convite (`join_public_group()`, `SECURITY DEFINER` -
  /// valida `visibility = 'public'` no servidor, nunca confia só na UI
  /// já ter checado isso).
  Future<Group> joinPublicGroup(String groupId);

  /// FASE SOCIAL 3 - ids de todos os grupos dos quais [userId] já é
  /// membro - usado por `search`/`listFeatured` na UI para marcar "Você
  /// participa" em vez de "Entrar" (decisão de produto: grupos dos
  /// quais o usuário já participa continuam aparecendo normalmente na
  /// busca/destaque, nunca são escondidos).
  Future<Set<String>> listMyGroupIds(String userId);
}
