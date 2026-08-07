import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../../restaurants/domain/restaurant.dart';
import '../data/ranking_repository_impl.dart';
import '../domain/ranking_repository.dart';
import '../presentation/states/rankings_status.dart';

/// Fluxo simples RankingRepository -> Controller (mesmo padrão do
/// DV-01/02/03/04), sem use cases intermediários. `load()` sem
/// parâmetros cobre o Ranking Geral; com `city` e/ou `category` cobre
/// Cidade, Categoria e Personalizado (DV-05 §5) - um único método, já
/// que os quatro são a mesma consulta com filtros diferentes. "Ranking
/// entre Amigos" não é coberto (decisão do DV-05 - depende de Grupos/
/// DV-07, que ainda não existem).
class RankingsController extends Notifier<RankingsStatus> {
  @override
  RankingsStatus build() => const RankingsInitial();

  RankingRepository get _repository => ref.read(rankingRepositoryProvider);

  String? _city;
  String? _category;
  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  Future<void> load({String? city, String? category}) {
    _city = city;
    _category = category;
    _page = 1;
    return _run(const RankingsLoading(), requestId: ++_requestId);
  }

  Future<void> loadNextPage() {
    final current = state;
    if (current is! RankingsLoaded || !current.result.hasNextPage) {
      return Future.value();
    }
    _page++;
    return _run(
      current,
      previousItems: current.result.items,
      requestId: ++_requestId,
    );
  }

  /// [requestId] coordena chamadas concorrentes (mesmo mecanismo de
  /// `FeedController._run`): só a resposta cujo `requestId` ainda bate com
  /// `_requestId` no momento em que o fetch resolve pode escrever em
  /// `state` - evita que um `loadNextPage` disparado durante um `load`
  /// (ex.: aplicar um filtro com o scroll perto do fim) produza um
  /// resultado final inconsistente, qualquer que seja a ordem das
  /// respostas.
  Future<void> _run(
    RankingsStatus loadingState, {
    List<Restaurant> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.listRanked(
        city: _city,
        category: _category,
        page: _page,
        limit: _limit,
      );
      if (requestId != _requestId) return;
      final items = [...previousItems, ...result.items];
      state = items.isEmpty
          ? const RankingsEmpty()
          : RankingsLoaded(
              PagedResult(
                items: items,
                page: result.page,
                limit: result.limit,
                hasNextPage: result.hasNextPage,
              ),
            );
    } on RankingRepositoryException catch (e) {
      if (requestId != _requestId) return;
      // Falha ao buscar a PRÓXIMA página com itens já acumulados: mantém
      // a lista já carregada visível em vez de virar tela cheia de erro.
      // Reverte `_page`: a página que falhou nunca chegou a ser aplicada,
      // então a próxima tentativa deve rebuscá-la, em vez de pular para a
      // seguinte.
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = RankingsError(e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      if (previousItems.isNotEmpty) {
        _page--;
        return;
      }
      state = const RankingsError('Não foi possível carregar o ranking.');
    }
  }
}

final rankingsControllerProvider =
    NotifierProvider<RankingsController, RankingsStatus>(
      RankingsController.new,
    );
