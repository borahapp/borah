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

const _group = Group(
  id: 'g-1',
  name: 'Amigos da Faculdade',
  description: null,
  photoUrl: null,
  inviteCode: 'ABC123',
);

GroupDetails _details() {
  return const GroupDetails(
    group: _group,
    members: [
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

/// FASE C.1: owner (`user-1`) com outro membro no grupo - caso em que a
/// saída é "Transferir propriedade", não "Excluir grupo".
GroupDetails _detailsWithTwoMembers() {
  return const GroupDetails(
    group: _group,
    members: [
      GroupMember(
        id: 'm-1',
        userId: 'user-1',
        role: 'owner',
        fullName: 'Você',
        avatarUrl: null,
      ),
      GroupMember(
        id: 'm-2',
        userId: 'user-2',
        role: 'member',
        fullName: 'Bruno Costa',
        avatarUrl: null,
      ),
    ],
  );
}

/// FASE C.1: usuário atual (`user-1`) é admin, não owner - não deve ver
/// "Transferir propriedade" em nenhuma linha.
GroupDetails _detailsAsAdmin() {
  return const GroupDetails(
    group: _group,
    members: [
      GroupMember(
        id: 'm-1',
        userId: 'user-owner',
        role: 'owner',
        fullName: 'Dono',
        avatarUrl: null,
      ),
      GroupMember(
        id: 'm-2',
        userId: 'user-1',
        role: 'admin',
        fullName: 'Você',
        avatarUrl: null,
      ),
      GroupMember(
        id: 'm-3',
        userId: 'user-3',
        role: 'member',
        fullName: 'Carla',
        avatarUrl: null,
      ),
    ],
  );
}

/// FASE C.1: usuário atual (`user-1`) é membro comum - não deve ver
/// nenhum dos 2 itens novos em lugar nenhum.
GroupDetails _detailsAsMember() {
  return const GroupDetails(
    group: _group,
    members: [
      GroupMember(
        id: 'm-1',
        userId: 'user-owner',
        role: 'owner',
        fullName: 'Dono',
        avatarUrl: null,
      ),
      GroupMember(
        id: 'm-2',
        userId: 'user-1',
        role: 'member',
        fullName: 'Você',
        avatarUrl: null,
      ),
      GroupMember(
        id: 'm-3',
        userId: 'user-3',
        role: 'member',
        fullName: 'Carla',
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

  group('FASE C.1 - transferir propriedade', () {
    testWidgets('owner com outros membros: "Transferir propriedade" aparece na '
        'linha do outro membro; "Sair do grupo" e "Excluir grupo" '
        'continuam ausentes no menu do topo', (tester) async {
      when(
        () => repository.getById(any()),
      ).thenAnswer((_) async => _detailsWithTwoMembers());

      await tester.pumpWidget(_wrap(repository, justCreated: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      expect(find.text('Sair do grupo'), findsNothing);
      expect(find.text('Excluir grupo'), findsNothing);

      // Fecha o menu do topo tocando fora dele.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final memberTile = find.widgetWithText(ListTile, 'Bruno Costa');
      await tester.tap(
        find.descendant(
          of: memberTile,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transferir propriedade'), findsOneWidget);
    });

    testWidgets('tocar em "Transferir propriedade" pede confirmação e, ao '
        'confirmar, chama o repository', (tester) async {
      when(
        () => repository.getById(any()),
      ).thenAnswer((_) async => _detailsWithTwoMembers());
      when(
        () => repository.transferOwnership(
          groupId: 'g-1',
          newOwnerMemberId: 'm-2',
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(repository, justCreated: false));
      await tester.pumpAndSettle();

      final memberTile = find.widgetWithText(ListTile, 'Bruno Costa');
      await tester.tap(
        find.descendant(
          of: memberTile,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferir propriedade'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      verifyNever(
        () => repository.transferOwnership(
          groupId: any(named: 'groupId'),
          newOwnerMemberId: any(named: 'newOwnerMemberId'),
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Transferir'),
        ),
      );
      await tester.pumpAndSettle();

      verify(
        () => repository.transferOwnership(
          groupId: 'g-1',
          newOwnerMemberId: 'm-2',
        ),
      ).called(1);
    });

    testWidgets('admin (não-owner) não vê "Transferir propriedade" na linha de '
        'outro membro', (tester) async {
      when(
        () => repository.getById(any()),
      ).thenAnswer((_) async => _detailsAsAdmin());

      await tester.pumpWidget(_wrap(repository, justCreated: false));
      await tester.pumpAndSettle();

      final memberTile = find.widgetWithText(ListTile, 'Carla');
      await tester.tap(
        find.descendant(
          of: memberTile,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transferir propriedade'), findsNothing);
      expect(find.text('Remover do grupo'), findsOneWidget);
    });
  });

  group('FASE C.1 - excluir grupo', () {
    testWidgets(
      'owner sozinho no grupo: "Excluir grupo" aparece no menu do topo; '
      '"Sair do grupo" continua ausente',
      (tester) async {
        await tester.pumpWidget(_wrap(repository, justCreated: false));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();

        expect(find.text('Excluir grupo'), findsOneWidget);
        expect(find.text('Sair do grupo'), findsNothing);
      },
    );

    testWidgets('owner com outros membros: "Excluir grupo" não aparece', (
      tester,
    ) async {
      when(
        () => repository.getById(any()),
      ).thenAnswer((_) async => _detailsWithTwoMembers());

      await tester.pumpWidget(_wrap(repository, justCreated: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Excluir grupo'), findsNothing);
    });

    testWidgets(
      'tocar em "Excluir grupo" pede confirmação e, ao confirmar, exclui '
      'e volta para a tela anterior',
      (tester) async {
        when(() => repository.delete('g-1')).thenAnswer((_) async {});
        when(() => repository.listMine()).thenAnswer((_) async => []);

        // RC-04E (mesmo padrão de review_detail_page_test.dart): sucesso
        // navega de volta via `context.pop()` - precisa de uma pilha real
        // (empilhada com `push`, não `initialLocation`) para ter para
        // onde voltar, diferente do `_wrap()` padrão usado nos demais
        // testes deste arquivo.
        final router = GoRouter(
          initialLocation: '/list',
          routes: [
            GoRoute(
              path: '/list',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/group'),
                    child: const Text('Abrir grupo'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/group',
              builder: (_, _) => const GroupDetailPage(groupId: 'g-1'),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              groupRepositoryProvider.overrideWithValue(repository),
              currentUserIdProvider.overrideWithValue('user-1'),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abrir grupo'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir grupo'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        verifyNever(() => repository.delete(any()));

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(TextButton, 'Excluir'),
          ),
        );
        await tester.pumpAndSettle();

        verify(() => repository.delete('g-1')).called(1);
        expect(find.text('Abrir grupo'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'FASE C.1 - membro comum: nenhum item novo aparece em lugar nenhum',
    (tester) async {
      when(
        () => repository.getById(any()),
      ).thenAnswer((_) async => _detailsAsMember());

      await tester.pumpWidget(_wrap(repository, justCreated: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      expect(find.text('Excluir grupo'), findsNothing);
      expect(find.text('Sair do grupo'), findsOneWidget);

      // Fecha o menu do topo - membro comum não gerencia ninguém, então
      // nenhuma outra linha tem PopupMenuButton (nem para "Transferir
      // propriedade", nem para nada mais).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    },
  );
}
