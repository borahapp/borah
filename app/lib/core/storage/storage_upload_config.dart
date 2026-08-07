/// Regras de validação de um upload (RC-04B — "tamanho máximo
/// configurável", "tipos MIME permitidos", "extensões permitidas").
/// [StorageService] rejeita qualquer upload que viole estas regras
/// antes de qualquer chamada ao Supabase.
class StorageUploadConfig {
  const StorageUploadConfig({
    required this.maxBytes,
    required this.allowedMimeTypes,
    required this.allowedExtensions,
  });

  final int maxBytes;
  final Set<String> allowedMimeTypes;
  final Set<String> allowedExtensions;

  /// Espelha exatamente o limite já usado por
  /// `change_avatar_page.dart` (5 MB, jpg/jpeg/png/webp) — mesmo
  /// valor, não um novo padrão inventado nesta rodada. Nenhuma tela é
  /// conectada a esta configuração nesta rodada (só infraestrutura);
  /// disponível para quando a RC-04B for conectada a uma tela.
  static const avatar = StorageUploadConfig(
    maxBytes: 5 * 1024 * 1024,
    allowedMimeTypes: {'image/jpeg', 'image/png', 'image/webp'},
    allowedExtensions: {'jpg', 'jpeg', 'png', 'webp'},
  );

  /// Espelha `restaurant_detail_page.dart` (10 MB, mesmos formatos).
  static const restaurantCover = StorageUploadConfig(
    maxBytes: 10 * 1024 * 1024,
    allowedMimeTypes: {'image/jpeg', 'image/png', 'image/webp'},
    allowedExtensions: {'jpg', 'jpeg', 'png', 'webp'},
  );

  /// Espelha `review_detail_page.dart` (10 MB, mesmos formatos).
  static const reviewPhoto = StorageUploadConfig(
    maxBytes: 10 * 1024 * 1024,
    allowedMimeTypes: {'image/jpeg', 'image/png', 'image/webp'},
    allowedExtensions: {'jpg', 'jpeg', 'png', 'webp'},
  );

  /// RC-03 FASE A2 (`BORAH_VISION_v2.0.md`) - mesmos limites de
  /// [reviewPhoto], bucket próprio (`event-review-photos`, privado).
  /// Primeira config desta classe efetivamente conectada a uma tela
  /// (as anteriores eram só infraestrutura, RC-04B).
  static const eventReviewPhoto = StorageUploadConfig(
    maxBytes: 10 * 1024 * 1024,
    allowedMimeTypes: {'image/jpeg', 'image/png', 'image/webp'},
    allowedExtensions: {'jpg', 'jpeg', 'png', 'webp'},
  );
}
