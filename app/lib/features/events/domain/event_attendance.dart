/// Presença de um membro em um rolê (ROLÊ-03). Dados vêm de
/// `event_attendances` (`id`/`status`) + `profiles` (`fullName`/
/// `avatarUrl`), duas tabelas sem FK direta entre si - mesma limitação
/// já documentada em `GroupMember`/`FollowerRemoteDatasource`.
class EventAttendance {
  const EventAttendance({
    required this.id,
    required this.userId,
    required this.status,
    required this.fullName,
    required this.avatarUrl,
  });

  final String id;
  final String userId;

  /// Valor real do banco (`pending`/`confirmed`/`declined` - ROLÊ-01).
  /// Nunca exibido diretamente ao usuário - ver [statusLabel].
  final String status;

  final String? fullName;
  final String? avatarUrl;

  /// Tradução do status para exibição (PT-BR). O banco continua em
  /// inglês - só a apresentação muda (mesmo padrão de
  /// `GroupMember.roleLabel`).
  String get statusLabel => switch (status) {
    'confirmed' => 'Confirmado',
    'declined' => 'Recusado',
    _ => 'Aguardando resposta',
  };

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
}
