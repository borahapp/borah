import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_result.dart';
import '../data/ranking_repository_impl.dart';
import '../domain/ranked_restaurant.dart';
import '../domain/ranking_repository.dart';
import '../domain/ranking_scope.dart';
import '../presentation/states/rankings_status.dart';

/// Fluxo RankingRepository -> Controller (mesmo padrão do DV-01/02/03/04).
/// Item F (ranking multi-escopo) - um único controller cobre os 3 escopos
/// (`global`/`personal`/`group`), já que os 3 compartilham a mesma forma
/// de paginação/concorrência - só o que é passado para
/// `RankingRepository.list` muda.
class RankingsController extends Notifier<RankingsStatus> {
  @override
  RankingsStatus build() => const RankingsInitial();

  RankingRepository get _repository => ref.read(rankingRepositoryProvider);

  RankingScope _scope = RankingScope.global;
  String? _groupId;
  String? _userId;
  String? _city;
  String? _state;
  String? _country;
  String? _category;
  int _page = 1;
  int _requestId = 0;
  static const _limit = 20;

  RankingScope get scope => _scope;

  /// [groupId] obrigatório para `RankingScope.group`, [userId] obrigatório
  /// para `RankingScope.personal` - a página é quem resolve esses valores
  /// (seletor de grupo / `currentUserIdProvider`) antes de chamar `load`.
  /// Os filtros de localização/categoria são preservados entre trocas de
  /// escopo (decisão de UX: trocar de Global para Grupo não deve limpar um
  /// filtro de cidade que a pessoa já aplicou).
  Future<void> load({
    RankingScope? scope,
    String? groupId,
    String? userId,
    String? city,
    String? state,
    String? country,
    String? category,
  }) {
    _scope = scope ?? _scope;
    _groupId = groupId;
    _userId = userId;
    _city = city;
    _state = state;
    _country = country;
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
  /// (ex.: trocar de escopo ou aplicar um filtro com o scroll perto do
  /// fim) produza um resultado final inconsistente, qualquer que seja a
  /// ordem das respostas.
  Future<void> _run(
    RankingsStatus loadingState, {
    List<RankedRestaurant> previousItems = const [],
    required int requestId,
  }) async {
    state = loadingState;
    try {
      final result = await _repository.list(
        scope: _scope,
        groupId: _groupId,
        userId: _userId,
        city: _city,
        state: _state,
        country: _country,
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
