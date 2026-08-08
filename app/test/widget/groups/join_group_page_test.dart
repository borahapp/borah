import 'package:app/core/deep_link/deep_link.dart';
import 'package:app/features/groups/application/pending_invite_controller.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/pages/join_group_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

Widget _wrap(MockGroupRepository repository, {ProviderContainer? container}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/groups/join'),
            child: const Text('Abrir entrar em grupo'),
          ),
        ),
      ),
      GoRoute(path: '/groups/join', builder: (_, _) => const JoinGroupPage()),
    ],
  );

  if (container != null) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  return ProviderScope(
    overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpAndOpen(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Abrir entrar em grupo'));
  await tester.pumpAndSettle();
}

void main() {
  late MockGroupRepository repository;

  setUp(() {
    repository = MockGroupRepository();
  });

  testWidgets('sem convite pendente, o campo de código começa vazio', (
    tester,
  ) async {
    await _pumpAndOpen(tester, _wrap(repository));

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text, isEmpty);
  });

  testWidgets(
    'com convite pendente, o campo já vem preenchido e o convite é consumido',
    (tester) async {
      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container
          .read(pendingInviteControllerProvider.notifier)
          .receive(const GroupJoinDeepLink(inviteCode: 'ABCD1234'));

      await _pumpAndOpen(tester, _wrap(repository, container: container));

      expect(find.text('ABCD1234'), findsOneWidget);
      // Consumido (não fica reaplicável se a tela for reaberta depois).
      expect(
        container.read(pendingInviteControllerProvider.notifier).existe,
        isFalse,
      );
    },
  );

  testWidgets(
    'preenchido (manualmente ou pré-preenchido), tocar em Entrar chama o repositório',
    (tester) async {
      when(() => repository.joinByInviteCode('ABCD1234')).thenAnswer(
        (_) async => const Group(
          id: 'g-1',
          name: 'Galera do Rolê',
          description: null,
          photoUrl: null,
          inviteCode: 'ABCD1234',
        ),
      );

      await _pumpAndOpen(tester, _wrap(repository));

      await tester.enterText(find.byType(TextFormField), 'ABCD1234');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      verify(() => repository.joinByInviteCode('ABCD1234')).called(1);
      expect(
        find.text('Você entrou no grupo "Galera do Rolê".'),
        findsOneWidget,
      );
    },
  );

  group('FASE C.3 - navegação ao concluir (pop() sem rota anterior)', () {
    testWidgets(
      'entrada via push (navegação interna): sucesso usa pop() e volta '
      'para a tela anterior',
      (tester) async {
        when(() => repository.joinByInviteCode('ABCD1234')).thenAnswer(
          (_) async => const Group(
            id: 'g-1',
            name: 'Galera do Rolê',
            description: null,
            photoUrl: null,
            inviteCode: 'ABCD1234',
          ),
        );

        await _pumpAndOpen(tester, _wrap(repository));
        expect(find.text('Abrir entrar em grupo'), findsNothing);

        await tester.enterText(find.byType(TextFormField), 'ABCD1234');
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        // pop() de volta à tela que empilhou `/groups/join` - prova de
        // que a navegação por push continua intacta, sem regressão.
        expect(find.text('Abrir entrar em grupo'), findsOneWidget);
      },
    );

    testWidgets(
      'entrada via Deep Link (pilha vazia): sucesso não lança exceção e '
      'usa o fallback (/home) em vez de pop()',
      (tester) async {
        when(() => repository.joinByInviteCode('ABCD1234')).thenAnswer(
          (_) async => const Group(
            id: 'g-1',
            name: 'Galera do Rolê',
            description: null,
            photoUrl: null,
            inviteCode: 'ABCD1234',
          ),
        );

        // Mesmo formato que o `redirect` de app_router.dart produz para
        // quem chega por Deep Link: `/groups/join` é a ÚNICA rota - sem
        // nenhuma rota anterior para `pop()` voltar.
        final router = GoRouter(
          initialLocation: '/groups/join',
          routes: [
            GoRoute(
              path: '/groups/join',
              builder: (_, _) => const JoinGroupPage(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, _) =>
                  const Scaffold(body: Text('Home (fallback)')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [groupRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'ABCD1234');
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Home (fallback)'), findsOneWidget);
      },
    );
  });
}
