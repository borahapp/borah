import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/review_repository_impl.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import '../presentation/states/review_detail_status.dart';

/// Regra do DV-04 §11: no máximo 5 fotos por avaliação.
const maxReviewPhotos = 5;

class ReviewDetailController extends Notifier<ReviewDetailStatus> {
  @override
  ReviewDetailStatus build() => const ReviewDetailInitial();

  ReviewRepository get _repository => ref.read(reviewRepositoryProvider);

  Future<void> load(String id, {required String currentUserId}) async {
    state = const ReviewDetailLoading();
    try {
      final review = await _repository.getById(id);
      final photoUrls = await _repository.listPhotoUrls(id);
      final liked = await _repository.isLikedByUser(id, currentUserId);
      state = ReviewDetailLoaded(
        review,
        photoUrls: photoUrls,
        likedByCurrentUser: liked,
      );
    } on ReviewRepositoryException catch (e) {
      state = ReviewDetailError(e.message);
    } catch (_) {
      state = const ReviewDetailError('Não foi possível carregar a avaliação.');
    }
  }

  Future<void> create({
    required String restaurantId,
    required String userId,
    required double rating,
    String? comment,
  }) async {
    state = const ReviewDetailSaving();
    try {
      final review = await _repository.create(
        restaurantId: restaurantId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
      state = ReviewDetailSaveSuccess(
        review,
        photoUrls: const [],
        likedByCurrentUser: false,
      );
    } on ReviewRepositoryException catch (e) {
      state = ReviewDetailError(e.message);
    } catch (_) {
      state = const ReviewDetailError('Não foi possível publicar a avaliação.');
    }
  }

  Future<void> update(
    String id, {
    required double rating,
    String? comment,
  }) async {
    final previous = _currentDetails();
    state = const ReviewDetailSaving();
    try {
      final review = await _repository.update(
        id,
        rating: rating,
        comment: comment,
      );
      state = ReviewDetailSaveSuccess(
        review,
        photoUrls: previous?.photoUrls ?? const [],
        likedByCurrentUser: previous?.likedByCurrentUser ?? false,
      );
    } on ReviewRepositoryException catch (e) {
      state = ReviewDetailError(e.message);
    } catch (_) {
      state = const ReviewDetailError(
        'Não foi possível atualizar a avaliação.',
      );
    }
  }

  Future<void> delete(String id) async {
    state = const ReviewDetailSaving();
    try {
      await _repository.delete(id);
      state = const ReviewDetailDeleted();
    } on ReviewRepositoryException catch (e) {
      state = ReviewDetailError(e.message);
    } catch (_) {
      state = const ReviewDetailError('Não foi possível excluir a avaliação.');
    }
  }

  Future<void> addPhoto(
    String id, {
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final previous = _currentDetails();
    if (previous != null && previous.photoUrls.length >= maxReviewPhotos) {
      state = ReviewDetailError(
        'Cada avaliação pode ter no máximo $maxReviewPhotos fotos.',
      );
      return;
    }

    state = previous == null
        ? const ReviewDetailSaving()
        : ReviewDetailPhotoUploading(
            previous.review,
            photoUrls: previous.photoUrls,
            likedByCurrentUser: previous.likedByCurrentUser,
          );
    try {
      final review = await _repository.addPhoto(
        id,
        bytes: bytes,
        fileExtension: fileExtension,
      );
      final photoUrls = await _repository.listPhotoUrls(id);
      state = ReviewDetailSaveSuccess(
        review,
        photoUrls: photoUrls,
        likedByCurrentUser: previous?.likedByCurrentUser ?? false,
      );
    } on ReviewRepositoryException catch (e) {
      state = ReviewDetailError(e.message);
    } catch (_) {
      state = const ReviewDetailError('Não foi possível enviar a foto.');
    }
  }

  Future<void> toggleLike(String id, String userId) async {
    final previous = _currentDetails();
    if (previous == null) return;

    try {
      if (previous.likedByCurrentUser) {
        await _repository.unlike(id, userId);
      } else {
        await _repository.like(id, userId);
      }
      final review = await _repository.getById(id);
      state = ReviewDetailSaveSuccess(
        review,
        photoUrls: previous.photoUrls,
        likedByCurrentUser: !previous.likedByCurrentUser,
      );
    } on ReviewRepositoryException catch (e) {
      state = ReviewDetailError(e.message);
    } catch (_) {
      state = const ReviewDetailError('Não foi possível registrar a curtida.');
    }
  }

  /// Dados carregados atuais (avaliação/fotos/curtida), preservados entre
  /// ações que não os alteram (ex.: editar nota não deve descartar as
  /// fotos já carregadas). `null` se nada foi carregado ainda.
  ({Review review, List<String> photoUrls, bool likedByCurrentUser})?
  _currentDetails() {
    final current = state;
    return switch (current) {
      ReviewDetailLoaded(
        :final review,
        :final photoUrls,
        :final likedByCurrentUser,
      ) =>
        (
          review: review,
          photoUrls: photoUrls,
          likedByCurrentUser: likedByCurrentUser,
        ),
      ReviewDetailSaveSuccess(
        :final review,
        :final photoUrls,
        :final likedByCurrentUser,
      ) =>
        (
          review: review,
          photoUrls: photoUrls,
          likedByCurrentUser: likedByCurrentUser,
        ),
      _ => null,
    };
  }
}

final reviewDetailControllerProvider =
    NotifierProvider<ReviewDetailController, ReviewDetailStatus>(
      ReviewDetailController.new,
    );
