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

  /// FASE SOCIAL 2 §11 (AUDITORIA) - campos explícitos em vez de
  /// `.select()` (equivalente a `select *`): `profiles` não tem nenhuma
  /// coluna sensível hoje, mas listar os campos aqui evita que um campo
  /// privado futuro vaze automaticamente por este call site.
  static const _columns =
      'id,full_name,username,bio,avatar_url,city,state,'
      'followers_count,following_count,created_at,updated_at';

  Future<Map<String, dynamic>> fetchProfile(String userId) {
    return _client.from(_table).select(_columns).eq('id', userId).single();
  }

  Future<List<Map<String, dynamic>>> listAll({
    String? query,
    required int page,
    required int limit,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit;

    var builder = _client.from(_table).select(_columns);
    if (query != null && query.isNotEmpty) {
      builder = builder.ilike('full_name', '%$query%');
    }

    final rows = await builder
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> patch,
  ) {
    return _client
        .from(_table)
        .update(patch)
        .eq('id', userId)
        .select(_columns)
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
