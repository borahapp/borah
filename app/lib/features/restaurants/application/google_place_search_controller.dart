import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/google_places_repository_impl.dart';
import '../domain/google_place_result.dart';
import '../domain/google_places_repository.dart';
import '../presentation/states/google_place_search_status.dart';

/// Busca de restaurantes reais (F12) - Text Search (New). O debounce
/// "não chamar a cada tecla" (F12 §8) é responsabilidade da tela
/// (`SearchGoogleRestaurantPage`, mesmo padrão do projeto de manter
/// timing de UI no widget, não no controller - ver `_onScroll`/
/// `_isLoadingMore` de `FeedPage`) - `search()` aqui já assume que o
/// debounce já passou e a busca deve acontecer agora.
///
/// Cache simples de 1 slot (F12 §16): repetir a MESMA busca (já
/// normalizada) imediatamente reaproveita o último resultado, sem nova
/// chamada à API - cobre o caso "Madero Jundiaí" pesquisado de novo logo
/// em seguida, sem precisar de infraestrutura de cache dedicada.
class GooglePlaceSearchController extends Notifier<GooglePlaceSearchStatus> {
  @override
  GooglePlaceSearchStatus build() => const GooglePlaceSearchInitial();

  GooglePlacesRepository get _repository =>
      ref.read(googlePlacesRepositoryProvider);

  int _requestId = 0;
  String? _lastQuery;
  List<GooglePlaceResult>? _lastResults;

  Future<void> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      _lastQuery = null;
      _lastResults = null;
      state = const GooglePlaceSearchInitial();
      return;
    }

    if (normalized == _lastQuery && _lastResults != null) {
      state = _statusFor(_lastResults!);
      return;
    }

    final requestId = ++_requestId;
    state = const GooglePlaceSearchLoading();
    try {
      final results = await _repository.searchText(normalized);
      if (requestId != _requestId) return;
      _lastQuery = normalized;
      _lastResults = results;
      state = _statusFor(results);
    } on GooglePlacesRepositoryException catch (e) {
      if (requestId != _requestId) return;
      state = GooglePlaceSearchError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = const GooglePlaceSearchError(
        'Não foi possível buscar restaurantes. Tente novamente.',
      );
    }
  }

  GooglePlaceSearchStatus _statusFor(List<GooglePlaceResult> results) {
    return results.isEmpty
        ? const GooglePlaceSearchEmpty()
        : GooglePlaceSearchLoaded(results);
  }
}

final googlePlaceSearchControllerProvider =
    NotifierProvider<GooglePlaceSearchController, GooglePlaceSearchStatus>(
      GooglePlaceSearchController.new,
    );
