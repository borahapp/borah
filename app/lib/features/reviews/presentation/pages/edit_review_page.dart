import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/review_detail_controller.dart';
import '../states/review_detail_status.dart';
import '../validators/review_validators.dart';
import '../widgets/review_detail_error_listener.dart';

/// Tela de Edição de avaliação (DV-04). Reaproveita o estado já carregado
/// pelo `ReviewDetailController` (mesmo padrão do `EditProfilePage` do
/// DV-02) — não recarrega a avaliação, pois se chega aqui a partir da
/// tela de Detalhes, que já a carregou.
class EditReviewPage extends ConsumerStatefulWidget {
  const EditReviewPage({super.key, required this.reviewId});

  final String reviewId;

  @override
  ConsumerState<EditReviewPage> createState() => _EditReviewPageState();
}

class _EditReviewPageState extends ConsumerState<EditReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _ratingController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(ReviewDetailStatus status) {
    if (_prefilled) return;
    if (status is ReviewDetailLoaded) {
      _ratingController.text = status.review.rating.toStringAsFixed(1);
      _commentController.text = status.review.comment ?? '';
      _prefilled = true;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(reviewDetailControllerProvider.notifier)
        .update(
          widget.reviewId,
          rating: double.parse(_ratingController.text),
          comment: _commentController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(reviewDetailControllerProvider);
    _prefillIfNeeded(status);
    final isSaving = status is ReviewDetailSaving;

    listenForReviewDetailErrors(ref, context);
    ref.listen<ReviewDetailStatus>(reviewDetailControllerProvider, (
      previous,
      next,
    ) {
      if (next is ReviewDetailSaveSuccess) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Editar avaliação'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _ratingController,
                  label: 'Nota (1 a 5)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: validateRating,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _commentController,
                  label: 'Comentário (opcional)',
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Salvar',
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
}
