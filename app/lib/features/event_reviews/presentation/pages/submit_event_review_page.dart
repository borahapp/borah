import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/image_picker_service.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/cards/restaurant_header.dart';
import '../../../../design_system/components/inputs/app_star_rating.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/submit_event_review_controller.dart';
import '../../domain/event_review.dart';
import '../states/submit_event_review_status.dart';

/// RC-03 FASE A2 (`BORAH_VISION_v2.0.md`) - mesmos limites de
/// `StorageUploadConfig.eventReviewPhoto` (servidor), espelhados aqui
/// para validar antes do upload, mesmo padrão de `review_detail_page.dart`.
const _maxPhotoBytes = 10 * 1024 * 1024;
const _allowedPhotoExtensions = {'jpg', 'jpeg', 'png', 'webp'};

/// Tela de avaliação coletiva (RC-03, FASE A1 - `BORAH_VISION_v2.0.md`
/// Capítulo 6: Avaliação é o gesto que converte o rolê vivido em dado
/// permanente do grupo). Substitui o padrão anterior de nota numérica em
/// texto livre por `AppStarRating`; contextualiza a avaliação com o
/// restaurante/data do rolê (Análise de UX aprovada nesta rodada) e
/// mostra progresso de preenchimento sem telas adicionais.
///
/// Ordem dos critérios segue a linha do tempo real da visita (Ambiente
/// ao chegar → Atendimento ao longo da visita → Comida, o evento
/// central → Custo-benefício, síntese → Experiência geral, resumo) - não
/// a ordem alfabética/arbitrária anterior.
///
/// Serve tanto para enviar quanto para editar - ver
/// `SubmitEventReviewController.save`.
class SubmitEventReviewPage extends ConsumerStatefulWidget {
  const SubmitEventReviewPage({
    super.key,
    required this.eventId,
    this.restaurantName,
    this.scheduledAt,
    this.restaurantCoverImage,
    this.existingReview,
  });

  final String eventId;

  /// Contexto do rolê (nome do restaurante/data), vindo de `Event` via
  /// `extra` da rota (`app_router.dart`) - opcional para não quebrar se
  /// algum ponto de navegação futuro não os fornecer; nesse caso o
  /// cabeçalho de contexto simplesmente não aparece.
  final String? restaurantName;
  final DateTime? scheduledAt;
  final String? restaurantCoverImage;

  /// Presente = modo edição (formulário pré-preenchido, `save` chama
  /// `update`). Ausente = nova avaliação (`save` chama `submit`).
  final EventReview? existingReview;

  @override
  ConsumerState<SubmitEventReviewPage> createState() =>
      _SubmitEventReviewPageState();
}

class _SubmitEventReviewPageState extends ConsumerState<SubmitEventReviewPage> {
  final _formKey = GlobalKey<FormState>();

  late int _ambienceScore = widget.existingReview?.ambienceScore.round() ?? 0;
  late int _serviceScore = widget.existingReview?.serviceScore.round() ?? 0;
  late int _foodScore = widget.existingReview?.foodScore.round() ?? 0;
  late int _costBenefitScore =
      widget.existingReview?.costBenefitScore.round() ?? 0;
  late int _overallScore = widget.existingReview?.overallScore.round() ?? 0;

  late final _commentController = TextEditingController(
    text: widget.existingReview?.comment ?? '',
  );

  final _imagePickerService = ImagePickerService();

  /// Bytes de uma foto recém-selecionada, ainda não enviada - `null`
  /// enquanto nenhuma nova foto foi escolhida (a existente, se houver,
  /// continua sendo `widget.existingReview?.photoUrl`, já resolvido
  /// pela navegação, sem consulta nova aqui).
  Uint8List? _pickedPhotoBytes;
  String? _pickedPhotoExtension;

  /// `true` quando o usuário pediu para remover a foto já existente
  /// sem escolher uma nova - só tem efeito se nenhuma foto nova for
  /// selecionada depois (uma foto nova sempre substitui a intenção de
  /// remoção).
  bool _removeExistingPhoto = false;

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

    ref
        .read(submitEventReviewControllerProvider.notifier)
        .save(
          eventId: widget.eventId,
          existingReviewId: widget.existingReview?.id,
          ambienceScore: _ambienceScore.toDouble(),
          serviceScore: _serviceScore.toDouble(),
          foodScore: _foodScore.toDouble(),
          costBenefitScore: _costBenefitScore.toDouble(),
          overallScore: _overallScore.toDouble(),
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          photoBytes: _pickedPhotoBytes,
          photoFileExtension: _pickedPhotoExtension,
          previousPhotoPath: widget.existingReview?.photoPath,
          removePhoto: _removeExistingPhoto,
        );
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _imagePickerService.pickAndValidate(
        maxBytes: _maxPhotoBytes,
        allowedExtensions: _allowedPhotoExtensions,
      );
      if (picked == null) return;
      setState(() {
        _pickedPhotoBytes = picked.bytes;
        _pickedPhotoExtension = picked.extension;
        _removeExistingPhoto = false;
      });
    } on ImageValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      // Falha de plataforma (ex.: permissão de galeria negada) - mesmo
      // tratamento silencioso já usado em `review_detail_page.dart`,
      // não é um erro de dado do usuário.
    }
  }

  void _clearPickedPhoto() {
    setState(() {
      _pickedPhotoBytes = null;
      _pickedPhotoExtension = null;
    });
  }

  void _removePhoto() {
    setState(() => _removeExistingPhoto = true);
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
          SnackBar(
            content: next.photoWarning != null
                ? Text(next.photoWarning!)
                : const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Sua nota já atualizou o ranking do grupo.',
                        ),
                      ),
                    ],
                  ),
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppTopBar(title: isEditing ? 'Editar avaliação' : 'Avaliar rolê'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.restaurantName != null)
                  RestaurantHeader(
                    name: widget.restaurantName!,
                    subtitle: widget.scheduledAt == null
                        ? null
                        : _formatDate(widget.scheduledAt!),
                    photoUrl: widget.restaurantCoverImage,
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgress(context),
                      const SizedBox(height: AppSpacing.lg),
                      AppStarRating(
                        label: 'Ambiente',
                        initialValue: _ambienceScore,
                        onChanged: (value) =>
                            setState(() => _ambienceScore = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStarRating(
                        label: 'Atendimento',
                        initialValue: _serviceScore,
                        onChanged: (value) =>
                            setState(() => _serviceScore = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStarRating(
                        label: 'Comida',
                        initialValue: _foodScore,
                        onChanged: (value) =>
                            setState(() => _foodScore = value),
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
                        caption: 'Sua nota geral para o rolê',
                        initialValue: _overallScore,
                        onChanged: (value) =>
                            setState(() => _overallScore = value),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _commentController,
                        label: 'Comentário (opcional)',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPhotoSection(context),
                      const SizedBox(height: AppSpacing.xl),
                      AppPrimaryButton(
                        label: isEditing ? 'Salvar' : 'Enviar avaliação',
                        isLoading: isSaving,
                        onPressed: _submit,
                      ),
                    ],
                  ),
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

  /// RC-03 FASE A2 - foto opcional, no mesmo formulário (nunca uma
  /// tela separada, `BORAH_VISION_v2.0.md` Capítulo 12). Três estados:
  /// nenhuma foto (botão para adicionar), foto já existente (modo
  /// edição, já resolvida via navegação - sem consulta nova) ou foto
  /// recém-selecionada (ainda não enviada, preview local).
  Widget _buildPhotoSection(BuildContext context) {
    final theme = Theme.of(context);
    final existingPhotoUrl = widget.existingReview?.photoUrl;
    final hasPickedPhoto = _pickedPhotoBytes != null;
    final hasExistingPhoto = existingPhotoUrl != null && !_removeExistingPhoto;

    if (!hasPickedPhoto && !hasExistingPhoto) {
      return AppOutlinedButton(
        label: 'Adicionar foto (opcional)',
        icon: Icons.add_a_photo_outlined,
        onPressed: _pickPhoto,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto (opcional)', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.radiusMd,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: hasPickedPhoto
                    ? Image.memory(_pickedPhotoBytes!, fit: BoxFit.cover)
                    : Image.network(existingPhotoUrl!, fit: BoxFit.cover),
              ),
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: AppIconButton(
                    icon: Icons.close,
                    tooltip: 'Remover foto',
                    color: Colors.white,
                    onPressed: hasPickedPhoto
                        ? _clearPickedPhoto
                        : _removePhoto,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
