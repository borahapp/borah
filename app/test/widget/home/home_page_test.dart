import 'package:app/features/events/data/event_repository_impl.dart';
import 'package:app/features/events/domain/event.dart';
import 'package:app/features/events/domain/event_details.dart';
import 'package:app/features/events/domain/event_repository.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/event_summary.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockEventRepository extends Mock implements EventRepository {}

Group _group({
  String id = 'g-1',
  String name = 'Turma do João',
  int? memberCount = 4,
  EventSummary? nextEvent,
}) {
  return Group(
    id: id,
    name: name,
    description: null,
    photoUrl: null,
    inviteCode: 'FS575HP5',
    memberCount: memberCount,
    nextEvent: nextEvent,
  );
}

Event _event({
  String id = 'e-1',
  String groupId = 'g-1',
  String restaurantName = 'Madero',
}) {
  return Event(
    id: id,
    groupId: groupId,
    restaurantId: 'r-1',
    organizerId: 'u-1',
    scheduledAt: DateTime(2026, 9, 1, 20),
    status: 'scheduled',
    restaurantName: restaurantName,
    confirmedCount: 3,
  );
}

Widget _wrap({
  required MockGroupRepository groupRepository,
  required MockEventRepository eventRepository,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(
        path: '/groups/new',
        builder: (_, _) => const Scaffold(body: Text('Criar grupo (tela)')),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => Scaffold(
          body: Text('Detalhe do grupo ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/groups',
        builder: (_, _) => const Scaffold(body: Text('Meus grupos (tela)')),
      ),
      // Mesma ordem de `app_router.dart`: `/events/new` precisa vir ANTES
      // de `/events/:eventId` - senão o segmento literal "new" seria
      // capturado pelo parâmetro `:eventId` (achado real ao rodar os
      // testes desta fase).
      GoRoute(
        path: '/groups/:groupId/events/new',
        builder: (_, state) => Scaffold(
          body: Text(
            'Criar rolê (tela) no grupo ${state.pathParameters['groupId']}',
          ),
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/events/:eventId',
        builder: (_, state) => Scaffold(
          body: Text(
            'Detalhe do rolê ${state.pathParameters['eventId']} '
            'no grupo ${state.pathParameters['groupId']}',
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      groupRepositoryProvider.overrideWithValue(groupRepository),
      eventRepositoryProvider.overrideWithValue(eventRepository),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockGroupRepository groupRepository;
  late MockEventRepository eventRepository;

  setUp(() {
    groupRepository = MockGroupRepository();
    eventRepository = MockEventRepository();
  });

  Widget wrap() =>
      _wrap(groupRepository: groupRepository, eventRepository: eventRepository);

  testWidgets('HOME-01: Home carregada mostra título e CTA principal', (
    tester,
  ) async {
    when(() => groupRepository.listMine()).thenAnswer((_) async => []);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('BORAH'), findsOneWidget);
    expect(find.text('Criar novo rolê'), findsOneWidget);
  });

  testWidgets(
    'HOME-02: com próximo rolê, mostra restaurante, grupo e card do rolê',
    (tester) async {
      when(() => groupRepository.listMine()).thenAnswer(
        (_) async => [
          _group(
            id: 'g-1',
            name: 'Turma do João',
            nextEvent: EventSummary(
              id: 'e-1',
              scheduledAt: DateTime(2026, 9, 1, 20),
            ),
          ),
        ],
      );
      when(() => eventRepository.getById('e-1')).thenAnswer(
        (_) async => EventDetails(
          event: _event(id: 'e-1', groupId: 'g-1'),
          attendances: const [],
        ),
      );

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('Madero'), findsOneWidget);
      expect(find.text('Turma do João'), findsWidgets); // grupo + card
      expect(find.text('3 confirmados'), findsOneWidget);
    },
  );

  testWidgets(
    'HOME-03: sem próximo rolê, mostra estado vazio com CTA de criar o primeiro',
    (tester) async {
      when(
        () => groupRepository.listMine(),
      ).thenAnswer((_) async => [_group()]);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        find.text('Você ainda não tem nenhum rolê marcado.'),
        findsOneWidget,
      );
      expect(find.text('Criar meu primeiro rolê'), findsOneWidget);
      verifyNever(() => eventRepository.getById(any()));
    },
  );

  testWidgets('HOME-04: com grupos, mostra GroupCard na Home', (tester) async {
    when(() => groupRepository.listMine()).thenAnswer(
      (_) async => [_group(id: 'g-1', name: 'Galera do Rolê', memberCount: 5)],
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Galera do Rolê'), findsOneWidget);
    expect(find.text('5 integrantes'), findsOneWidget);
  });

  testWidgets('HOME-05: sem grupos, mostra estado vazio com "Criar grupo"', (
    tester,
  ) async {
    when(() => groupRepository.listMine()).thenAnswer((_) async => []);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(
      find.text('Você ainda não participa de nenhum grupo.'),
      findsOneWidget,
    );
    // "Criar grupo" aparece 2x: ação do estado vazio + botão do cabeçalho.
    expect(find.text('Criar grupo'), findsWidgets);
  });

  testWidgets('HOME-06: tocar em um grupo abre o detalhe correto', (
    tester,
  ) async {
    when(
      () => groupRepository.listMine(),
    ).thenAnswer((_) async => [_group(id: 'g-42', name: 'Galera do Rolê')]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Galera do Rolê'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do grupo g-42'), findsOneWidget);
  });

  testWidgets(
    'HOME-07: tocar em "+ Criar grupo" abre o fluxo existente de criação',
    (tester) async {
      when(() => groupRepository.listMine()).thenAnswer((_) async => []);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Criar grupo'));
      await tester.pumpAndSettle();

      expect(find.text('Criar grupo (tela)'), findsOneWidget);
    },
  );

  testWidgets(
    'HOME-08 / FASE02-TESTE1: 0 grupos -> "Criar novo rolê" vai para /groups',
    (tester) async {
      when(() => groupRepository.listMine()).thenAnswer((_) async => []);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar novo rolê'));
      await tester.pumpAndSettle();

      expect(find.text('Meus grupos (tela)'), findsOneWidget);
    },
  );

  testWidgets(
    'FASE02-TESTE2: 1 grupo -> "Criar novo rolê" vai direto para a criação, '
    'sem /groups/GroupDetail/EventsList intermediários',
    (tester) async {
      when(
        () => groupRepository.listMine(),
      ).thenAnswer((_) async => [_group(id: 'g-1', name: 'Único Grupo')]);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar novo rolê'));
      await tester.pumpAndSettle();

      expect(find.text('Criar rolê (tela) no grupo g-1'), findsOneWidget);
      expect(find.text('Meus grupos (tela)'), findsNothing);
      expect(find.text('Detalhe do grupo g-1'), findsNothing);
    },
  );

  testWidgets(
    'FASE02-TESTE3: vários grupos -> "Criar novo rolê" abre o bottom sheet '
    '"Escolha o grupo" com todos os grupos, sem nenhuma consulta nova',
    (tester) async {
      when(() => groupRepository.listMine()).thenAnswer(
        (_) async => [
          _group(id: 'g-a', name: 'Grupo A'),
          _group(id: 'g-b', name: 'Grupo B'),
        ],
      );

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar novo rolê'));
      await tester.pumpAndSettle();

      // A Home por trás continua montada (não some do widget tree só por
      // o sheet estar aberto) - escopar ao `BottomSheet` evita achar o
      // mesmo nome 2x (uma vez na seção "Meus grupos", outra no sheet).
      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('Escolha o grupo')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Em qual grupo você quer criar este rolê?'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Grupo A')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Grupo B')),
        findsOneWidget,
      );
      // listMine() só é chamado 1x pelo HomeController.load() inicial -
      // abrir o sheet não dispara nenhuma consulta nova.
      verify(() => groupRepository.listMine()).called(1);
    },
  );

  testWidgets(
    'FASE02-TESTE4: no bottom sheet, tocar no Grupo A vai para a criação '
    'no grupo A',
    (tester) async {
      when(() => groupRepository.listMine()).thenAnswer(
        (_) async => [
          _group(id: 'g-a', name: 'Grupo A'),
          _group(id: 'g-b', name: 'Grupo B'),
        ],
      );

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar novo rolê'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Grupo A'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Criar rolê (tela) no grupo g-a'), findsOneWidget);
    },
  );

  testWidgets(
    'FASE02-TESTE5: no bottom sheet, tocar no Grupo B vai para a criação '
    'no grupo B',
    (tester) async {
      when(() => groupRepository.listMine()).thenAnswer(
        (_) async => [
          _group(id: 'g-a', name: 'Grupo A'),
          _group(id: 'g-b', name: 'Grupo B'),
        ],
      );

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar novo rolê'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Grupo B'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Criar rolê (tela) no grupo g-b'), findsOneWidget);
    },
  );

  testWidgets('tocar no card do próximo rolê abre o detalhe correto do rolê', (
    tester,
  ) async {
    when(() => groupRepository.listMine()).thenAnswer(
      (_) async => [
        _group(
          id: 'g-1',
          nextEvent: EventSummary(
            id: 'e-1',
            scheduledAt: DateTime(2026, 9, 1, 20),
          ),
        ),
      ],
    );
    when(() => eventRepository.getById('e-1')).thenAnswer(
      (_) async => EventDetails(
        event: _event(id: 'e-1', groupId: 'g-1'),
        attendances: const [],
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Madero'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do rolê e-1 no grupo g-1'), findsOneWidget);
  });

  testWidgets(
    'entre 2 grupos com próximo rolê, mostra apenas o mais próximo no tempo',
    (tester) async {
      when(() => groupRepository.listMine()).thenAnswer(
        (_) async => [
          _group(
            id: 'g-far',
            name: 'Grupo distante',
            nextEvent: EventSummary(
              id: 'e-far',
              scheduledAt: DateTime(2026, 12, 25),
            ),
          ),
          _group(
            id: 'g-near',
            name: 'Grupo próximo',
            nextEvent: EventSummary(
              id: 'e-near',
              scheduledAt: DateTime(2026, 9, 1),
            ),
          ),
        ],
      );
      when(() => eventRepository.getById('e-near')).thenAnswer(
        (_) async => EventDetails(
          event: _event(
            id: 'e-near',
            groupId: 'g-near',
            restaurantName: 'Outback',
          ),
          attendances: const [],
        ),
      );

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('Outback'), findsOneWidget);
      verifyNever(() => eventRepository.getById('e-far'));
    },
  );
}
