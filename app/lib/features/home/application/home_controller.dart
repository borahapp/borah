import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/data/event_repository_impl.dart';
import '../../events/domain/event.dart';
import '../../events/domain/event_repository.dart';
import '../../groups/data/group_repository_impl.dart';
import '../../groups/domain/group.dart';
import '../../groups/domain/group_repository.dart';
import '../presentation/states/home_status.dart';

/// Controller da nova Home (FASE 01 da simplificação de produto, ver
/// `BORAH_NEXT_STEP_ANALYSIS.md`/auditoria aprovada). Não possui
/// repository/datasource próprio - compõe exclusivamente
/// `GroupRepository`/`EventRepository`, já existentes, sem nenhuma
/// tabela/RPC/RLS nova.
///
/// `Group.nextEvent` (populado por `listMine()`) já traz, por grupo, o
/// `id`/`scheduledAt` do próximo rolê agendado - suficiente para achar o
/// rolê mais próximo entre TODOS os grupos sem nenhuma chamada extra.
/// Só o card "Próximo rolê" precisa do nome do restaurante, que
/// `EventSummary` deliberadamente não carrega (ver seu doc comment) -
/// por isso, exatamente 1 chamada adicional a `getById` para esse único
/// rolê, nunca uma por grupo (nada de N+1).
class HomeController extends Notifier<HomeStatus> {
  @override
  HomeStatus build() => const HomeInitial();

  GroupRepository get _groupRepository => ref.read(groupRepositoryProvider);
  EventRepository get _eventRepository => ref.read(eventRepositoryProvider);

  Future<void> load() async {
    state = const HomeLoading();
    try {
      final groups = await _groupRepository.listMine();

      final withNextEvent = groups.where((g) => g.nextEvent != null).toList()
        ..sort(
          (a, b) =>
              a.nextEvent!.scheduledAt.compareTo(b.nextEvent!.scheduledAt),
        );

      Group? heroGroup;
      Event? heroEvent;
      if (withNextEvent.isNotEmpty) {
        heroGroup = withNextEvent.first;
        final details = await _eventRepository.getById(heroGroup.nextEvent!.id);
        heroEvent = details.event;
      }

      state = HomeLoaded(
        groups: groups,
        heroEvent: heroEvent,
        heroEventGroup: heroGroup,
      );
    } on GroupRepositoryException catch (e) {
      state = HomeError(e.message);
    } on EventRepositoryException catch (e) {
      state = HomeError(e.message);
    } catch (_) {
      state = const HomeError('Não foi possível carregar sua Home.');
    }
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeStatus>(
  HomeController.new,
);
