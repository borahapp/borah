import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/submit_event_review_controller.dart';
import '../../domain/event_review.dart';
import '../states/submit_event_review_status.dart';

/// Tela de avaliação coletiva (BLOCO 4) - mesmo padrão de
/// `CreateReviewPage` (5 campos de nota como `AppTextField` numérico +
/// `validateRating`, em vez de um seletor de estrelas próprio - nenhuma
/// tela do projeto usa um widget de estrelas, não introduzir um agora).
/// Serve tanto para enviar quanto para editar - ver
/// `SubmitEventReviewController.save`.
class SubmitEventReviewPage extends ConsumerStatefulWidget {
  const SubmitEventReviewPage({
    super.key,
    required this.eventId,
    this.existingReview,
  });

  final String eventId;

  /// Presente = modo edição (formulário pré-preenchido, `save` chama
  /// `update`). Ausente = nova avaliação (`save` chama `submit`).
  final EventReview? existingReview;

  @override
  ConsumerState<SubmitEventReviewPage> createState() =>
      _SubmitEventReviewPageState();
}

class _SubmitEventReviewPageState extends ConsumerState<SubmitEventReviewPage> {
  final _formKey = GlobalKey<FormState>();
  late final _foodController = TextEditingController(
    text: widget.existingReview?.foodScore.toString() ?? '',
  );
  late final _serviceController = TextEditingController(
    text: widget.existingReview?.serviceScore.toString() ?? '',
  );
  late final _ambienceController = TextEditingController(
    text: widget.existingReview?.ambienceScore.toString() ?? '',
  );
  late final _costBenefitController = TextEditingController(
    text: widget.existingReview?.costBenefitScore.toString() ?? '',
  );
  late final _overallController = TextEditingController(
    text: widget.existingReview?.overallScore.toString() ?? '',
  );
  late final _commentController = TextEditingController(
    text: widget.existingReview?.comment ?? '',
  );

  @override
  void dispose() {
    _foodController.dispose();
    _serviceController.dispose();
    _ambienceController.dispose();
    _costBenefitController.dispose();
    _overallController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(submitEventReviewControllerProvider.notifier)
        .save(
          eventId: widget.eventId,
          existingReviewId: widget.existingReview?.id,
          foodScore: parseRating(_foodController.text)!,
          serviceScore: parseRating(_serviceController.text)!,
          ambienceScore: parseRating(_ambienceController.text)!,
          costBenefitScore: parseRating(_costBenefitController.text)!,
          overallScore: parseRating(_overallController.text)!,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(submitEventReviewControllerProvider);
    final isSaving = status is SubmitEventReviewSaving;
    final isEditing = widget.existingReview != null;

    ref.listen<SubmitEventReviewStatus>(submitEventReviewControllerProvider, (
      previous,
      next,
    ) {
      if (next is SubmitEventReviewError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is SubmitEventReviewSaveSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação enviada. Obrigado!')),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppTopBar(title: isEditing ? 'Editar avaliação' : 'Avaliar rolê'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Notas (1 a 5)'),
                const SizedBox(height: AppSpacing.sm),
                _ratingField(_foodController, 'Comida'),
                const SizedBox(height: AppSpacing.md),
                _ratingField(_serviceController, 'Atendimento'),
                const SizedBox(height: AppSpacing.md),
                _ratingField(_ambienceController, 'Ambiente'),
                const SizedBox(height: AppSpacing.md),
                _ratingField(_costBenefitController, 'Custo-benefício'),
                const SizedBox(height: AppSpacing.md),
                _ratingField(_overallController, 'Experiência geral'),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _commentController,
                  label: 'Comentário (opcional)',
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: isEditing ? 'Salvar' : 'Enviar avaliação',
                  isLoading: isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratingField(TextEditingController controller, String label) {
    return AppTextField(
      controller: controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validateRating,
    );
  }
}
