/// Image Size Tokens — cobre os casos hoje hardcoded de avatar/thumbnail
/// identificados no `RC03_UI_AUDIT.md §6` (raio de avatar em
/// `change_avatar_page.dart`/`follow_list_page.dart`/`profile_page.dart`
/// variando entre 20/48/64px sem token; tira de fotos em
/// `review_detail_page.dart` com `width`/`height` de 96px hardcoded).
///
/// Valores abaixo são os já observados em uso real (não uma escala nova
/// inventada) — esta rodada (Sprint 1) só cria o token; consolidar as
/// telas existentes para usá-lo é retrofit de outra sprint (majoritariamente
/// Sprint 9/Polimento), conforme `RC03_IMPLEMENTATION_PLAN.md`.
abstract final class AppImageSize {
  /// Raio de avatar em contexto de lista (ex.: linha de seguidor).
  static const avatarSmall = 20.0;

  /// Raio de avatar em contexto intermediário (ex.: `profile_page.dart`).
  static const avatarMedium = 48.0;

  /// Raio de avatar em contexto de destaque (ex.: preview pré-upload em
  /// `change_avatar_page.dart`).
  static const avatarLarge = 64.0;

  /// Lado do thumbnail quadrado de foto (ex.: tira de fotos de avaliação).
  static const thumbnail = 96.0;
}
