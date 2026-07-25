import 'package:app/core/feedback/feedback_model.dart';
import 'package:app/core/feedback/feedback_providers.dart';
import 'package:app/core/feedback/feedback_repository.dart';
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

void main() {
  late MockFeedbackRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFeedbackRepository();
    container = ProviderContainer(
      overrides: [feedbackRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FeedbackInitial', () {
    expect(container.read(feedbackControllerProvider), isA<FeedbackInitial>());
  });

  test('submit() bem-sucedido -> FeedbackSubmitSuccess', () async {
    when(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    ).thenAnswer((_) async => _feedback());

    await container
        .read(feedbackControllerProvider.notifier)
        .submit(userId: 'u1', message: 'ótimo app');

    expect(
      container.read(feedbackControllerProvider),
      isA<FeedbackSubmitSuccess>(),
    );
  });

  test('submit() com FeedbackRepositoryException -> FeedbackSubmitError com a '
      'mensagem original', () async {
    when(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    ).thenThrow(const FeedbackRepositoryException('Falha de rede.'));

    await container
        .read(feedbackControllerProvider.notifier)
        .submit(userId: 'u1', message: 'ótimo app');

    final status = container.read(feedbackControllerProvider);
    expect(status, isA<FeedbackSubmitError>());
    expect((status as FeedbackSubmitError).message, 'Falha de rede.');
  });

  test(
    'submit() com erro genérico -> FeedbackSubmitError com mensagem amigável',
    () async {
      when(
        () => repository.submit(
          userId: any(named: 'userId'),
          message: any(named: 'message'),
          screenContext: any(named: 'screenContext'),
          appVersion: any(named: 'appVersion'),
          environment: any(named: 'environment'),
        ),
      ).thenThrow(Exception('boom'));

      await container
          .read(feedbackControllerProvider.notifier)
          .submit(userId: 'u1', message: 'ótimo app');

      final status = container.read(feedbackControllerProvider);
      expect(status, isA<FeedbackSubmitError>());
      expect(
        (status as FeedbackSubmitError).message,
        'Não foi possível enviar seu feedback. Tente novamente.',
      );
    },
  );

  test('reset() volta ao estado FeedbackInitial após um erro', () async {
    when(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    ).thenThrow(const FeedbackRepositoryException('Falha de rede.'));

    final notifier = container.read(feedbackControllerProvider.notifier);
    await notifier.submit(userId: 'u1', message: 'ótimo app');
    expect(
      container.read(feedbackControllerProvider),
      isA<FeedbackSubmitError>(),
    );

    notifier.reset();

    expect(container.read(feedbackControllerProvider), isA<FeedbackInitial>());
  });
}
