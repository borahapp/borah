import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/supabase_client_provider.dart';
import 'feedback_model.dart';
import 'feedback_repository.dart';
import 'feedback_service.dart';
import 'supabase_feedback_repository.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseFeedbackRepository(client);
});

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(ref.watch(feedbackRepositoryProvider));
});

/// Estado do envio de feedback (mesmo padrão sealed-class usado em todas
/// as features do app, ex. `AuthStatus`).
sealed class FeedbackStatus {
  const FeedbackStatus();
}

final class FeedbackInitial extends FeedbackStatus {
  const FeedbackInitial();
}

final class FeedbackSubmitting extends FeedbackStatus {
  const FeedbackSubmitting();
}

final class FeedbackSubmitSuccess extends FeedbackStatus {
  const FeedbackSubmitSuccess(this.feedback);

  final FeedbackModel feedback;
}

final class FeedbackSubmitError extends FeedbackStatus {
  const FeedbackSubmitError(this.message);

  final String message;
}

/// Ao contrário de `FeatureFlagsController` (RC-03D, cujo serviço nunca
/// lança), aqui o [FeedbackService] propaga a falha de propósito (ver
/// `feedback_service.dart`) — é esta controller quem a captura e traduz
/// para [FeedbackSubmitError], mesmo padrão já usado em `AuthController`.
class FeedbackController extends Notifier<FeedbackStatus> {
  @override
  FeedbackStatus build() => const FeedbackInitial();

  FeedbackService get _service => ref.read(feedbackServiceProvider);

  Future<void> submit({
    required String userId,
    required String message,
    String? screenContext,
  }) async {
    state = const FeedbackSubmitting();
    try {
      final feedback = await _service.submit(
        userId: userId,
        message: message,
        screenContext: screenContext,
      );
      state = FeedbackSubmitSuccess(feedback);
    } on FeedbackRepositoryException catch (e) {
      state = FeedbackSubmitError(e.message);
    } catch (_) {
      state = const FeedbackSubmitError(
        'Não foi possível enviar seu feedback. Tente novamente.',
      );
    }
  }

  /// Volta ao estado inicial — chamado sempre que o diálogo de feedback
  /// é reaberto, para nunca reaproveitar um estado de sucesso/erro de um
  /// envio anterior.
  void reset() => state = const FeedbackInitial();
}

final feedbackControllerProvider =
    NotifierProvider<FeedbackController, FeedbackStatus>(
      FeedbackController.new,
    );
