/// Icon Size Tokens — escala oficial já especificada em
/// `docs/FASE 3 - UX_UI/UI-05_ICONOGRAPHY.md §6`, nunca implementada como
/// token Dart (achado do `RC03_UI_AUDIT.md §6`: ~9 arquivos com tamanho
/// de ícone hardcoded, valores 14/16/18/36/48/64px espalhados sem token
/// comum).
///
/// Esta rodada (Sprint 1) só cria o token — retrofit nas telas com
/// tamanho hardcoded fica para a sprint que já toca cada tela
/// (majoritariamente Sprint 9/Polimento), conforme
/// `RC03_IMPLEMENTATION_PLAN.md`.
abstract final class AppIconSize {
  static const xs = 16.0;
  static const sm = 20.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const xl = 48.0;
}
