import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Coordenadas resolvidas pelo dispositivo (Item G - sugestão por
/// localização em Explorar).
class LocationCoordinates {
  const LocationCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// GPS/localização desligada no dispositivo (diferente de permissão
/// negada - aqui o app nem chega a perguntar).
class LocationServiceDisabledException implements Exception {}

/// Usuário negou a permissão (uma vez ou permanentemente - `geolocator`
/// não distingue os dois quando `requestPermission` retorna `denied`
/// após já ter sido chamado, então tratamos igual: a UI oferece
/// "Tentar novamente", que reabre o pedido do próprio SO/navegador).
class LocationPermissionDeniedException implements Exception {}

/// Encapsula o `geolocator` (Item G) - mesma decisão de isolamento de
/// `ImagePickerService` (core/services/): a camada de aplicação nunca
/// importa o pacote de terceiros diretamente.
class LocationService {
  Future<LocationCoordinates> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw LocationServiceDisabledException();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException();
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return LocationCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

/// Diferente de `ImagePickerService` (instanciado direto em cada tela,
/// nunca testado isoladamente) - `LocationService` precisa ser
/// substituível em teste, já que seu resultado decide o estado de
/// `NearbyRestaurantsController` (sucesso/permissão negada/serviço
/// desligado), não só uma ação pontual de UI.
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
