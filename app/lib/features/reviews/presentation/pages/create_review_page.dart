import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/inputs/app_star_rating.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/review_detail_controller.dart';
import '../states/review_detail_status.dart';
import '../widgets/review_detail_error_listener.dart';

/// Tela de Criação de avaliação (DV-04). Uma avaliação por usuário por
/// restaurante (constraint `UNIQUE(user_id, restaurant_id)`).
///
/// RC-03 F16 - substitui o campo numérico cru anterior pelos mesmos 5
/// critérios de estrelas já usados em `submit_event_review_page.dart`
/// (paridade de UX entre avaliação individual e coletiva, achado do
/// `BORAH_NEXT_STEP_ANALYSIS.md §2/§4/§7`) - mesma ordem de critérios
/// (Ambiente → Atendimento → Comida → Custo-benefício → Experiência
/// geral) e mesmo indicador de progresso.
class CreateReviewPage extends ConsumerStatefulWidget {
  const CreateReviewPage({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<CreateReviewPage> createState() => _CreateReviewPageState();
}

class _CreateReviewPageState extends ConsumerState<CreateReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  int _ambienceScore = 0;
  int _serviceScore = 0;
  int _foodScore = 0;
  int _costBenefitScore = 0;
  int _overallScore = 0;

  int get _filledCount => [
    _ambienceScore,
    _serviceScore,
    _foodScore,
    _costBenefitScore,
    _overallScore,
  ].where((score) => score > 0).length;

  @override
  void dispose() {
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
          rating: _overallScore.toDouble(),
          ambienceScore: _ambienceScore.toDouble(),
          serviceScore: _serviceScore.toDouble(),
          foodScore: _foodScore.toDouble(),
          costBenefitScore: _costBenefitScore.toDouble(),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgress(context),
                const SizedBox(height: AppSpacing.lg),
                AppStarRating(
                  label: 'Ambiente',
                  initialValue: _ambienceScore,
                  onChanged: (value) => setState(() => _ambienceScore = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppStarRating(
                  label: 'Atendimento',
                  initialValue: _serviceScore,
                  onChanged: (value) => setState(() => _serviceScore = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppStarRating(
                  label: 'Comida',
                  initialValue: _foodScore,
                  onChanged: (value) => setState(() => _foodScore = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppStarRating(
                  label: 'Custo-benefício',
                  initialValue: _costBenefitScore,
                  onChanged: (value) =>
                      setState(() => _costBenefitScore = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppStarRating(
                  label: 'Experiência geral',
                  caption: 'Sua nota geral para o restaurante',
                  initialValue: _overallScore,
                  onChanged: (value) => setState(() => _overallScore = value),
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

  Widget _buildProgress(BuildContext context) {
    final theme = Theme.of(context);
    final filled = _filledCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$filled de 5 critérios avaliados',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.radiusPill,
          child: LinearProgressIndicator(value: filled / 5),
        ),
      ],
    );
  }
}
