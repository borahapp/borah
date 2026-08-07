import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/app_analytics.dart';
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
  /// [photoBytes]/[photoFileExtension] presentes -> anexa/substitui a
  /// foto (RC-03 FASE A2) depois da avaliação salva com sucesso.
  /// [removePhoto] -> remove a foto já existente, sem enviar uma nova
  /// (ignorado se [photoBytes] também for informado - uma nova foto
  /// sempre vence). [previousPhotoPath] vem de `EventReview.photoPath`
  /// já carregado pela tela (nunca uma consulta nova aqui).
  ///
  /// A falha no passo de foto nunca derruba o envio da avaliação em
  /// si - as notas já foram salvas com sucesso nesse ponto
  /// (`BORAH_VISION_v2.0.md`, Princípio 3: foto é sempre opcional,
  /// nunca pode bloquear o gesto principal). `photoWarning` carrega o
  /// aviso secundário para a tela mostrar.
  Future<void> save({
    required String eventId,
    String? existingReviewId,
    required double ambienceScore,
    required double serviceScore,
    required double foodScore,
    required double costBenefitScore,
    required double overallScore,
    String? comment,
    Uint8List? photoBytes,
    String? photoFileExtension,
    String? previousPhotoPath,
    bool removePhoto = false,
  }) async {
    state = const SubmitEventReviewSaving();
    try {
      var review = existingReviewId == null
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
      unawaited(
        AppAnalytics.trackEventReviewSubmitted(
          eventId: eventId,
          isEdit: existingReviewId != null,
        ),
      );

      String? photoWarning;
      if (photoBytes != null && photoFileExtension != null) {
        try {
          review = await _repository.attachPhoto(
            reviewId: review.id,
            bytes: photoBytes,
            fileExtension: photoFileExtension,
            previousPath: previousPhotoPath,
          );
          unawaited(
            AppAnalytics.trackPhotoUploaded(
              type: 'event_review',
              success: true,
            ),
          );
        } catch (_) {
          unawaited(
            AppAnalytics.trackPhotoUploaded(
              type: 'event_review',
              success: false,
            ),
          );
          photoWarning = 'Avaliação salva, mas não foi possível enviar a foto.';
        }
      } else if (removePhoto && previousPhotoPath != null) {
        try {
          review = await _repository.removePhoto(
            reviewId: review.id,
            photoPath: previousPhotoPath,
          );
        } catch (_) {
          photoWarning =
              'Avaliação salva, mas não foi possível remover a foto.';
        }
      }

      state = SubmitEventReviewSaveSuccess(review, photoWarning: photoWarning);
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
