import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/restaurant_repository_impl.dart';
import '../domain/google_place_result.dart';
import '../domain/restaurant_repository.dart';
import '../presentation/states/google_place_selection_status.dart';

/// Resolve um `GooglePlaceResult` selecionado em um `Restaurant` do BORAH
/// (F12 §11/§12) - `google_place_id` é a chave de deduplicação:
///
/// 1. procura um restaurante existente por `google_place_id`;
/// 2. se existir, reaproveita (nunca cria de novo);
/// 3. se não existir, cria preenchendo nome/endereço/coordenadas/
///    `google_place_id` a partir do que o Google já devolveu - o usuário
///    nunca precisa redigitar o que já veio pronto.
class GooglePlaceSelectionController
    extends Notifier<GooglePlaceSelectionStatus> {
  @override
  GooglePlaceSelectionStatus build() => const GooglePlaceSelectionInitial();

  RestaurantRepository get _repository =>
      ref.read(restaurantRepositoryProvider);

  /// Tipos genéricos demais para virar categoria (F12 §9 - `types` não é
  /// a mesma taxonomia do campo livre `Restaurant.category`); o primeiro
  /// tipo que não estiver nesta lista vira a categoria sugerida.
  static const _genericTypes = {'point_of_interest', 'establishment', 'food'};

  Future<void> selectPlace(
    GooglePlaceResult place, {
    required String createdBy,
  }) async {
    state = const GooglePlaceSelectionResolving();
    try {
      final existing = await _repository.findByGooglePlaceId(place.placeId);
      if (existing != null) {
        state = GooglePlaceSelectionResolved(existing, wasCreated: false);
        return;
      }

      final created = await _repository.create(
        createdBy: createdBy,
        name: place.name,
        category: _categoryFromTypes(place.types),
        address: place.address,
        latitude: place.latitude,
        longitude: place.longitude,
        googlePlaceId: place.placeId,
      );
      state = GooglePlaceSelectionResolved(created, wasCreated: true);
    } on RestaurantRepositoryException catch (e) {
      state = GooglePlaceSelectionError(e.message);
    } catch (_) {
      state = const GooglePlaceSelectionError(
        'Não foi possível cadastrar o restaurante.',
      );
    }
  }

  /// Título-caso simples do primeiro tipo não-genérico (ex.: `restaurant`
  /// -> `Restaurant`) - decisão deliberada de manter simples nesta fase
  /// (sem dicionário de tradução PT-BR dos tipos do Google); o usuário
  /// pode editar a categoria depois pelo fluxo de edição já existente
  /// (DV-08). `'Restaurante'` é o padrão quando só há tipos genéricos.
  String _categoryFromTypes(List<String> types) {
    final specific = types.firstWhere(
      (type) => !_genericTypes.contains(type),
      orElse: () => '',
    );
    if (specific.isEmpty) return 'Restaurante';
    return specific
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

final googlePlaceSelectionControllerProvider =
    NotifierProvider<
      GooglePlaceSelectionController,
      GooglePlaceSelectionStatus
    >(GooglePlaceSelectionController.new);
