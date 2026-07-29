/// Entidade de notificação (DV-09 §9). Nomeada `AppNotification` (não
/// `Notification`) para evitar colisão com a classe `Notification` do
/// Flutter - mesma lição do `AuthStatus` (DV-01) sobre `AuthState`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.payload,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
}
