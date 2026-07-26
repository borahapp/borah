import 'dart:async';

import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/authentication/presentation/pages/new_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget _wrap(MockAuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: NewPasswordPage()),
  );
}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthSessionUpdate>.empty());
  });

  testWidgets('renderização inicial mostra os campos e as ações', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Definir nova senha'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.widgetWithText(FilledButton, 'Salvar nova senha'),
      findsOneWidget,
    );
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets(
    'senha muito curta exibe erro de validação e não chama updatePassword',
    (tester) async {
      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '123');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar nova senha'));
      await tester.pumpAndSettle();

      expect(
        find.text('A senha deve ter ao menos 6 caracteres.'),
        findsOneWidget,
      );
      verifyNever(() => repository.updatePassword(any()));
    },
  );

  testWidgets(
    'senhas diferentes exibem erro de validação e não chamam updatePassword',
    (tester) async {
      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'senhaForte1');
      await tester.enterText(find.byType(TextFormField).at(1), 'outraSenha2');
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar nova senha'));
      await tester.pumpAndSettle();

      expect(find.text('As senhas não coincidem.'), findsOneWidget);
      verifyNever(() => repository.updatePassword(any()));
    },
  );

  testWidgets('estado de carregamento mostra indicador no botão', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(
      () => repository.updatePassword(any()),
    ).thenAnswer((_) => completer.future);
    when(
      () => repository.currentUser,
    ).thenReturn((userId: 'user-1', email: 'ana@borah.com'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'senhaForte1');
    await tester.enterText(find.byType(TextFormField).at(1), 'senhaForte1');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar nova senha'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('falha ao definir a nova senha exibe snackbar com a mensagem', (
    tester,
  ) async {
    when(() => repository.updatePassword(any())).thenThrow(
      const AuthRepositoryException(
        'A nova senha deve ser diferente da senha atual.',
      ),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'senhaForte1');
    await tester.enterText(find.byType(TextFormField).at(1), 'senhaForte1');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar nova senha'));
    await tester.pumpAndSettle();

    expect(
      find.text('A nova senha deve ser diferente da senha atual.'),
      findsOneWidget,
    );
  });

  testWidgets('"Cancelar" encerra a sessão de recuperação', (tester) async {
    when(() => repository.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verify(() => repository.signOut()).called(1);
  });
}
