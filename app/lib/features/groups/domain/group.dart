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
    this.memberCount,
    this.nextEvent,
  });

  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String inviteCode;

  /// Contagem de integrantes (Sprint 3, F46 - `GroupCard`). Populado
  /// apenas por `GroupRepository.listMine()`, via embed do PostgREST
  /// (`group_members(count)`, sem migration) - `null` em `create`/
  /// `update`/`getById`/`joinByInviteCode`, que não renderizam
  /// `GroupCard` e não precisam desse dado.
  final int? memberCount;

  /// Próximo rolê agendado do grupo (Sprint 3, `RC03_DESIGN_GAP.md
  /// §1.3`), para a prévia do `GroupCard`. Populado apenas por
  /// `listMine()`; `null` quando não há rolê futuro agendado, ou quando
  /// vem de um método que não busca esse dado.
  final EventSummary? nextEvent;
}
