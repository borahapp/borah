import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';
import 'user_remote_datasource.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._datasource);

  final UserRemoteDatasource _datasource;

  @override
  Future<UserProfile> getProfile(String userId) {
    return _guard(() async {
      final row = await _datasource.fetchProfile(userId);
      return _mapRow(row);
    });
  }

  @override
  Future<PagedResult<UserProfile>> listAll({
    String? query,
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listAll(
        query: query,
        page: page,
        limit: limit,
      );

      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      return PagedResult<UserProfile>(
        items: pageRows.map(_mapRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  @override
  Future<UserProfile> updateProfile(
    String userId, {
    String? fullName,
    String? bio,
    String? city,
    String? stateProvince,
  }) {
    return _guard(() async {
      final patch = <String, dynamic>{
        'full_name': ?fullName,
        'bio': ?bio,
        'city': ?city,
        'state': ?stateProvince,
      };
      final row = await _datasource.updateProfile(userId, patch);
      return _mapRow(row);
    });
  }

  @override
  Future<UserProfile> updateAvatar(
    String userId, {
    required Uint8List bytes,
    required String fileExtension,
  }) {
    return _guard(() async {
      final path = await _datasource.uploadAvatar(userId, bytes, fileExtension);
      final row = await _datasource.updateProfile(userId, {'avatar_url': path});
      return _mapRow(row);
    });
  }

  @override
  Future<String?> getAvatarDisplayUrl(String? avatarPath) {
    return _guard(() => _datasource.createSignedAvatarUrl(avatarPath));
  }

  UserProfile _mapRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      fullName: row['full_name'] as String?,
      bio: row['bio'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      city: row['city'] as String?,
      state: row['state'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw UserProfileRepositoryException(e.message);
    } on StorageException catch (e) {
      throw UserProfileRepositoryException(e.message);
    }
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserProfileRepositoryImpl(UserRemoteDatasource(client));
});
