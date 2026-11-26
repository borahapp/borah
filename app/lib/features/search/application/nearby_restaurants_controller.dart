import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/location_service.dart';
import '../../restaurants/data/restaurant_repository_impl.dart';
import '../../restaurants/domain/restaurant_repository.dart';
import '../presentation/states/nearby_restaurants_status.dart';

/// "Perto de você" (Item G - sugestão por localização em Explorar):
/// localiza o dispositivo (`LocationService`) e busca restaurantes
/// próximos (`RestaurantRepository.listNearby`). Erros de localização
/// (serviço desligado/permissão negada) viram estados próprios, não
/// `NearbyRestaurantsError` - a tela mostra uma mensagem acionável
/// ("Tentar novamente") em vez de um erro genérico.
class NearbyRestaurantsController extends Notifier<NearbyRestaurantsStatus> {
  @override
  NearbyRestaurantsStatus build() => const NearbyRestaurantsInitial();

  static const _limit = 10;
  int _requestId = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    state = const NearbyRestaurantsLoading();
    try {
      final location = await ref
          .read(locationServiceProvider)
          .getCurrentLocation();
      if (requestId != _requestId) return;

      final restaurants = await ref
          .read(restaurantRepositoryProvider)
          .listNearby(
            latitude: location.latitude,
            longitude: location.longitude,
            limit: _limit,
          );
      if (requestId != _requestId) return;

      state = restaurants.isEmpty
          ? const NearbyRestaurantsEmpty()
          : NearbyRestaurantsLoaded(restaurants);
    } on LocationServiceDisabledException {
      if (requestId != _requestId) return;
      state = const NearbyRestaurantsServiceDisabled();
    } on LocationPermissionDeniedException {
      if (requestId != _requestId) return;
      state = const NearbyRestaurantsPermissionDenied();
    } on RestaurantRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = NearbyRestaurantsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = const NearbyRestaurantsError(
        'Não foi possível buscar restaurantes perto de você.',
      );
    }
  }
}

final nearbyRestaurantsControllerProvider =
    NotifierProvider<NearbyRestaurantsController, NearbyRestaurantsStatus>(
      NearbyRestaurantsController.new,
    );
