/// Validadores de formulário compartilhados entre Login, Cadastro e
/// Recuperação de Senha (DV-01).
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
