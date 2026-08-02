import 'package:app/design_system/components/buttons/app_primary_button.dart';
import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/pages/create_group_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

Group _group({String id = 'g-1', String name = 'Amigos da Faculdade'}) {
  return Group(
    id: id,
    name: name,
    description: null,
    photoUrl: null,
    inviteCode: 'ABC123',
  );
}

Widget _wrap(MockGroupRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CreateGroupPage()),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => Scaffold(
          body: Text(
            'Group Detail Page ${state.pathParameters['id']} '
            'justCreated=${state.extra}',
          ),
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

  testWidgets(
    'criação com sucesso navega direto para o Detalhe do Grupo, sem snackbar',
    (tester) async {
      when(
        () => repository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
        ),
      ).thenAnswer((_) async => _group());

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Novo Grupo');
      await tester.tap(find.widgetWithText(AppPrimaryButton, 'Criar grupo'));
      await tester.pumpAndSettle();

      // UX-01: vai direto para o detalhe, com o sinal de "acabou de ser
      // criado" - não fecha a tela (pop) nem mostra snackbar de sucesso.
      expect(
        find.text('Group Detail Page g-1 justCreated=true'),
        findsOneWidget,
      );
      expect(find.text('Criar grupo'), findsNothing);
      expect(find.textContaining('criado.'), findsNothing);
    },
  );

  testWidgets('falha na criação mostra snackbar e permanece na tela', (
    tester,
  ) async {
    when(
      () => repository.create(
        name: any(named: 'name'),
        description: any(named: 'description'),
        photoUrl: any(named: 'photoUrl'),
      ),
    ).thenThrow(const GroupRepositoryException('Nome inválido.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Novo Grupo');
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Criar grupo'));
    await tester.pumpAndSettle();

    expect(find.text('Nome inválido.'), findsOneWidget);
    expect(find.text('Group Detail Page g-1 justCreated=true'), findsNothing);
  });
}
