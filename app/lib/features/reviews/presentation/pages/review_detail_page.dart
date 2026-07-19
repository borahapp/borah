import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/image_picker_service.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/review_detail_controller.dart';
import '../states/review_detail_status.dart';
import '../widgets/review_detail_error_listener.dart';

/// Regras do DV-04 §11: máximo 5 fotos, formatos JPG/PNG/WEBP, até 10 MB
/// cada (mesmos limites de tamanho/formato do DV-03, reaproveitados aqui).
const _maxPhotoBytes = 10 * 1024 * 1024;
const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

/// Tela de Detalhes de uma avaliação (DV-04). Curtir, editar, excluir
/// (lógico) e anexar fotos - comentários e compartilhamento (DV-07) têm
/// tela/ação próprias, acessadas a partir daqui.
class ReviewDetailPage extends ConsumerStatefulWidget {
  const ReviewDetailPage({super.key, required this.reviewId});

  final String reviewId;

  @override
  ConsumerState<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends ConsumerState<ReviewDetailPage> {
  final _imagePickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      ref
          .read(reviewDetailControllerProvider.notifier)
          .load(widget.reviewId, currentUserId: userId);
    });
  }

  Future<void> _addPhoto() async {
    try {
      final picked = await _imagePickerService.pickAndValidate(
        maxBytes: _maxPhotoBytes,
        allowedExtensions: _allowedExtensions,
      );
      if (picked == null) return;
      await ref
          .read(reviewDetailControllerProvider.notifier)
          .addPhoto(
            widget.reviewId,
            bytes: picked.bytes,
            fileExtension: picked.extension,
          );
    } on ImageValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _toggleLike() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref
        .read(reviewDetailControllerProvider.notifier)
        .toggleLike(widget.reviewId, userId);
  }

  void _delete() {
    ref.read(reviewDetailControllerProvider.notifier).delete(widget.reviewId);
  }

  /// Compartilhamento nativo de texto simples (DV-07 decisão 6) - sem
  /// Deep Link nesta versão.
  void _share(double rating) {
    Share.share(
      'Confira esta avaliação no BORAH: nota ${rating.toStringAsFixed(1)}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(reviewDetailControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    listenForReviewDetailErrors(ref, context);
    ref.listen<ReviewDetailStatus>(reviewDetailControllerProvider, (
      previous,
      next,
    ) {
      if (next is ReviewDetailDeleted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Avaliação')),
      body: switch (status) {
        ReviewDetailInitial() ||
        ReviewDetailLoading() ||
        ReviewDetailSaving() ||
        ReviewDetailDeleted() => const Center(
          child: CircularProgressIndicator(),
        ),
        ReviewDetailError(:final message) => Center(child: Text(message)),
        ReviewDetailLoaded(
          :final review,
          :final photoUrls,
          :final likedByCurrentUser,
        ) ||
        ReviewDetailSaveSuccess(
          :final review,
          :final photoUrls,
          :final likedByCurrentUser,
        ) => _DetailView(
          rating: review.rating,
          comment: review.comment,
          likesCount: review.likesCount,
          photoUrls: photoUrls,
          likedByCurrentUser: likedByCurrentUser,
          canManage: review.userId == currentUserId,
          canAddMorePhotos: photoUrls.length < 5,
          onToggleLike: _toggleLike,
          onAddPhoto: _addPhoto,
          onEdit: () => context.push('/reviews/${widget.reviewId}/edit'),
          onDelete: _delete,
          onShare: () => _share(review.rating),
          onViewComments: () =>
              context.push('/reviews/${widget.reviewId}/comments'),
        ),
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.rating,
    required this.comment,
    required this.likesCount,
    required this.photoUrls,
    required this.likedByCurrentUser,
    required this.canManage,
    required this.canAddMorePhotos,
    required this.onToggleLike,
    required this.onAddPhoto,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.onViewComments,
  });

  final double rating;
  final String? comment;
  final int likesCount;
  final List<String> photoUrls;
  final bool likedByCurrentUser;
  final bool canManage;
  final bool canAddMorePhotos;
  final VoidCallback onToggleLike;
  final VoidCallback onAddPhoto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onViewComments;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (comment != null && comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  likedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: onToggleLike,
              ),
              Text('$likesCount'),
              const Spacer(),
              IconButton(icon: const Icon(Icons.share), onPressed: onShare),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onViewComments,
            child: const Text('Ver comentários'),
          ),
          if (photoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoUrls[index],
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          if (canAddMorePhotos) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAddPhoto,
              child: const Text('Adicionar foto'),
            ),
          ],
          if (canManage) ...[
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
            const SizedBox(height: 8),
            TextButton(onPressed: onDelete, child: const Text('Excluir')),
          ],
        ],
      ),
    );
  }
}
