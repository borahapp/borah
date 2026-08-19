import 'google_place_result.dart';

/// Erro traduzido pela camada de dados (mesmo padrão do DV-03 em diante) -
/// [message] já é a mensagem amigável final (nunca o corpo/headers/status
/// bruto da resposta HTTP) - ver `GooglePlacesRepositoryImpl._guard`.
class GooglePlacesRepositoryException implements Exception {
  const GooglePlacesRepositoryException(this.message);

  final String message;
}

/// Contrato do domínio para busca de restaurantes reais (F12) - Google
/// Places API (New), Text Search apenas nesta fase (Place Details/Nearby/
/// Photos/Maps ficam fora, sem necessidade demonstrada pelo fluxo de
/// cadastro). Nunca referencia `Restaurant` (DV-03) - a composição entre
/// os dois mundos acontece em `GooglePlaceSelectionController`, não aqui.
abstract interface class GooglePlacesRepository {
  Future<List<GooglePlaceResult>> searchText(String query);
}
