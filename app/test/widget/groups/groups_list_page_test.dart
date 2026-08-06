import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/event_summary.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/pages/groups_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

Widget _wrap(MockGroupRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const GroupsListPage()),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => Scaffold(
          body: Text('Detalhe do grupo ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockGroupRepository repository;

  setUp(() {
    repository = MockGroupRepository();
  });

  testWidgets('grupo carregado mostra GroupCard com nome e integrantes', (
    tester,
  ) async {
    when(() => repository.listMine()).thenAnswer(
      (_) async => [
        const Group(
          id: 'g-1',
          name: 'Galera do Rolê',
          description: null,
          photoUrl: null,
          inviteCode: 'ABC12345',
          memberCount: 5,
        ),
      ],
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Galera do Rolê'), findsOneWidget);
    expect(find.text('5 integrantes'), findsOneWidget);
  });

  testWidgets(
    'grupo sem próximo rolê mostra "Sem rolês ainda" e integrante no singular',
    (tester) async {
      when(() => repository.listMine()).thenAnswer(
        (_) async => [
          const Group(
            id: 'g-1',
            name: 'Grupo Novo',
            description: null,
            photoUrl: null,
            inviteCode: 'ABC12345',
            memberCount: 1,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Sem rolês ainda'), findsOneWidget);
      expect(find.text('1 integrante'), findsOneWidget);
    },
  );

  testWidgets('grupo com foto mostra a foto no avatar', (tester) async {
    when(() => repository.listMine()).thenAnswer(
      (_) async => [
        const Group(
          id: 'g-1',
          name: 'Galera do Rolê',
          description: null,
          photoUrl: 'https://x/groups/g-1.jpg',
          inviteCode: 'ABC12345',
          memberCount: 5,
        ),
      ],
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Mesmo padrão de `change_avatar_page_test.dart` - `NetworkImage` não
    // resolve em ambiente de teste (sempre HTTP 400), exceção esperada e
    // sem relação com a asserção abaixo.
    while (tester.takeException() != null) {}

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isA<NetworkImage>());
    expect(
      (avatar.backgroundImage! as NetworkImage).url,
      'https://x/groups/g-1.jpg',
    );
  });

  testWidgets('grupo com próximo rolê mostra a data formatada', (tester) async {
    when(() => repository.listMine()).thenAnswer(
      (_) async => [
        Group(
          id: 'g-1',
          name: 'Galera do Rolê',
          description: null,
          photoUrl: null,
          inviteCode: 'ABC12345',
          memberCount: 3,
          nextEvent: EventSummary(
            id: 'e-1',
            scheduledAt: DateTime(2026, 8, 12, 20),
          ),
        ),
      ],
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Próximo rolê: 12/08'), findsOneWidget);
  });

  testWidgets('tocar no GroupCard navega para o detalhe do grupo', (
    tester,
  ) async {
    when(() => repository.listMine()).thenAnswer(
      (_) async => [
        const Group(
          id: 'g-1',
          name: 'Galera do Rolê',
          description: null,
          photoUrl: null,
          inviteCode: 'ABC12345',
          memberCount: 5,
        ),
      ],
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Galera do Rolê'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do grupo g-1'), findsOneWidget);
  });

  testWidgets('lista vazia mostra o EmptyState', (tester) async {
    when(() => repository.listMine()).thenAnswer((_) async => []);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Você ainda não participa de nenhum grupo.'),
      findsOneWidget,
    );
  });

  testWidgets('erro ao carregar mostra ErrorState e permite tentar novamente', (
    tester,
  ) async {
    when(
      () => repository.listMine(),
    ).thenThrow(const GroupRepositoryException('Falha ao carregar grupos.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Falha ao carregar grupos.'), findsOneWidget);

    when(() => repository.listMine()).thenAnswer((_) async => []);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(
      find.text('Você ainda não participa de nenhum grupo.'),
      findsOneWidget,
    );
  });
}
