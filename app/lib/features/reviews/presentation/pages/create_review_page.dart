import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/review_detail_controller.dart';
import '../states/review_detail_status.dart';
import '../validators/review_validators.dart';
import '../widgets/review_detail_error_listener.dart';

/// Tela de Criação de avaliação (DV-04). Uma avaliação por usuário por
/// restaurante (constraint `UNIQUE(user_id, restaurant_id)`).
class CreateReviewPage extends ConsumerStatefulWidget {
  const CreateReviewPage({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<CreateReviewPage> createState() => _CreateReviewPageState();
}

class _CreateReviewPageState extends ConsumerState<CreateReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _ratingController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    ref
        .read(reviewDetailControllerProvider.notifier)
        .create(
          restaurantId: widget.restaurantId,
          userId: userId,
          rating: double.parse(_ratingController.text),
          comment: _commentController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(reviewDetailControllerProvider);
    final isSaving = status is ReviewDetailSaving;

    listenForReviewDetailErrors(ref, context);
    ref.listen<ReviewDetailStatus>(reviewDetailControllerProvider, (
      previous,
      next,
    ) {
      if (next is ReviewDetailSaveSuccess) {
        context.pushReplacement('/reviews/${next.review.id}');
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Avaliar restaurante'),
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
                  label: 'Publicar avaliação',
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
