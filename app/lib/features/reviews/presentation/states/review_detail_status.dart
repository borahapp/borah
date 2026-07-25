import '../../domain/review.dart';

/// Estado de uma avaliação individual (Detalhes/Criação/Edição, DV-04) -
/// separado do `ReviewsStatus` (listagem), assim como o
/// `RestaurantDetailStatus` do DV-03.
sealed class ReviewDetailStatus {
  const ReviewDetailStatus();
}

final class ReviewDetailInitial extends ReviewDetailStatus {
  const ReviewDetailInitial();
}

final class ReviewDetailLoading extends ReviewDetailStatus {
  const ReviewDetailLoading();
}

final class ReviewDetailLoaded extends ReviewDetailStatus {
  const ReviewDetailLoaded(
    this.review, {
    required this.photoUrls,
    required this.likedByCurrentUser,
  });

  final Review review;
  final List<String> photoUrls;
  final bool likedByCurrentUser;
}

final class ReviewDetailSaving extends ReviewDetailStatus {
  const ReviewDetailSaving();
}

/// Upload de foto em andamento (RC-02, Quick Win): diferente de
/// `ReviewDetailSaving`, preserva os dados já carregados para que a tela
/// continue mostrando nota/comentário/fotos em vez de um spinner de tela
/// cheia enquanto a foto sobe.
final class ReviewDetailPhotoUploading extends ReviewDetailStatus {
  const ReviewDetailPhotoUploading(
    this.review, {
    required this.photoUrls,
    required this.likedByCurrentUser,
  });

  final Review review;
  final List<String> photoUrls;
  final bool likedByCurrentUser;
}

final class ReviewDetailSaveSuccess extends ReviewDetailStatus {
  const ReviewDetailSaveSuccess(
    this.review, {
    required this.photoUrls,
    required this.likedByCurrentUser,
  });

  final Review review;
  final List<String> photoUrls;
  final bool likedByCurrentUser;
}

final class ReviewDetailDeleted extends ReviewDetailStatus {
  const ReviewDetailDeleted();
}

final class ReviewDetailError extends ReviewDetailStatus {
  const ReviewDetailError(this.message);

  final String message;
}
