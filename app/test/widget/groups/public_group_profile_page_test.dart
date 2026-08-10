import 'package:app/features/groups/data/group_repository_impl.dart';
import 'package:app/features/groups/domain/group.dart';
import 'package:app/features/groups/domain/group_repository.dart';
import 'package:app/features/groups/presentation/pages/public_group_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

Group _group({
  String id = 'g-1',
  String name = 'Os Exploradores',
  String? description = 'Rolês de fim de semana.',
  int memberCount = 12,
}) {
  return Group(
    id: id,
    name: name,
    description: description,
    photoUrl: null,
    inviteCode: 'ABCDEFGH',
    visibility: 'public',
    memberCount: memberCount,
  );
}

Widget _wrap(MockGroupRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const PublicGroupProfilePage(groupId: 'g-1'),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => Scaffold(
          body: Text('Group Detail Page ${state.pathParameters['id']}'),
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

  testWidgets('mostra nome, descrição, contagem de membros e badge Público', (
    tester,
  ) async {
    when(
      () => repository.getPublicSummary('g-1'),
    ).thenAnswer((_) async => _group());

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Os Exploradores'), findsOneWidget);
    expect(find.text('Rolês de fim de semana.'), findsOneWidget);
    expect(find.text('12 membros'), findsOneWidget);
    expect(find.text('Público'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('tocar em Entrar navega para o Detalhe do grupo', (tester) async {
    when(
      () => repository.getPublicSummary('g-1'),
    ).thenAnswer((_) async => _group());
    when(
      () => repository.joinPublicGroup('g-1'),
    ).thenAnswer((_) async => _group());

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Group Detail Page g-1'), findsOneWidget);
  });

  testWidgets('falha ao entrar mostra snackbar e permanece na tela', (
    tester,
  ) async {
    when(
      () => repository.getPublicSummary('g-1'),
    ).thenAnswer((_) async => _group());
    when(
      () => repository.joinPublicGroup('g-1'),
    ).thenThrow(const GroupRepositoryException('Este grupo não é público.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Este grupo não é público.'), findsOneWidget);
    expect(find.text('Os Exploradores'), findsOneWidget);
  });

  testWidgets('erro ao carregar mostra mensagem de erro', (tester) async {
    when(
      () => repository.getPublicSummary('g-1'),
    ).thenThrow(const GroupRepositoryException('Grupo não encontrado.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o grupo.'), findsOneWidget);
  });
}
