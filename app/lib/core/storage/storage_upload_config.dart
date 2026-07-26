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
}
