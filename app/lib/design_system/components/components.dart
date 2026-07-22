/// Barrel file da biblioteca de componentes oficial do BORAH (UI-02).
///
/// `AppPrimaryButton` e `AppTextField` (os dois componentes-base já
/// existentes desde antes do UI-02) continuam em `core/widgets/` — não
/// foram duplicados aqui para não exigir alterar as telas que já os
/// importam de lá (fora do escopo desta rodada). São, ainda assim,
/// parte oficial da biblioteca (ver UI-06_COMPONENT_LIBRARY.md).
library;

export 'avatars/user_avatar.dart';
export 'badges/app_badge.dart';
export 'bottom_sheets/app_bottom_sheet.dart';
export 'buttons/app_fab.dart';
export 'buttons/app_icon_button.dart';
export 'buttons/app_outlined_button.dart';
export 'buttons/app_secondary_button.dart';
export 'buttons/app_text_button.dart';
export 'cards/app_card.dart';
export 'cards/ranking_card.dart';
export 'cards/restaurant_card.dart';
export 'cards/review_card.dart';
export 'dialogs/app_dialog.dart';
export 'dialogs/confirmation_dialog.dart';
export 'feedback/app_chip.dart';
export 'feedback/empty_state.dart';
export 'feedback/loading_indicator.dart';
export 'feedback/score_bubble.dart';
export 'feedback/skeleton_loader.dart';
export 'inputs/app_password_field.dart';
export 'inputs/app_search_field.dart';
export 'navigation/app_bottom_navigation.dart';
export 'navigation/app_top_bar.dart';
export 'navigation/section_header.dart';
