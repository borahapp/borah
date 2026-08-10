import 'event_summary.dart';

/// Entidade de Grupo (GROUP-02A) — só os campos necessarios nesta sprint
/// (criacao). `ownerId`/`createdAt`/`updatedAt`/`lastActivityAt` existem
/// na tabela (GROUP-01) mas nao sao usados por nenhuma tela ainda -
/// ficam para quando a tela de Detalhe (GROUP-02B) precisar deles.
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.photoUrl,
    required this.inviteCode,
    this.visibility = 'private',
    this.memberCount,
    this.nextEvent,
  });

  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String inviteCode;

  /// FASE SOCIAL 3 - `groups.visibility` (`'private'`/`'public'`,
  /// `text + check` - mesma convenção de `GroupMember.role`, sem enum
  /// Dart). Default `'private'` aqui só evita quebrar os ~15 call sites
  /// de teste (fora do escopo desta fase) que já constroem `Group` sem
  /// esse campo - toda leitura real do banco sempre popula o valor
  /// verdadeiro da coluna, nunca depende deste default.
  final String visibility;

  bool get isPublic => visibility == 'public';

  /// Contagem de integrantes. Antes da FASE SOCIAL 3, só vinha
  /// (`memberCount`) via embed de `listMine()` - agora também vem da
  /// coluna denormalizada `groups.member_count` em `search`/
  /// `listFeatured`/`getPublicSummary` (necessário porque um não-membro
  /// de um grupo `public` não pode consultar `group_members`
  /// diretamente - RLS continua fechada). Continua `null` nos métodos
  /// que não precisam desse dado (`update`/`joinByInviteCode`).
  final int? memberCount;

  /// Próximo rolê agendado do grupo (Sprint 3, `RC03_DESIGN_GAP.md
  /// §1.3`), para a prévia do `GroupCard`. Populado apenas por
  /// `listMine()`; `null` quando não há rolê futuro agendado, ou quando
  /// vem de um método que não busca esse dado.
  final EventSummary? nextEvent;
}
