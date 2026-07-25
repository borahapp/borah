import 'dart:async';

import 'package:app/core/feedback/feedback_dialog.dart';
import 'package:app/core/feedback/feedback_model.dart';
import 'package:app/core/feedback/feedback_providers.dart';
import 'package:app/core/feedback/feedback_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

FeedbackModel _feedback() {
  return FeedbackModel(
    id: 'f1',
    userId: 'u1',
    message: 'ok',
    status: 'new',
    createdAt: DateTime.utc(2026, 7, 25),
  );
}

Widget _wrap(MockFeedbackRepository repository) {
  return ProviderScope(
    overrides: [feedbackRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => FeedbackDialog.show(context, userId: 'u1'),
              child: const Text('Abrir feedback'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Abrir feedback'));
  await tester.pumpAndSettle();
}

void main() {
  late MockFeedbackRepository repository;

  setUp(() {
    repository = MockFeedbackRepository();
  });

  testWidgets('exibe campo de mensagem com contador de caracteres', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await _openDialog(tester);

    expect(find.text('Enviar feedback'), findsOneWidget);
    expect(find.text('Sua mensagem'), findsOneWidget);
    expect(find.text('0/500'), findsOneWidget);
  });

  testWidgets('tocar em Enviar com mensagem vazia não chama o repositório', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await _openDialog(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Enviar'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    );
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets(
    'envio bem-sucedido mostra carregamento, fecha o diálogo e exibe snackbar',
    (tester) async {
      final completer = Completer<FeedbackModel>();
      when(
        () => repository.submit(
          userId: any(named: 'userId'),
          message: any(named: 'message'),
          screenContext: any(named: 'screenContext'),
          appVersion: any(named: 'appVersion'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(_wrap(repository));
      await _openDialog(tester);

      await tester.enterText(find.byType(TextFormField), 'Muito bom!');
      await tester.tap(find.widgetWithText(TextButton, 'Enviar'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_feedback());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Feedback enviado. Obrigado!'), findsOneWidget);
    },
  );

  testWidgets(
    'falha no envio mantém o diálogo aberto, mostra erro e permite nova '
    'tentativa',
    (tester) async {
      when(
        () => repository.submit(
          userId: any(named: 'userId'),
          message: any(named: 'message'),
          screenContext: any(named: 'screenContext'),
          appVersion: any(named: 'appVersion'),
          environment: any(named: 'environment'),
        ),
      ).thenThrow(const FeedbackRepositoryException('Falha de rede.'));

      await tester.pumpWidget(_wrap(repository));
      await _openDialog(tester);

      await tester.enterText(find.byType(TextFormField), 'Muito bom!');
      await tester.tap(find.widgetWithText(TextButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Falha de rede.'), findsOneWidget);

      when(
        () => repository.submit(
          userId: any(named: 'userId'),
          message: any(named: 'message'),
          screenContext: any(named: 'screenContext'),
          appVersion: any(named: 'appVersion'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async => _feedback());

      await tester.tap(find.widgetWithText(TextButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('cancelar fecha o diálogo sem chamar o repositório', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository));
    await _openDialog(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    );
  });
}
