import '../../domain/restaurant.dart';

/// Estado da resolução de um `GooglePlaceResult` selecionado (F12) -
/// reaproveitar restaurante existente ou criar um novo, sealed class.
sealed class GooglePlaceSelectionStatus {
  const GooglePlaceSelectionStatus();
}

final class GooglePlaceSelectionInitial extends GooglePlaceSelectionStatus {
  const GooglePlaceSelectionInitial();
}

final class GooglePlaceSelectionResolving extends GooglePlaceSelectionStatus {
  const GooglePlaceSelectionResolving();
}

/// [wasCreated] distingue "restaurante já existia" de "acabou de ser
/// criado" - só para a mensagem exibida ao usuário (F12 §12), a
/// navegação final é a mesma nos 2 casos (`/restaurants/:id`).
final class GooglePlaceSelectionResolved extends GooglePlaceSelectionStatus {
  const GooglePlaceSelectionResolved(
    this.restaurant, {
    required this.wasCreated,
  });

  final Restaurant restaurant;
  final bool wasCreated;
}

final class GooglePlaceSelectionError extends GooglePlaceSelectionStatus {
  const GooglePlaceSelectionError(this.message);

  final String message;
}
