import 'package:app/features/group_ranking/application/group_ranking_controller.dart';
import 'package:app/features/group_ranking/data/group_ranking_repository_impl.dart';
import 'package:app/features/group_ranking/domain/group_ranking_entry.dart';
import 'package:app/features/group_ranking/domain/group_ranking_repository.dart';
import 'package:app/features/group_ranking/presentation/states/group_ranking_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRankingRepository extends Mock implements GroupRankingRepository {}

GroupRankingEntry _entry({String userId = 'u-1', int eventsCount = 3}) {
  return GroupRankingEntry(
    userId: userId,
    fullName: 'Ana Silva',
    avatarUrl: null,
    eventsCount: eventsCount,
    reviewsCount: 2,
    averageScore: 4.5,
    declinedCount: 0,
  );
}

void main() {
  late MockGroupRankingRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockGroupRankingRepository();
    container = ProviderContainer(
      overrides: [groupRankingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é GroupRankingInitial', () {
    expect(
      container.read(groupRankingControllerProvider),
      isA<GroupRankingInitial>(),
    );
  });

  group('load', () {
    test('sucesso -> GroupRankingLoaded', () async {
      when(() => repository.listByGroup('g-1')).thenAnswer(
        (_) async => [_entry(userId: 'u-1', eventsCount: 3), _entry(userId: 'u-2', eventsCount: 1)],
      );

      await container.read(groupRankingControllerProvider.notifier).load('g-1');

      final status = container.read(groupRankingControllerProvider);
      expect(status, isA<GroupRankingLoaded>());
      expect((status as GroupRankingLoaded).entries, hasLength(2));
    });

    test('lista vazia -> GroupRankingEmpty', () async {
      when(() => repository.listByGroup('g-1')).thenAnswer((_) async => []);

      await container.read(groupRankingControllerProvider.notifier).load('g-1');

      expect(
        container.read(groupRankingControllerProvider),
        isA<GroupRankingEmpty>(),
      );
    });

    test('falha com GroupRankingRepositoryException -> GroupRankingError com a mensagem original', () async {
      when(() => repository.listByGroup('g-1')).thenThrow(
        const GroupRankingRepositoryException('Você não é membro deste grupo.'),
      );

      await container.read(groupRankingControllerProvider.notifier).load('g-1');

      final status = container.read(groupRankingControllerProvider);
      expect(status, isA<GroupRankingError>());
      expect(
        (status as GroupRankingError).message,
        'Você não é membro deste grupo.',
      );
    });

    test('falha inesperada -> GroupRankingError com mensagem genérica', () async {
      when(() => repository.listByGroup('g-1')).thenThrow(Exception('erro de rede'));

      await container.read(groupRankingControllerProvider.notifier).load('g-1');

      final status = container.read(groupRankingControllerProvider);
      expect(status, isA<GroupRankingError>());
      expect(
        (status as GroupRankingError).message,
        'Não foi possível carregar o ranking.',
      );
    });
  });
}
