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

/// Promovido de `features/reviews/presentation/validators/
/// review_validators.dart` para `core/` quando `event_reviews` (BLOCO 4)
/// passou a precisar da mesma regra (nota `numeric(2,1)`, 1 a 5) - mesmo
/// motivo de promoção dos três validadores acima.
String? validateRating(String? value) {
  final rating = double.tryParse(value ?? '');
  if (rating == null || rating < 1 || rating > 5) {
    return 'Informe uma nota entre 1 e 5.';
  }
  return null;
}
