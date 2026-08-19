import 'dart:async';
import 'dart:io';

import 'package:app/features/restaurants/data/google_places_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('sem API key configurada', () {
    test('lança GooglePlacesMissingApiKeyException antes de chamar a rede', () {
      var callCount = 0;
      final datasource = GooglePlacesRemoteDatasource(
        MockClient((_) async {
          callCount++;
          return http.Response('{}', 200);
        }),
        apiKey: '',
      );

      expect(
        () => datasource.searchText('Madero'),
        throwsA(isA<GooglePlacesMissingApiKeyException>()),
      );
      expect(callCount, 0);
    });
  });

  group('requisição', () {
    test(
      'envia X-Goog-Api-Key/X-Goog-FieldMask e nunca coloca a chave na URL',
      () async {
        late Uri capturedUri;
        late Map<String, String> capturedHeaders;
        final datasource = GooglePlacesRemoteDatasource(
          MockClient((request) async {
            capturedUri = request.url;
            capturedHeaders = request.headers;
            return http.Response('{"places": []}', 200);
          }),
          apiKey: 'fake-test-key',
        );

        await datasource.searchText('Madero');

        expect(capturedUri.toString(), isNot(contains('fake-test-key')));
        expect(capturedUri.toString(), isNot(contains('key=')));
        expect(capturedHeaders['X-Goog-Api-Key'], 'fake-test-key');
        expect(capturedHeaders['X-Goog-FieldMask'], isNot(contains('*')));
        expect(
          capturedHeaders['X-Goog-FieldMask'],
          'places.id,places.displayName,places.formattedAddress,'
          'places.location,places.types',
        );
      },
    );
  });

  group('parser', () {
    test('retorna a lista de places em caso de sucesso', () async {
      final datasource = GooglePlacesRemoteDatasource(
        MockClient(
          (_) async =>
              http.Response('{"places": [{"id": "p-1"}, {"id": "p-2"}]}', 200),
        ),
        apiKey: 'fake-test-key',
      );

      final result = await datasource.searchText('Madero');

      expect(result, hasLength(2));
      expect(result[0]['id'], 'p-1');
    });

    test('resposta sem "places" (sem resultado) vira lista vazia', () async {
      final datasource = GooglePlacesRemoteDatasource(
        MockClient((_) async => http.Response('{}', 200)),
        apiKey: 'fake-test-key',
      );

      final result = await datasource.searchText('xyzxyzxyz');

      expect(result, isEmpty);
    });
  });

  group('códigos de erro', () {
    for (final statusCode in [400, 401, 403, 429, 500, 503]) {
      test(
        'HTTP $statusCode lança GooglePlacesHttpException($statusCode)',
        () async {
          final datasource = GooglePlacesRemoteDatasource(
            MockClient((_) async => http.Response('erro', statusCode)),
            apiKey: 'fake-test-key',
          );

          await expectLater(
            datasource.searchText('Madero'),
            throwsA(
              isA<GooglePlacesHttpException>().having(
                (e) => e.statusCode,
                'statusCode',
                statusCode,
              ),
            ),
          );
        },
      );
    }

    test(
      'timeout lança TimeoutException',
      () async {
        final datasource = GooglePlacesRemoteDatasource(
          MockClient((_) async {
            await Future<void>.delayed(const Duration(seconds: 15));
            return http.Response('{}', 200);
          }),
          apiKey: 'fake-test-key',
        );

        await expectLater(
          datasource.searchText('Madero'),
          throwsA(isA<TimeoutException>()),
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test('offline (SocketException) se propaga', () async {
      final datasource = GooglePlacesRemoteDatasource(
        MockClient((_) async => throw const SocketException('sem rede')),
        apiKey: 'fake-test-key',
      );

      await expectLater(
        datasource.searchText('Madero'),
        throwsA(isA<SocketException>()),
      );
    });
  });
}
