import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_controller.dart';
import '../data/event_review_repository_impl.dart';
import '../domain/event_review_repository.dart';
import '../presentation/states/submit_event_review_status.dart';

class SubmitEventReviewController extends Notifier<SubmitEventReviewStatus> {
  @override
  SubmitEventReviewStatus build() => const SubmitEventReviewInitial();

  EventReviewRepository get _repository =>
      ref.read(eventReviewRepositoryProvider);

  /// [existingReviewId] presente -> edita a avaliação já enviada;
  /// ausente -> envia uma nova. Uma página só (`SubmitEventReviewPage`)
  /// para os dois casos - diferente de Criar/Editar Grupo (páginas
  /// separadas): ali são duas intenções distintas em momentos
  /// diferentes; aqui é a mesma ação ("enviar sua avaliação"), só que a
  /// segunda vez já existe algo para ajustar.
  Future<void> save({
    required String eventId,
    String? existingReviewId,
    required double foodScore,
    required double serviceScore,
    required double ambienceScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
  }) async {
    state = const SubmitEventReviewSaving();
    try {
      final review = existingReviewId == null
          ? await _repository.submit(
              eventId: eventId,
              userId: _requireUserId(),
              foodScore: foodScore,
              serviceScore: serviceScore,
              ambienceScore: ambienceScore,
              costBenefitScore: costBenefitScore,
              overallScore: overallScore,
              comment: comment,
            )
          : await _repository.update(
              reviewId: existingReviewId,
              foodScore: foodScore,
              serviceScore: serviceScore,
              ambienceScore: ambienceScore,
              costBenefitScore: costBenefitScore,
              overallScore: overallScore,
              comment: comment,
            );
      state = SubmitEventReviewSaveSuccess(review);
    } on EventReviewRepositoryException catch (e) {
      state = SubmitEventReviewError(e.message);
    } catch (_) {
      state = const SubmitEventReviewError(
        'Não foi possível salvar sua avaliação.',
      );
    }
  }

  String _requireUserId() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw const EventReviewRepositoryException('Usuário não autenticado.');
    }
    return userId;
  }
}

final submitEventReviewControllerProvider =
    NotifierProvider<SubmitEventReviewController, SubmitEventReviewStatus>(
      SubmitEventReviewController.new,
    );
