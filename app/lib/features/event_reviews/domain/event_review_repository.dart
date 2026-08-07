import 'dart:typed_data';

import 'event_review.dart';

/// Erro traduzido pela camada de dados - mesmo padrão de
/// `EventRepositoryException`/`GroupRepositoryException` (nenhuma
/// classe base comum entre features).
class EventReviewRepositoryException implements Exception {
  const EventReviewRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio, independente de Flutter e Supabase (AR-02).
/// A elegibilidade para `submit`/`update` é decidida pela RLS
/// (`can_review_event()`, migration do BLOCO 4) - esta interface não
/// precisa de um método próprio para checar isso; a UI só evita mostrar
/// a ação usando `Event.hasHappened`/`EventAttendance.isConfirmed`, já
/// disponíveis via `EventRepository.getById`.
abstract interface class EventReviewRepository {
  /// Avaliações de um rolê, com o perfil de cada autor.
  Future<List<EventReview>> listByEvent(String eventId);

  /// [userId] é explícito (não lido de dentro do repositório) - mesmo
  /// padrão de `ReviewRepository.create` (DV-04): o domínio não conhece
  /// Riverpod/`currentUserIdProvider` (AR-02), então quem chama
  /// (o controller) resolve o usuário atual e passa aqui. Sem RPC, a
  /// RLS exige `auth.uid() = user_id` no `INSERT`, então o valor tem
  /// que vir no payload.
  Future<EventReview> submit({
    required String eventId,
    required String userId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  });

  /// Edita a própria avaliação já enviada. [reviewId] é o `id` da linha
  /// de `event_reviews` do usuário autenticado - a RLS
  /// (`event_reviews_update_own`) garante que só a própria linha pode
  /// ser alterada.
  Future<EventReview> update({
    required String reviewId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  });

  /// Anexa (ou substitui, se [previousPath] for informado) a única foto
  /// permitida por avaliação coletiva (RC-03 FASE A2). [previousPath]
  /// vem de `EventReview.photoPath` (a própria tela já o tem, sem
  /// consulta nova) - quando informado, o arquivo antigo é removido
  /// depois do novo upload ter sucesso (`AppStorage.replace`).
  Future<EventReview> attachPhoto({
    required String reviewId,
    required Uint8List bytes,
    required String fileExtension,
    String? previousPath,
  });

  /// Remove a foto já anexada, sem enviar uma nova. [photoPath] vem de
  /// `EventReview.photoPath` (já disponível na tela).
  Future<EventReview> removePhoto({
    required String reviewId,
    required String photoPath,
  });

  /// Resolve a URL assinada de um [photoPath] já conhecido - exposto no
  /// domínio para reuso futuro (ex.: uma tela que só tem o caminho
  /// salvo, sem ter carregado a avaliação inteira). `listByEvent`/
  /// `submit`/`update`/`attachPhoto` já devolvem `EventReview.photoUrl`
  /// resolvido, então este método não precisa ser chamado à parte no
  /// fluxo normal da tela de avaliação.
  Future<String> getPhotoUrl(String photoPath);
}
