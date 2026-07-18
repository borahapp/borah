/// Validador da nota de avaliação (DV-04 §9: `rating numeric(2,1)`, 1 a 5) -
/// compartilhado entre Criação e Edição para evitar duplicação (mesmo
/// padrão dos validadores extraídos no DV-01/DV-02).
String? validateRating(String? value) {
  final rating = double.tryParse(value ?? '');
  if (rating == null || rating < 1 || rating > 5) {
    return 'Informe uma nota entre 1 e 5.';
  }
  return null;
}
