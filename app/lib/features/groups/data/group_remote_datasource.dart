import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula todo acesso a `groups`/`group_members` via PostgREST
/// (GROUP-02A em diante).
///
/// `create_group()` e uma funcao Postgres `SECURITY DEFINER`
/// (migration `20260731090000_create_groups_and_group_members.sql`) -
/// insere o grupo e o proprio chamador como `owner` em `group_members`
/// na mesma transacao (INSERT direto em `groups`/`group_members` e
/// bloqueado por RLS para o cliente). `auth.uid()` e resolvido pela
/// propria funcao no Postgres - nenhum id de usuario e passado como
/// parametro. Nomes dos parametros (`p_name`/`p_description`/
/// `p_photo_url`) precisam bater exatamente com a assinatura da funcao.
class GroupRemoteDatasource {
  GroupRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _groupsTable = 'groups';
  static const _membersTable = 'group_members';
  static const _profilesTable = 'profiles';
  static const _eventsTable = 'events';

  /// FASE SOCIAL 3 - colunas de `groups` que toda consulta desta classe
  /// passa a selecionar (além das que cada método já buscava), para que
  /// `GroupRepositoryImpl._mapRow` sempre tenha `visibility`/
  /// `member_count` disponíveis, nunca dependendo de valor default de
  /// fallback por coluna ausente.
  static const _visibilityColumns = 'visibility,member_count';

  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
    String? photoUrl,
    required String visibility,
  }) async {
    final result = await _client.rpc(
      'create_group',
      params: {
        'p_name': name,
        'p_description': description,
        'p_photo_url': photoUrl,
        'p_visibility': visibility,
      },
    );
    return result as Map<String, dynamic>;
  }

  /// GROUP-02B.0: `SELECT` direto, sem RPC - a policy `groups_select_members`
  /// (GROUP-01) já restringe as linhas retornadas aos grupos do usuário
  /// autenticado, então nenhum filtro adicional é necessário aqui.
  ///
  /// Sprint 3 (F46, `RC03_IMPLEMENTATION_PLAN.md`): `group_members(count)`
  /// é um embed de agregação do PostgREST - `group_members.group_id` é FK
  /// real de `groups.id`, então a contagem de integrantes vem nesta mesma
  /// consulta, sem migration nem N+1. Retorna `group_members: [{count: N}]`
  /// por linha (formato padrão do PostgREST para embed de `count`).
  ///
  /// Sem `description` (auditoria pós-Sprint 3): `GroupCard` não tem
  /// slot para descrição (`RC03_DESIGN_GAP.md §1.3` nunca previu isso
  /// aqui) e `groups_list_page.dart` é a única chamadora - buscar essa
  /// coluna seria over-fetching sem consumidor. `fetchGroupById`/
  /// `updateGroup` abaixo continuam selecionando `description` porque
  /// `group_detail_page.dart`/`edit_group_page.dart` de fato a exibem.
  Future<List<Map<String, dynamic>>> listMine() async {
    final rows = await _client
        .from(_groupsTable)
        .select(
          'id,name,photo_url,invite_code,group_members(count),$_visibilityColumns',
        )
        .order('last_activity_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Sprint 3 (F46): próximo rolê agendado de cada grupo em [groupIds],
  /// para a prévia do `GroupCard`. 1 consulta em lote (não N+1) - mesmo
  /// padrão de composição já usado por `fetchProfilesByIds` abaixo
  /// (consulta direta a uma tabela de outra feature, sem view/RPC nova).
  /// Mesma definição de "próximo" já usada por `Event.isUpcoming`
  /// (`status == 'scheduled' && scheduledAt.isAfter(now)`). Ordenado
  /// ascendente por `scheduled_at`: o chamador pode ficar só com a
  /// primeira ocorrência de cada `group_id` para obter o mais próximo.
  Future<List<Map<String, dynamic>>> fetchNextEvents(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return [];
    final rows = await _client
        .from(_eventsTable)
        .select('id,group_id,scheduled_at')
        .inFilter('group_id', groupIds)
        .eq('status', 'scheduled')
        .gt('scheduled_at', DateTime.now().toIso8601String())
        .order('scheduled_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// GROUP-02B.1: 3 consultas, sem embed, sem RPC - mesmo padrão de
  /// `FollowerRemoteDatasource` (`group_members.user_id`/`profiles.id`
  /// referenciam `auth.users` independentemente; não há FK direta entre
  /// `group_members` e `profiles` que o PostgREST possa usar num embed).
  Future<Map<String, dynamic>> fetchGroupById(String id) {
    return _client
        .from(_groupsTable)
        .select('id,name,description,photo_url,invite_code,$_visibilityColumns')
        .eq('id', id)
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchMembers(String groupId) async {
    final rows = await _client
        .from(_membersTable)
        .select('id,user_id,role')
        .eq('group_id', groupId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Mesmo método/assinatura de `FollowerRemoteDatasource.fetchProfilesByIds`.
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_profilesTable)
        .select()
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// FASE SOCIAL 2 - ids de grupo onde AMBOS os usuários são membros. 2
  /// consultas (ids de grupo de [currentUserId], depois quais delas
  /// também têm [otherUserId]) - a policy `group_members_select_members`
  /// permite as duas por simetria de "quem consulta é membro do grupo
  /// da linha" (ver AUDITORIA — FASE SOCIAL 2 §8).
  Future<List<String>> fetchCommonGroupIds(
    String currentUserId,
    String otherUserId,
  ) async {
    final myRows = await _client
        .from(_membersTable)
        .select('group_id')
        .eq('user_id', currentUserId);
    final myGroupIds = List<Map<String, dynamic>>.from(
      myRows,
    ).map((row) => row['group_id'] as String).toList();
    if (myGroupIds.isEmpty) return [];

    final commonRows = await _client
        .from(_membersTable)
        .select('group_id')
        .eq('user_id', otherUserId)
        .inFilter('group_id', myGroupIds);
    return List<Map<String, dynamic>>.from(
      commonRows,
    ).map((row) => row['group_id'] as String).toList();
  }

  /// FASE SOCIAL 2 - nome/foto dos grupos em [groupIds], só os campos
  /// que a seção "Grupos em comum" do Perfil público exibe.
  Future<List<Map<String, dynamic>>> fetchGroupsByIds(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return [];
    final rows = await _client
        .from(_groupsTable)
        .select('id,name,photo_url,invite_code,$_visibilityColumns')
        .inFilter('id', groupIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// FASE SOCIAL 3 - ids de grupo dos quais [userId] já é membro, usado
  /// para MARCAR (não excluir) os resultados de `search`/`listFeatured` -
  /// um grupo público do qual o usuário já participa continua aparecendo
  /// normalmente, só troca "Entrar" por "Você participa" na UI (decisão
  /// de produto explícita: não esconder grupos relevantes da busca).
  Future<List<String>> fetchMyGroupIds(String userId) async {
    final rows = await _client
        .from(_membersTable)
        .select('group_id')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => row['group_id'] as String).toList();
  }

  /// FASE SOCIAL 3 - busca de grupos `public` por nome (Pesquisa/
  /// Explorar). `visibility = 'public'` explícito além da RLS (defesa
  /// em profundidade, mesmo padrão já usado em
  /// `FollowerRemoteDatasource.searchProfiles`).
  Future<List<Map<String, dynamic>>> searchGroups(
    String query, {
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;
    final rows = await _client
        .from(_groupsTable)
        .select('id,name,description,photo_url,invite_code,$_visibilityColumns')
        .eq('visibility', 'public')
        .ilike('name', '%$query%')
        .order('name')
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// FASE SOCIAL 3 - "Grupos em destaque": só `public`, ordenado por
  /// `member_count` e depois `last_activity_at` (que `create_event()`
  /// já mantém a cada novo rolê criado no grupo, confirmado em
  /// `20260731092000_create_events_and_attendances.sql`) - nenhum
  /// algoritmo, só os 2 sinais que já existem.
  Future<List<Map<String, dynamic>>> listFeaturedGroups({
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;
    final rows = await _client
        .from(_groupsTable)
        .select('id,name,description,photo_url,invite_code,$_visibilityColumns')
        .eq('visibility', 'public')
        .order('member_count', ascending: false)
        .order('last_activity_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// FASE SOCIAL 3 - dados básicos de um grupo `public` para quem ainda
  /// não é membro (`PublicGroupProfilePage`) - sem `fetchMembers`
  /// (`group_members` continua fechado a não-membros).
  Future<Map<String, dynamic>> fetchGroupPublicSummary(String groupId) {
    return _client
        .from(_groupsTable)
        .select('id,name,description,photo_url,invite_code,$_visibilityColumns')
        .eq('id', groupId)
        .single();
  }

  /// FASE SOCIAL 3 - `join_public_group()` é `SECURITY DEFINER`, valida
  /// `visibility = 'public'` no servidor (nunca confia só na UI já ter
  /// checado isso) e insere o chamador como `member`, idempotente
  /// (`on conflict do nothing`), mesmo padrão de `joinByInviteCode`.
  Future<Map<String, dynamic>> joinPublicGroup(String groupId) async {
    final result = await _client.rpc(
      'join_public_group',
      params: {'p_group_id': groupId},
    );
    return result as Map<String, dynamic>;
  }

  /// ONBOARDING-01: `join_group_by_invite_code()` é `SECURITY DEFINER`
  /// (mesma migration do `create_group()`) - resolve o grupo pelo
  /// código e insere o chamador como `member` na mesma transação
  /// (`on conflict do nothing` se já for membro). Mesma disciplina de
  /// nomes exatos do parâmetro (`p_invite_code`).
  Future<Map<String, dynamic>> joinByInviteCode(String inviteCode) async {
    final result = await _client.rpc(
      'join_group_by_invite_code',
      params: {'p_invite_code': inviteCode},
    );
    return result as Map<String, dynamic>;
  }

  /// BLOCO 2: `UPDATE` direto, sem RPC - a policy `groups_update_admin`
  /// (GROUP-01) já restringe isso a admin/owner. Só envia as colunas
  /// que a tela de edição expõe (nunca `owner_id`/`invite_code`, que
  /// têm suas próprias funções dedicadas).
  Future<Map<String, dynamic>> updateGroup({
    required String id,
    required String name,
    String? description,
    String? photoUrl,
  }) {
    return _client
        .from(_groupsTable)
        .update({
          'name': name,
          'description': description,
          'photo_url': photoUrl,
        })
        .eq('id', id)
        .select('id,name,description,photo_url,invite_code')
        .single();
  }

  /// BLOCO 2: `UPDATE` direto por `id` da linha - a policy
  /// `group_members_update_owner` (GROUP-01) já restringe isso ao
  /// owner, e já bloqueia `role = 'owner'` tanto na linha atual quanto
  /// na nova (não precisa de validação própria aqui).
  Future<void> updateMemberRole(String memberId, String role) {
    return _client
        .from(_membersTable)
        .update({'role': role})
        .eq('id', memberId);
  }

  /// BLOCO 2: mesma operação para "sair do grupo" e "remover membro" -
  /// a policy `group_members_delete_self_or_admin` (GROUP-01) decide
  /// pelo `id` da linha quem pode apagar o quê.
  Future<void> removeMember(String memberId) {
    return _client.from(_membersTable).delete().eq('id', memberId);
  }

  /// FASE C.1: `transfer_group_ownership()` é `security definer` (migration
  /// `20260807180000`) - atualiza `groups.owner_id` e o papel das 2 linhas
  /// de `group_members` envolvidas na mesma transação. Mesma disciplina de
  /// nomes exatos de parâmetro já usada em `createGroup`/`joinByInviteCode`.
  Future<void> transferOwnership(String groupId, String newOwnerMemberId) {
    return _client.rpc(
      'transfer_group_ownership',
      params: {
        'p_group_id': groupId,
        'p_new_owner_member_id': newOwnerMemberId,
      },
    );
  }

  /// FASE C.1: `DELETE` direto, sem RPC - a policy `groups_delete_owner`
  /// (GROUP-01, já existente) já restringe isso ao owner.
  Future<void> deleteGroup(String id) {
    return _client.from(_groupsTable).delete().eq('id', id);
  }
}
