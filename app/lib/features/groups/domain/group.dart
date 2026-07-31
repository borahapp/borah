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
  });

  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String inviteCode;
}
