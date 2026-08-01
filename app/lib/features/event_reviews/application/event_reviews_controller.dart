import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_review_repository_impl.dart';
import '../domain/event_review_repository.dart';
import '../presentation/states/event_reviews_status.dart';

/// Carrega as avaliações coletivas de um rolê - seção própria dentro de
/// `EventDetailPage` (BLOCO 4), controller independente de
/// `EventDetailController` (mesmo padrão de `FavoriteToggleController`
/// coexistir com `RestaurantDetailController` na mesma tela).
class EventReviewsController extends Notifier<EventReviewsStatus> {
  @override
  EventReviewsStatus build() => const EventReviewsInitial();

  EventReviewRepository get _repository => ref.read(eventReviewRepositoryProvider);

  Future<void> load(String eventId) async {
    state = const EventReviewsLoading();
    try {
      final reviews = await _repository.listByEvent(eventId);
      // Mesmo padrão de `UserReviewsController`: estado `Empty` dedicado
      // (não só `Loaded` com lista vazia) - permite à UI diferenciar
      // "ainda carregando" de "carregado, mas sem nenhuma avaliação".
      state = reviews.isEmpty
          ? const EventReviewsEmpty()
          : EventReviewsLoaded(reviews);
    } on EventReviewRepositoryException catch (e) {
      state = EventReviewsError(e.message);
    } catch (_) {
      state = const EventReviewsError('Não foi possível carregar as avaliações.');
    }
  }
}

final eventReviewsControllerProvider =
    NotifierProvider<EventReviewsController, EventReviewsStatus>(
      EventReviewsController.new,
    );
