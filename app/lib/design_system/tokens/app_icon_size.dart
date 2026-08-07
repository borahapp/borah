/// Icon Size Tokens — escala oficial já especificada em
/// `docs/FASE 3 - UX_UI/UI-05_ICONOGRAPHY.md §6`, nunca implementada como
/// token Dart (achado do `RC03_UI_AUDIT.md §6`: ~9 arquivos com tamanho
/// de ícone hardcoded, valores 14/16/18/36/48/64px espalhados sem token
/// comum).
///
/// Esta rodada só criou o token — retrofit nas ~9 telas com tamanho
/// ainda hardcoded fica para quando cada uma dessas telas for tocada
/// por sua própria fase de trabalho, não uma varredura dedicada.
abstract final class AppIconSize {
  static const xs = 16.0;
  static const sm = 20.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const xl = 48.0;
}
