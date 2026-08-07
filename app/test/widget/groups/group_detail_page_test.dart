import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_details.dart';
import 'package:app/features/groups/domain/group_member.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/pages/group_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

GroupDetails _details() {
  return GroupDetails(
    group: const Group(
      id: 'g-1',
      name: 'Amigos da Faculdade',
      description: null,
      photoUrl: null,
      inviteCode: 'ABC123',
    ),
    members: const [
      GroupMember(
        id: 'm-1',
        userId: 'user-1',
        role: 'owner',
        fullName: 'Você',
        avatarUrl: null,
      ),
    ],
  );
}

Widget _wrap(MockGroupRepository repository, {required bool justCreated}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            GroupDetailPage(groupId: 'g-1', justCreated: justCreated),
      ),
      // Stub - o próprio GroupHubPage já é testado em
      // group_hub_page_test.dart; aqui só interessa confirmar para
      // onde e com qual aba inicial a navegação acontece (FASE B,
      // Entrega 5), mesmo padrão de stub já usado em
      // events_list_page_test.dart para a rota de detalhe do rolê.
      GoRoute(
        path: '/groups/:id/hub',
        builder: (_, state) =>
            Scaffold(body: Text('Group Hub - aba ${state.extra}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      groupRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockGroupRepository repository;

  setUp(() {
    repository = MockGroupRepository();
    when(() => repository.getById(any())).thenAnswer((_) async => _details());
  });

  testWidgets(
    'justCreated=true mostra o diálogo de grupo criado uma única vez',
    (tester) async {
      await tester.pumpWidget(_wrap(repository, justCreated: true));
      await tester.pump();

      expect(find.text('Grupo criado com sucesso'), findsOneWidget);
      expect(
        find.text('Convide seus amigos para começar os rolês.'),
        findsOneWidget,
      );
      expect(find.text('Compartilhar agora'), findsOneWidget);
      expect(find.text('Agora não'), findsOneWidget);

      // Fecha o diálogo e deixa o load() (rebuild via provider) terminar -
      // não deve reaparecer mesmo com o rebuild seguinte.
      await tester.tap(find.text('Agora não'));
      await tester.pumpAndSettle();

      expect(find.text('Grupo criado com sucesso'), findsNothing);
    },
  );

  testWidgets('justCreated=false (navegação normal) nunca mostra o diálogo', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository, justCreated: false));
    await tester.pumpAndSettle();

    expect(find.text('Grupo criado com sucesso'), findsNothing);
  });

  testWidgets(
    '"Ranking do grupo" navega para o Group Hub já na aba 0 (Ranking) '
    '(FASE B, Entrega 5)',
    (tester) async {
      await tester.pumpWidget(_wrap(repository, justCreated: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ranking do grupo'));
      await tester.pumpAndSettle();

      expect(find.text('Group Hub - aba 0'), findsOneWidget);
    },
  );

  testWidgets(
    '"Estatísticas" navega para o Group Hub já na aba 1 (Estatísticas) '
    '(FASE B, Entrega 5)',
    (tester) async {
      await tester.pumpWidget(_wrap(repository, justCreated: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estatísticas'));
      await tester.pumpAndSettle();

      expect(find.text('Group Hub - aba 1'), findsOneWidget);
    },
  );

  testWidgets(
    'as 2 rotas antigas de Ranking/Estatísticas não existem mais - ambos os '
    'itens do menu continuam visíveis, levando ao Group Hub (FASE B, '
    'Entrega 5)',
    (tester) async {
      await tester.pumpWidget(_wrap(repository, justCreated: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Ranking do grupo'), findsOneWidget);
      expect(find.text('Estatísticas'), findsOneWidget);
    },
  );
}
