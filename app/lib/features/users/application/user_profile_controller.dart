import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/app_analytics.dart';
import '../data/user_profile_repository_impl.dart';
import '../domain/user_profile_repository.dart';
import '../presentation/states/user_profile_status.dart';

/// Camada de aplicação: fluxo simples UserProfileRepository -> Controller,
/// sem use cases intermediários (mesmo padrão do DV-01).
class UserProfileController extends Notifier<UserProfileStatus> {
  @override
  UserProfileStatus build() => const ProfileInitial();

  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  Future<void> loadProfile(String userId) async {
    state = const ProfileLoading();
    try {
      final profile = await _repository.getProfile(userId);
      state = ProfileLoaded(profile);
    } on UserProfileRepositoryException catch (e) {
      state = ProfileError(e.message);
    } catch (_) {
      state = const ProfileError('Não foi possível carregar o perfil.');
    }
  }

  Future<void> updateProfile(
    String userId, {
    String? fullName,
    String? bio,
    String? city,
    String? stateProvince,
  }) async {
    final previous = state;
    if (previous is ProfileLoaded) {
      state = ProfileUpdating(previous.profile);
    }
    try {
      final updated = await _repository.updateProfile(
        userId,
        fullName: fullName,
        bio: bio,
        city: city,
        stateProvince: stateProvince,
      );
      state = ProfileUpdateSuccess(updated);
    } on UserProfileRepositoryException catch (e) {
      state = ProfileError(e.message);
    } catch (_) {
      state = const ProfileError('Não foi possível atualizar o perfil.');
    }
  }

  Future<void> updateAvatar(
    String userId, {
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final previous = state;
    if (previous is ProfileLoaded) {
      state = ProfileUpdating(previous.profile);
    }
    try {
      final updated = await _repository.updateAvatar(
        userId,
        bytes: bytes,
        fileExtension: fileExtension,
      );
      unawaited(AppAnalytics.trackPhotoUploaded(type: 'avatar', success: true));
      state = ProfileUpdateSuccess(updated);
    } on UserProfileRepositoryException catch (e) {
      unawaited(
        AppAnalytics.trackPhotoUploaded(type: 'avatar', success: false),
      );
      state = ProfileError(e.message);
    } catch (_) {
      unawaited(
        AppAnalytics.trackPhotoUploaded(type: 'avatar', success: false),
      );
      state = const ProfileError('Não foi possível atualizar a foto.');
    }
  }

  Future<String?> avatarDisplayUrl(String? avatarPath) {
    return _repository.getAvatarDisplayUrl(avatarPath);
  }
}

final userProfileControllerProvider =
    NotifierProvider<UserProfileController, UserProfileStatus>(
      UserProfileController.new,
    );
