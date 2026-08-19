import '../../domain/google_place_result.dart';

/// Estado da busca de restaurantes reais (F12), sealed class.
sealed class GooglePlaceSearchStatus {
  const GooglePlaceSearchStatus();
}

/// Nenhuma busca feita ainda, ou campo de busca vazio (F12 §7 - string
/// vazia nunca dispara chamada).
final class GooglePlaceSearchInitial extends GooglePlaceSearchStatus {
  const GooglePlaceSearchInitial();
}

final class GooglePlaceSearchLoading extends GooglePlaceSearchStatus {
  const GooglePlaceSearchLoading();
}

final class GooglePlaceSearchLoaded extends GooglePlaceSearchStatus {
  const GooglePlaceSearchLoaded(this.results);

  final List<GooglePlaceResult> results;
}

final class GooglePlaceSearchEmpty extends GooglePlaceSearchStatus {
  const GooglePlaceSearchEmpty();
}

final class GooglePlaceSearchError extends GooglePlaceSearchStatus {
  const GooglePlaceSearchError(this.message);

  final String message;
}
