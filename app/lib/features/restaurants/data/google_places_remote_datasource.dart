import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/logger/app_logger.dart';

/// Erro de transporte/HTTP da Google Places API (New) - carrega só o
/// `statusCode` (nunca o corpo/headers da resposta, que poderiam conter
/// detalhes internos) para `GooglePlacesRepositoryImpl` traduzir numa
/// mensagem amigável por faixa de código.
class GooglePlacesHttpException implements Exception {
  const GooglePlacesHttpException(this.statusCode);

  final int statusCode;
}

/// Lançado quando não há credencial configurada (`GOOGLE_PLACES_API_KEY`
/// vazio) - mesmo espírito de `AuthRemoteDatasource.signInWithGoogle()`
/// recusar login sem `googleServerClientId` (AUTH-02): falha com uma
/// mensagem clara em vez de chamar a API sem `X-Goog-Api-Key`.
class GooglePlacesMissingApiKeyException implements Exception {
  const GooglePlacesMissingApiKeyException();
}

/// Encapsula a chamada HTTP à Google Places API (New) - Text Search
/// apenas (F12, escopo desta fase). Autenticação via header
/// `X-Goog-Api-Key` (nunca query string - a URL nunca carrega a chave,
/// diferente da API Legacy) + `X-Goog-FieldMask` explícito, nunca `*`.
///
/// Retorna `List<Map<String, dynamic>>` crus (cada item é um objeto
/// `places[]` da resposta) - o mapeamento para `GooglePlaceResult`
/// acontece em `GooglePlacesRepositoryImpl`, nunca aqui (mesma separação
/// datasource/repository de todo o projeto).
class GooglePlacesRemoteDatasource {
  /// [apiKey] é injetado (não lido direto de `AppEnvironment` dentro do
  /// método) por 2 motivos: testabilidade - `String.fromEnvironment` é
  /// resolvido em tempo de compilação, então testes rodando sem
  /// `--dart-define` sempre veriam uma string vazia se o valor fosse lido
  /// direto aqui, tornando impossível testar o caminho de sucesso/erros
  /// HTTP sem recompilar o binário de teste - e para manter esta classe
  /// desacoplada de `AppEnvironment` (só o provider, em
  /// `google_places_repository_impl.dart`, conhece essa fonte).
  GooglePlacesRemoteDatasource(this._client, {required this.apiKey});

  final http.Client _client;
  final String apiKey;

  static const _searchTextUrl =
      'https://places.googleapis.com/v1/places:searchText';

  /// FieldMask mínimo para o fluxo de cadastro (F12 §6): `id` (dedup por
  /// `google_place_id`), `displayName` (nome), `formattedAddress`
  /// (endereço), `location` (latitude/longitude), `types` (sugestão de
  /// categoria). Nenhum outro campo é pedido - em particular, sem
  /// `photos` (evita custo e escopo de Places Photos, fora desta fase).
  static const _fieldMask =
      'places.id,places.displayName,places.formattedAddress,'
      'places.location,places.types';

  static const _tag = 'restaurants/GooglePlacesRemoteDatasource.searchText';

  Future<List<Map<String, dynamic>>> searchText(String query) async {
    if (apiKey.isEmpty) {
      throw const GooglePlacesMissingApiKeyException();
    }

    AppLogger.info('Google Places search started', tag: _tag);

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_searchTextUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': apiKey,
              'X-Goog-FieldMask': _fieldMask,
            },
            body: jsonEncode({'textQuery': query}),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      AppLogger.warning('Google Places search failed: offline', tag: _tag);
      rethrow;
    }

    if (response.statusCode != 200) {
      AppLogger.warning(
        'Google Places search failed: ${response.statusCode}',
        tag: _tag,
      );
      throw GooglePlacesHttpException(response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final places = body['places'] as List<dynamic>?;
    if (places == null) {
      AppLogger.info('Google Places search returned 0 results', tag: _tag);
      return const [];
    }

    AppLogger.info(
      'Google Places search returned ${places.length} results',
      tag: _tag,
    );
    return places.cast<Map<String, dynamic>>();
  }
}
