import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula as chamadas ao Supabase Database (tabela `profiles`) e ao
/// Supabase Storage (bucket `avatars`) - DV-02 §14.
class UserRemoteDatasource {
  UserRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const _table = 'profiles';
  static const _avatarsBucket = 'avatars';
  static const _signedUrlExpirySeconds = 3600;

  Future<Map<String, dynamic>> fetchProfile(String userId) {
    return _client.from(_table).select().eq('id', userId).single();
  }

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> patch,
  ) {
    return _client
        .from(_table)
        .update(patch)
        .eq('id', userId)
        .select()
        .single();
  }

  Future<String> uploadAvatar(
    String userId,
    Uint8List bytes,
    String fileExtension,
  ) async {
    final path = '$userId/avatar.$fileExtension';
    await _client.storage
        .from(_avatarsBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  Future<String?> createSignedAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return Future.value(null);
    return _client.storage
        .from(_avatarsBucket)
        .createSignedUrl(path, _signedUrlExpirySeconds);
  }
}
