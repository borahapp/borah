import 'dart:async';

import 'package:app/core/storage/app_storage.dart';
import 'package:app/core/storage/storage_repository.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/users/data/account_deletion_repository_impl.dart';
import 'package:app/features/users/domain/account_deletion_repository.dart';
import 'package:app/features/users/presentation/widgets/account_deletion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAccountDeletionRepository extends Mock
    implements AccountDeletionRepository {}

class MockStorageRepository extends Mock implements StorageRepository {}

Widget _wrap(
  MockAuthRepository authRepository,
  MockAccountDeletionRepository accountDeletionRepository,
) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      accountDeletionRepositoryProvider.overrideWithValue(
        accountDeletionRepository,
      ),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  AccountDeletionDialog.show(context, email: 'ana@borah.com'),
              child: const Text('Abrir exclusão'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Abrir exclusão'));
  await tester.pumpAndSettle();
}

void main() {
  late MockAuthRepository authRepository;
  late MockAccountDeletionRepository accountDeletionRepository;
  late MockStorageRepository storageRepository;

  setUp(() {
    authRepository = MockAuthRepository();
    accountDeletionRepository = MockAccountDeletionRepository();
    storageRepository = MockStorageRepository();
    AppStorage.debugServiceOverride = StorageService(storageRepository);

    when(
      () => authRepository.onAuthStateChange,
    ).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    AppStorage.debugServiceOverride = null;
  });

  testWidgets('mostra o aviso de confirmação ao abrir', (tester) async {
    await tester.pumpWidget(_wrap(authRepository, accountDeletionRepository));
    await _openDialog(tester);

    expect(find.text('Excluir conta'), findsOneWidget);
    expect(find.textContaining('Esta ação é permanente'), findsOneWidget);
  });

  testWidgets('cancelar no aviso fecha o diálogo sem chamar nada', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(authRepository, accountDeletionRepository));
    await _openDialog(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(
      () => authRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('continuar revela o campo de senha', (tester) async {
    await tester.pumpWidget(_wrap(authRepository, accountDeletionRepository));
    await _openDialog(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Confirme sua senha'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('tocar em Excluir minha conta com senha vazia não chama nada', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(authRepository, accountDeletionRepository));
    await _openDialog(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Continuar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Excluir minha conta'));
    await tester.pumpAndSettle();

    verifyNever(
      () => authRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('senha incorreta mostra erro inline e permite nova tentativa', (
    tester,
  ) async {
    when(
      () => authRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthRepositoryException('Senha incorreta.'));

    await tester.pumpWidget(_wrap(authRepository, accountDeletionRepository));
    await _openDialog(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'errada');
    await tester.tap(find.widgetWithText(TextButton, 'Excluir minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('Senha incorreta.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets(
    'exclusão bem-sucedida mostra carregamento, fecha o diálogo e exibe '
    'snackbar',
    (tester) async {
      final signInCompleter = Completer<void>();
      when(
        () => authRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => signInCompleter.future);
      when(
        () => accountDeletionRepository.deleteOwnAccount(),
      ).thenAnswer((_) async {});
      when(() => authRepository.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(authRepository, accountDeletionRepository));
      await _openDialog(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Continuar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'certa');
      await tester.tap(find.widgetWithText(TextButton, 'Excluir minha conta'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      signInCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Sua conta foi excluída.'), findsOneWidget);
    },
  );

  testWidgets('falha na exclusão mostra erro inline e permite nova tentativa', (
    tester,
  ) async {
    when(
      () => authRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => accountDeletionRepository.deleteOwnAccount(),
    ).thenThrow(const AccountDeletionRepositoryException('Falha no servidor.'));

    await tester.pumpWidget(_wrap(authRepository, accountDeletionRepository));
    await _openDialog(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'certa');
    await tester.tap(find.widgetWithText(TextButton, 'Excluir minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('Falha no servidor.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
