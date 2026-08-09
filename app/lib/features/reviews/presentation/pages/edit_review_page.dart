import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/inputs/app_star_rating.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/review_detail_controller.dart';
import '../states/review_detail_status.dart';
import '../widgets/review_detail_error_listener.dart';

/// Tela de Edição de avaliação (DV-04). Reaproveita o estado já carregado
/// pelo `ReviewDetailController` (mesmo padrão do `EditProfilePage` do
/// DV-02) — não recarrega a avaliação, pois se chega aqui a partir da
/// tela de Detalhes, que já a carregou.
///
/// RC-03 F16 - mesmos 5 critérios de `create_review_page.dart`. Avaliações
/// criadas antes do F16 (`review.hasCriteriaScores == false`) só têm a
/// nota geral pré-preenchida — os 4 critérios novos começam em 0 e o
/// usuário precisa escolhê-los para salvar (nenhuma migração retroativa
/// de dado, decisão já registrada na migration).
class EditReviewPage extends ConsumerStatefulWidget {
  const EditReviewPage({super.key, required this.reviewId});

  final String reviewId;

  @override
  ConsumerState<EditReviewPage> createState() => _EditReviewPageState();
}

class _EditReviewPageState extends ConsumerState<EditReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _prefilled = false;

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

  void _prefillIfNeeded(ReviewDetailStatus status) {
    if (_prefilled) return;
    if (status is ReviewDetailLoaded) {
      final review = status.review;
      _overallScore = review.rating.round();
      _ambienceScore = review.ambienceScore?.round() ?? 0;
      _serviceScore = review.serviceScore?.round() ?? 0;
      _foodScore = review.foodScore?.round() ?? 0;
      _costBenefitScore = review.costBenefitScore?.round() ?? 0;
      _commentController.text = review.comment ?? '';
      _prefilled = true;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(reviewDetailControllerProvider.notifier)
        .update(
          widget.reviewId,
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
