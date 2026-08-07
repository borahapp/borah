import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/group_ranking/data/group_ranking_repository_impl.dart';
import 'package:app/features/group_ranking/domain/group_ranking_entry.dart';
import 'package:app/features/group_ranking/domain/group_ranking_repository.dart';
import 'package:app/features/group_ranking/presentation/pages/group_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRankingRepository extends Mock
    implements GroupRankingRepository {}

class MockEventRepository extends Mock implements EventRepository {}

GroupRankingEntry _entry({
  String userId = 'u-1',
  String fullName = 'Ana Silva',
  int eventsCount = 3,
  int reviewsCount = 2,
  double? averageScore = 4.5,
  int declinedCount = 0,
}) {
  return GroupRankingEntry(
    userId: userId,
    fullName: fullName,
    avatarUrl: null,
    eventsCount: eventsCount,
    reviewsCount: reviewsCount,
    averageScore: averageScore,
    declinedCount: declinedCount,
  );
}

Event _event({
  String id = 'e-1',
  String status = 'completed',
  DateTime? scheduledAt,
  String restaurantId = 'r-1',
  String restaurantName = 'Cantina da Vila',
  double? averageRating,
  String organizerId = 'u-organizer',
}) {
  return Event(
    id: id,
    groupId: 'g-1',
    restaurantId: restaurantId,
    organizerId: organizerId,
    scheduledAt:
        scheduledAt ?? DateTime.now().subtract(const Duration(days: 3)),
    status: status,
    restaurantName: restaurantName,
    averageRating: averageRating,
  );
}

Widget _wrap({
  required MockGroupRankingRepository rankingRepository,
  required MockEventRepository eventRepository,
  int initialTabIndex = 0,
}) {
  return ProviderScope(
    overrides: [
      groupRankingRepositoryProvider.overrideWithValue(rankingRepository),
      eventRepositoryProvider.overrideWithValue(eventRepository),
    ],
    child: MaterialApp(
      home: GroupHubPage(groupId: 'g-1', initialTabIndex: initialTabIndex),
    ),
  );
}

void main() {
  late MockGroupRankingRepository rankingRepository;
  late MockEventRepository eventRepository;

  setUp(() {
    rankingRepository = MockGroupRankingRepository();
    eventRepository = MockEventRepository();
  });

  testWidgets('mostra as 3 abas e o Ranking carregado por padrão', (
    tester,
  ) async {
    when(() => rankingRepository.listByGroup('g-1')).thenAnswer(
      (_) async => [
        _entry(userId: 'u-1', fullName: 'Ana Silva', eventsCount: 5),
        _entry(userId: 'u-2', fullName: 'Bia Costa', eventsCount: 2),
      ],
    );
    when(
      () => eventRepository.listByGroup('g-1'),
    ).thenAnswer((_) async => [_event()]);

    await tester.pumpWidget(
      _wrap(
        rankingRepository: rankingRepository,
        eventRepository: eventRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Estatísticas'), findsOneWidget);
    expect(find.text('Memórias'), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Bia Costa'), findsOneWidget);
  });

  testWidgets(
    'initialTabIndex abre direto na aba correspondente (FASE B, Entrega 5)',
    (tester) async {
      when(
        () => rankingRepository.listByGroup('g-1'),
      ).thenAnswer((_) async => [_entry()]);
      when(
        () => eventRepository.listByGroup('g-1'),
      ).thenAnswer((_) async => [_event()]);

      await tester.pumpWidget(
        _wrap(
          rankingRepository: rankingRepository,
          eventRepository: eventRepository,
          initialTabIndex: 1,
        ),
      );
      await tester.pumpAndSettle();

      // Conteúdo da aba Estatísticas já visível sem precisar tocar em
      // nada - prova que a aba inicial é a 1 (Estatísticas), não a
      // 0 (Ranking, default).
      expect(find.text('Total de rolês'), findsOneWidget);
    },
  );

  testWidgets('aba Estatísticas mostra os totais do grupo', (tester) async {
    // Valores escolhidos para que nenhum número se repita entre os
    // rótulos - evita um finder ambíguo (`find.text` faz match exato).
    when(() => rankingRepository.listByGroup('g-1')).thenAnswer(
      (_) async => [_entry(eventsCount: 9, reviewsCount: 8, declinedCount: 7)],
    );
    when(() => eventRepository.listByGroup('g-1')).thenAnswer(
      (_) async => [
        _event(id: 'e-1', restaurantId: 'r-1'),
        _event(id: 'e-2', restaurantId: 'r-2'),
        _event(id: 'e-3', restaurantId: 'r-2'),
        // Ainda não realizado - garante que "Total de rolês" (4) e
        // "Realizados" (3) não coincidam.
        _event(
          id: 'e-4',
          restaurantId: 'r-3',
          status: 'scheduled',
          scheduledAt: DateTime.now().add(const Duration(days: 5)),
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        rankingRepository: rankingRepository,
        eventRepository: eventRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Estatísticas'));
    await tester.pumpAndSettle();

    expect(find.text('Total de rolês'), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // total de rolês
    expect(
      find.text('2'),
      findsOneWidget,
    ); // restaurantes diferentes (só realizados)
  });

  testWidgets(
    'aba Memórias mostra "Mais visitado" e "Campeão" derivados dos rolês',
    (tester) async {
      when(
        () => rankingRepository.listByGroup('g-1'),
      ).thenAnswer((_) async => [_entry()]);
      when(() => eventRepository.listByGroup('g-1')).thenAnswer(
        (_) async => [
          _event(
            id: 'e-1',
            restaurantId: 'r-1',
            restaurantName: 'Cantina da Vila',
            averageRating: 4.0,
          ),
          _event(
            id: 'e-2',
            restaurantId: 'r-1',
            restaurantName: 'Cantina da Vila',
            averageRating: 4.0,
          ),
          _event(
            id: 'e-3',
            restaurantId: 'r-2',
            restaurantName: 'Sushi Kaze',
            averageRating: 5.0,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          rankingRepository: rankingRepository,
          eventRepository: eventRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Memórias'));
      await tester.pumpAndSettle();

      expect(find.text('Mais visitado'), findsOneWidget);
      expect(find.text('Cantina da Vila'), findsWidgets);
      expect(find.text('Campeão'), findsOneWidget);
      expect(find.text('Sushi Kaze'), findsOneWidget);
      expect(find.text('5.0 ⭐'), findsOneWidget);
    },
  );

  testWidgets(
    'rolê ainda não realizado (agendado no futuro) não conta como memória',
    (tester) async {
      when(
        () => rankingRepository.listByGroup('g-1'),
      ).thenAnswer((_) async => [_entry()]);
      when(() => eventRepository.listByGroup('g-1')).thenAnswer(
        (_) async => [
          _event(
            id: 'e-1',
            restaurantId: 'r-1',
            restaurantName: 'Cantina da Vila',
          ),
          // Mesmo restaurante visitado só 1x de verdade (acima), mas
          // agendado 3x no futuro - se o filtro de "realizados" não
          // excluir rolês futuros (bug real já encontrado nesta
          // entrega), este viraria "Mais visitado" por engano.
          _event(
            id: 'e-2',
            restaurantId: 'r-2',
            restaurantName: 'Sushi Kaze',
            status: 'scheduled',
            scheduledAt: DateTime.now().add(const Duration(days: 1)),
          ),
          _event(
            id: 'e-3',
            restaurantId: 'r-2',
            restaurantName: 'Sushi Kaze',
            status: 'scheduled',
            scheduledAt: DateTime.now().add(const Duration(days: 2)),
          ),
          _event(
            id: 'e-4',
            restaurantId: 'r-2',
            restaurantName: 'Sushi Kaze',
            status: 'scheduled',
            scheduledAt: DateTime.now().add(const Duration(days: 3)),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          rankingRepository: rankingRepository,
          eventRepository: eventRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Memórias'));
      await tester.pumpAndSettle();

      expect(find.text('Mais visitado'), findsOneWidget);
      expect(find.text('Cantina da Vila'), findsOneWidget);
      expect(find.text('Sushi Kaze'), findsNothing);
    },
  );

  testWidgets('grupo sem rolês realizados mostra estado vazio em Memórias', (
    tester,
  ) async {
    when(
      () => rankingRepository.listByGroup('g-1'),
    ).thenAnswer((_) async => []);
    when(() => eventRepository.listByGroup('g-1')).thenAnswer((_) async => []);

    await tester.pumpWidget(
      _wrap(
        rankingRepository: rankingRepository,
        eventRepository: eventRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Memórias'));
    await tester.pumpAndSettle();

    expect(
      find.text('Este grupo ainda não tem rolês realizados.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'erro ao carregar o ranking mostra estado de erro na aba Ranking',
    (tester) async {
      when(() => rankingRepository.listByGroup('g-1')).thenThrow(
        const GroupRankingRepositoryException('Você não é membro deste grupo.'),
      );
      when(
        () => eventRepository.listByGroup('g-1'),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        _wrap(
          rankingRepository: rankingRepository,
          eventRepository: eventRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Você não é membro deste grupo.'), findsOneWidget);
    },
  );
}
