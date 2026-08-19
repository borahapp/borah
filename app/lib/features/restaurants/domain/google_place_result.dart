/// Resultado de uma busca na Google Places API (New) - F12. Deliberadamente
/// distinto de `Restaurant` (DV-03): este é o DTO de domínio do lado
/// "Google", nunca misturado com a entidade do BORAH. Só os campos
/// mínimos que o fluxo de cadastro precisa (mesmos do FieldMask usado em
/// `GooglePlacesRemoteDatasource`).
class GooglePlaceResult {
  const GooglePlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.types,
  });

  /// `places.id` - identificador estável do Google, persistido em
  /// `restaurants.google_place_id` para deduplicação.
  final String placeId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  /// `places.types` - usado só para sugerir uma categoria inicial ao
  /// criar o restaurante (heurística simples, ver
  /// `GooglePlaceSelectionController`) - nunca exibido cru na UI.
  final List<String> types;
}
