/// Validadores de formulário compartilhados entre módulos (promovido do
/// DV-01 para `core/` quando o DV-02 passou a precisar dos mesmos).
String? validateEmail(String? value) {
  if (value == null || !value.contains('@')) {
    return 'Informe um e-mail válido.';
  }
  return null;
}

/// Validação de força mínima — aplicável ao cadastro, não ao login
/// (no login basta confirmar que o campo foi preenchido).
String? validatePassword(String? value) {
  if (value == null || value.length < 6) {
    return 'A senha deve ter ao menos 6 caracteres.';
  }
  return null;
}

String? validateRequired(String? value, String fieldLabel) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe $fieldLabel.';
  }
  return null;
}

/// Aceita vírgula ou ponto como separador decimal (QA, BLOCO 9): o
/// teclado numérico decimal (`TextInputType.numberWithOptions(decimal:
/// true)`, usado por todo campo de nota do app) insere vírgula por
/// padrão em locale pt-BR - `double.parse`/`double.tryParse` só aceitam
/// ponto, então uma nota como "4,5" digitada normalmente pelo teclado
/// nativo era rejeitada pela validação. Usado tanto por [validateRating]
/// quanto pelas telas que fazem o parse final após validar.
double? parseRating(String? value) {
  if (value == null) return null;
  return double.tryParse(value.replaceAll(',', '.'));
}

/// Promovido de `features/reviews/presentation/validators/
/// review_validators.dart` para `core/` quando `event_reviews` (BLOCO 4)
/// passou a precisar da mesma regra (nota `numeric(2,1)`, 1 a 5) - mesmo
/// motivo de promoção dos três validadores acima.
String? validateRating(String? value) {
  final rating = parseRating(value);
  if (rating == null || rating < 1 || rating > 5) {
    return 'Informe uma nota entre 1 e 5.';
  }
  return null;
}

final _usernamePattern = RegExp(r'^[a-zA-Z0-9_.]+$');

/// FASE SOCIAL 2 - `profiles.username` é opcional (contas antigas
/// continuam sem username), então um campo vazio é válido; só valida o
/// formato quando algo foi digitado. Mesma regra da CHECK constraint
/// `profiles_username_format` (`add_profiles_username.sql`) - mantidas
/// em sincronia manualmente, mesma decisão já aceita no projeto para
/// `validateRating`/CHECK de `reviews.overall_rating`.
String? validateUsername(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final trimmed = value.trim();
  if (trimmed.length < 3 || trimmed.length > 30) {
    return 'O nome de usuário deve ter entre 3 e 30 caracteres.';
  }
  if (!_usernamePattern.hasMatch(trimmed)) {
    return 'Use apenas letras, números, ponto e underscore.';
  }
  return null;
}
