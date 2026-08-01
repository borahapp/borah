/// Entidade de Rolê (ROLÊ-02, campos de restaurante adicionados no
/// ROLÊ-03) - só os campos necessários até agora (criação, lista,
/// detalhe). `organizerId`/`createdAt`/`updatedAt` existem na tabela
/// (ROLÊ-01) mas nenhuma tela usa ainda.
class Event {
  const Event({
    required this.id,
    required this.groupId,
    required this.restaurantId,
    required this.scheduledAt,
    required this.status,
    this.restaurantName,
    this.restaurantCategory,
    this.restaurantCity,
    this.averageRating,
    this.totalReviews = 0,
  });

  final String id;
  final String groupId;
  final String restaurantId;
  final DateTime scheduledAt;

  /// Valor real do banco (`scheduled`/`completed`/`cancelled` - ROLÊ-01).
  final String status;

  /// Dados do restaurante via embed do PostgREST (ROLÊ-03,
  /// `listByGroup`/`getById` - FK real `events.restaurant_id ->
  /// restaurants.id`, mesmo padrão de `FavoriteRemoteDatasource`). Nulos
  /// quando o `Event` vem de `create_event()` (ROLÊ-02), que não faz
  /// join - a tela de criação já conhece o restaurante pela seleção do
  /// próprio usuário, então não precisa desses campos.
  final String? restaurantName;
  final String? restaurantCategory;
  final String? restaurantCity;

  /// Agregado denormalizado de `event_reviews` (BLOCO 4), mantido por
  /// trigger (`recalculate_event_rating`) - nunca calculado no cliente.
  /// `null`/`0` até a primeira avaliação coletiva. Mesmo papel de
  /// `Restaurant.averageRating`/`totalReviews` (DV-03), mas escopado ao
  /// rolê, não ao restaurante - os dois nunca se misturam.
  final double? averageRating;
  final int totalReviews;

  String get statusLabel => switch (status) {
    'cancelled' => 'Cancelado',
    'completed' => 'Realizado',
    _ => 'Agendado',
  };

  /// Usado por `EventsListPage` (BLOCO 3) para separar "Próximos" de
  /// "Realizados" sem nenhuma consulta nova - `status` sozinho não
  /// basta (nada no projeto transiciona `scheduled` -> `completed`
  /// automaticamente ainda), então um rolê `scheduled` cuja data já
  /// passou também conta como já realizado.
  bool get isUpcoming => status == 'scheduled' && scheduledAt.isAfter(DateTime.now());

  /// Usado por `EventDetailPage` (BLOCO 4) para decidir se a avaliação
  /// coletiva já pode ser enviada - espelha exatamente a checagem de
  /// data que `can_review_event()` faz no banco (RLS é quem de fato
  /// impede o envio; isto só evita mostrar um botão que a RLS rejeitaria).
  bool get hasHappened => DateTime.now().isAfter(scheduledAt);
}
