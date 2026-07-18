import 'dart:typed_data';

import 'user_profile.dart';

/// Erro traduzido pela camada de dados — nenhuma camada acima de `data/`
/// conhece exceções do Supabase (mesmo padrão do DV-01).
class UserProfileRepositoryException implements Exception {
  const UserProfileRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio, independente de Flutter e Supabase (AR-02).
abstract interface class UserProfileRepository {
  Future<UserProfile> getProfile(String userId);

  Future<UserProfile> updateProfile(
    String userId, {
    String? fullName,
    String? bio,
    String? city,
    String? stateProvince,
  });

  /// Faz upload da imagem, atualiza avatar_url e retorna o perfil atualizado.
  Future<UserProfile> updateAvatar(
    String userId, {
    required Uint8List bytes,
    required String fileExtension,
  });

  /// O bucket `avatars` é privado (AR-08 §9) — gera uma URL assinada
  /// temporária para exibição, em vez de expor uma URL pública permanente.
  Future<String?> getAvatarDisplayUrl(String? avatarPath);
}
