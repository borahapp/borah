import 'dart:async';
import 'dart:io';

import 'package:app/features/restaurants/data/google_places_remote_datasource.dart';
import 'package:app/features/restaurants/data/google_places_repository_impl.dart';
import 'package:app/features/restaurants/domain/google_places_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGooglePlacesRemoteDatasource extends Mock
    implements GooglePlacesRemoteDatasource {}

Map<String, dynamic> _placeJson({
  String id = 'p-1',
  String name = 'Madero',
  String? address = 'Av. XXXXX, Jundiaí - SP',
  double? lat = -23.1,
  double? lng = -46.8,
  List<String> types = const ['restaurant', 'food', 'point_of_interest'],
}) {
  return {
    'id': id,
    'displayName': {'text': name, 'languageCode': 'pt-BR'},
    'formattedAddress': address,
    'location': lat == null ? null : {'latitude': lat, 'longitude': lng},
    'types': types,
  };
}

void main() {
  late MockGooglePlacesRemoteDatasource datasource;
  late GooglePlacesRepositoryImpl repository;

  setUp(() {
    datasource = MockGooglePlacesRemoteDatasource();
    repository = GooglePlacesRepositoryImpl(datasource);
  });

  group('mapper', () {
    test('mapeia placeId/name/address/latitude/longitude/types', () async {
      when(
        () => datasource.searchText('Madero'),
      ).thenAnswer((_) async => [_placeJson()]);

      final results = await repository.searchText('Madero');

      expect(results, hasLength(1));
      final place = results.single;
      expect(place.placeId, 'p-1');
      expect(place.name, 'Madero');
      expect(place.address, 'Av. XXXXX, Jundiaí - SP');
      expect(place.latitude, -23.1);
      expect(place.longitude, -46.8);
      expect(place.types, ['restaurant', 'food', 'point_of_interest']);
    });

    test('campos ausentes (location nula) não quebram o mapeamento', () async {
      when(() => datasource.searchText('sem local')).thenAnswer(
        (_) async => [_placeJson(id: 'p-2', address: null, lat: null)],
      );

      final results = await repository.searchText('sem local');

      expect(results.single.address, isNull);
      expect(results.single.latitude, isNull);
      expect(results.single.longitude, isNull);
    });
  });

  group('pesquisa', () {
    test('com resultado retorna a lista mapeada', () async {
      when(
        () => datasource.searchText('Madero'),
      ).thenAnswer((_) async => [_placeJson(), _placeJson(id: 'p-2')]);

      final results = await repository.searchText('Madero');

      expect(results, hasLength(2));
    });

    test('sem resultado retorna lista vazia (não erro)', () async {
      when(
        () => datasource.searchText('xyzxyzxyz'),
      ).thenAnswer((_) async => []);

      final results = await repository.searchText('xyzxyzxyz');

      expect(results, isEmpty);
    });
  });

  group('erros traduzidos', () {
    test('sem API key -> mensagem genérica', () async {
      when(
        () => datasource.searchText('Madero'),
      ).thenThrow(const GooglePlacesMissingApiKeyException());

      await expectLater(
        repository.searchText('Madero'),
        throwsA(
          isA<GooglePlacesRepositoryException>().having(
            (e) => e.message,
            'message',
            'Não foi possível buscar restaurantes. Tente novamente.',
          ),
        ),
      );
    });

    for (final statusCode in [400, 401, 403]) {
      test('HTTP $statusCode -> mensagem genérica', () async {
        when(
          () => datasource.searchText('Madero'),
        ).thenThrow(GooglePlacesHttpException(statusCode));

        await expectLater(
          repository.searchText('Madero'),
          throwsA(
            isA<GooglePlacesRepositoryException>().having(
              (e) => e.message,
              'message',
              'Não foi possível buscar restaurantes. Tente novamente.',
            ),
          ),
        );
      });
    }

    test('HTTP 429 -> mensagem de limite de consultas', () async {
      when(
        () => datasource.searchText('Madero'),
      ).thenThrow(const GooglePlacesHttpException(429));

      await expectLater(
        repository.searchText('Madero'),
        throwsA(
          isA<GooglePlacesRepositoryException>().having(
            (e) => e.message,
            'message',
            'Limite de consultas atingido. Tente novamente em alguns instantes.',
          ),
        ),
      );
    });

    for (final statusCode in [500, 503]) {
      test('HTTP $statusCode -> mensagem de indisponibilidade', () async {
        when(
          () => datasource.searchText('Madero'),
        ).thenThrow(GooglePlacesHttpException(statusCode));

        await expectLater(
          repository.searchText('Madero'),
          throwsA(
            isA<GooglePlacesRepositoryException>().having(
              (e) => e.message,
              'message',
              'Serviço temporariamente indisponível.',
            ),
          ),
        );
      });
    }

    test('timeout -> mensagem de indisponibilidade', () async {
      when(
        () => datasource.searchText('Madero'),
      ).thenThrow(TimeoutException('timeout'));

      await expectLater(
        repository.searchText('Madero'),
        throwsA(
          isA<GooglePlacesRepositoryException>().having(
            (e) => e.message,
            'message',
            'Serviço temporariamente indisponível.',
          ),
        ),
      );
    });

    test(
      'offline (SocketException) -> mensagem de indisponibilidade',
      () async {
        when(
          () => datasource.searchText('Madero'),
        ).thenThrow(const SocketException('sem rede'));

        await expectLater(
          repository.searchText('Madero'),
          throwsA(
            isA<GooglePlacesRepositoryException>().having(
              (e) => e.message,
              'message',
              'Serviço temporariamente indisponível.',
            ),
          ),
        );
      },
    );
  });
}
