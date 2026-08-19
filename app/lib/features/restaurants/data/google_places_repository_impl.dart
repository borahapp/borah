import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/environment/app_environment.dart';
import '../domain/google_place_result.dart';
import '../domain/google_places_repository.dart';
import 'google_places_remote_datasource.dart';

class GooglePlacesRepositoryImpl implements GooglePlacesRepository {
  GooglePlacesRepositoryImpl(this._datasource);

  final GooglePlacesRemoteDatasource _datasource;

  @override
  Future<List<GooglePlaceResult>> searchText(String query) {
    return _guard(() async {
      final rows = await _datasource.searchText(query);
      return rows.map(_mapPlace).toList();
    });
  }

  GooglePlaceResult _mapPlace(Map<String, dynamic> json) {
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    return GooglePlaceResult(
      placeId: json['id'] as String,
      name: displayName?['text'] as String? ?? '',
      address: json['formattedAddress'] as String?,
      latitude: (location?['latitude'] as num?)?.toDouble(),
      longitude: (location?['longitude'] as num?)?.toDouble(),
      types:
          (json['types'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
    );
  }

  /// Traduz erro de transporte/HTTP em mensagem amigável (F12 §14) - nunca
  /// propaga status/corpo/headers brutos para a UI. Faixas de código
  /// seguem exatamente o pedido: 429 tem mensagem própria (limite de
  /// consultas); 5xx/timeout/offline compartilham "indisponibilidade";
  /// os demais (400/401/403 e qualquer outro 4xx) caem no erro genérico -
  /// não há por que a UI distinguir "chave inválida" (403) de "consulta
  /// malformada" (400): nenhum dos dois é acionável pelo usuário.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on GooglePlacesMissingApiKeyException {
      throw const GooglePlacesRepositoryException(
        'Não foi possível buscar restaurantes. Tente novamente.',
      );
    } on GooglePlacesHttpException catch (e) {
      if (e.statusCode == 429) {
        throw const GooglePlacesRepositoryException(
          'Limite de consultas atingido. Tente novamente em alguns instantes.',
        );
      }
      if (e.statusCode >= 500) {
        throw const GooglePlacesRepositoryException(
          'Serviço temporariamente indisponível.',
        );
      }
      throw const GooglePlacesRepositoryException(
        'Não foi possível buscar restaurantes. Tente novamente.',
      );
    } on TimeoutException {
      throw const GooglePlacesRepositoryException(
        'Serviço temporariamente indisponível.',
      );
    } on Object catch (e) {
      // SocketException (offline) e qualquer outra falha de transporte -
      // `on Object` (não `catch (_)`) porque `_guard<T>` já é genérico o
      // suficiente para não precisar de um tipo mais específico aqui;
      // `SocketException` vive em `dart:io`, que este arquivo (camada de
      // repositório, sem I/O direto) não precisa importar só para isto.
      if (e is GooglePlacesRepositoryException) rethrow;
      throw const GooglePlacesRepositoryException(
        'Serviço temporariamente indisponível.',
      );
    }
  }
}

final googlePlacesHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final googlePlacesRepositoryProvider = Provider<GooglePlacesRepository>((ref) {
  final client = ref.watch(googlePlacesHttpClientProvider);
  return GooglePlacesRepositoryImpl(
    GooglePlacesRemoteDatasource(
      client,
      apiKey: AppEnvironment.googlePlacesApiKey,
    ),
  );
});
