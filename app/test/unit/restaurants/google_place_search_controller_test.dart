import 'dart:async';

import 'package:app/features/restaurants/application/google_place_search_controller.dart';
import 'package:app/features/restaurants/data/google_places_repository_impl.dart';
import 'package:app/features/restaurants/domain/google_place_result.dart';
import 'package:app/features/restaurants/domain/google_places_repository.dart';
import 'package:app/features/restaurants/presentation/states/google_place_search_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGooglePlacesRepository extends Mock
    implements GooglePlacesRepository {}

GooglePlaceResult _place({String placeId = 'p-1', String name = 'Madero'}) {
  return GooglePlaceResult(
    placeId: placeId,
    name: name,
    address: 'Av. XXXXX, Jundiaí - SP',
    latitude: -23.1,
    longitude: -46.8,
    types: const ['restaurant'],
  );
}

void main() {
  late MockGooglePlacesRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockGooglePlacesRepository();
    container = ProviderContainer(
      overrides: [googlePlacesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é GooglePlaceSearchInitial', () {
    expect(
      container.read(googlePlaceSearchControllerProvider),
      isA<GooglePlaceSearchInitial>(),
    );
  });

  test('query vazia (ou só espaços) não chama o repositório', () async {
    await container
        .read(googlePlaceSearchControllerProvider.notifier)
        .search('   ');

    expect(
      container.read(googlePlaceSearchControllerProvider),
      isA<GooglePlaceSearchInitial>(),
    );
    verifyNever(() => repository.searchText(any()));
  });

  test('busca com resultado -> GooglePlaceSearchLoaded', () async {
    when(
      () => repository.searchText('Madero'),
    ).thenAnswer((_) async => [_place()]);

    await container
        .read(googlePlaceSearchControllerProvider.notifier)
        .search('Madero');

    final status = container.read(googlePlaceSearchControllerProvider);
    expect(status, isA<GooglePlaceSearchLoaded>());
    expect((status as GooglePlaceSearchLoaded).results, hasLength(1));
  });

  test('busca sem resultado -> GooglePlaceSearchEmpty', () async {
    when(() => repository.searchText('xyzxyzxyz')).thenAnswer((_) async => []);

    await container
        .read(googlePlaceSearchControllerProvider.notifier)
        .search('xyzxyzxyz');

    expect(
      container.read(googlePlaceSearchControllerProvider),
      isA<GooglePlaceSearchEmpty>(),
    );
  });

  test('busca com falha -> GooglePlaceSearchError', () async {
    when(() => repository.searchText('Madero')).thenThrow(
      const GooglePlacesRepositoryException(
        'Não foi possível buscar restaurantes. Tente novamente.',
      ),
    );

    await container
        .read(googlePlaceSearchControllerProvider.notifier)
        .search('Madero');

    final status = container.read(googlePlaceSearchControllerProvider);
    expect(status, isA<GooglePlaceSearchError>());
    expect(
      (status as GooglePlaceSearchError).message,
      'Não foi possível buscar restaurantes. Tente novamente.',
    );
  });

  test('repetir a MESMA busca reaproveita o cache (F12 §16) - só 1 chamada '
      'ao repositório', () async {
    when(
      () => repository.searchText('Madero'),
    ).thenAnswer((_) async => [_place()]);

    final notifier = container.read(
      googlePlaceSearchControllerProvider.notifier,
    );
    await notifier.search('Madero');
    await notifier.search('Madero'); // mesma busca de novo
    await notifier.search('  Madero  '); // mesma busca, com espaços

    expect(
      container.read(googlePlaceSearchControllerProvider),
      isA<GooglePlaceSearchLoaded>(),
    );
    verify(() => repository.searchText('Madero')).called(1);
  });

  test('busca diferente da anterior dispara nova chamada', () async {
    when(
      () => repository.searchText('Madero'),
    ).thenAnswer((_) async => [_place()]);
    when(
      () => repository.searchText('Outback'),
    ).thenAnswer((_) async => [_place(placeId: 'p-2', name: 'Outback')]);

    final notifier = container.read(
      googlePlaceSearchControllerProvider.notifier,
    );
    await notifier.search('Madero');
    await notifier.search('Outback');

    verify(() => repository.searchText('Madero')).called(1);
    verify(() => repository.searchText('Outback')).called(1);
  });

  test('concorrência: resposta desatualizada não sobrescreve a busca mais '
      'recente', () async {
    final slowCompleter = Completer<List<GooglePlaceResult>>();
    when(
      () => repository.searchText('lento'),
    ).thenAnswer((_) => slowCompleter.future);
    when(
      () => repository.searchText('rapido'),
    ).thenAnswer((_) async => [_place(placeId: 'p-2', name: 'Rápido')]);

    final notifier = container.read(
      googlePlaceSearchControllerProvider.notifier,
    );
    final slowFuture = notifier.search('lento');
    await notifier.search('rapido');

    slowCompleter.complete([_place(placeId: 'p-lento')]);
    await slowFuture;

    final status = container.read(googlePlaceSearchControllerProvider);
    expect(status, isA<GooglePlaceSearchLoaded>());
    expect((status as GooglePlaceSearchLoaded).results.single.name, 'Rápido');
  });
}
