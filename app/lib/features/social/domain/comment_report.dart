/// Entidade de denúncia de comentário (DV-07 §9 `comment_reports`), lida
/// pelo módulo de Administração (DV-08 - Moderação de Denúncias). O DV-07
/// só escrevia nessa tabela (visão do próprio denunciante); o DV-08 lê
/// todas as denúncias.
class CommentReport {
  const CommentReport({
    required this.id,
    required this.commentId,
    required this.reportedBy,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String commentId;
  final String reportedBy;
  final String reason;
  final DateTime createdAt;
}
