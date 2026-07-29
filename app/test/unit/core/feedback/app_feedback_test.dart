import 'package:app/core/feedback/app_feedback.dart';
import 'package:app/core/feedback/feedback_model.dart';
import 'package:app/core/feedback/feedback_repository.dart';
import 'package:app/core/feedback/feedback_service.dart';
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

  setUp(() {
    repository = MockFeedbackRepository();
    AppFeedback.debugServiceOverride = FeedbackService(repository);
  });

  tearDown(() {
    AppFeedback.debugServiceOverride = null;
  });

  test('initialize() nunca lança mesmo sem PackageInfo disponível '
      '(ambiente de teste)', () async {
    await expectLater(AppFeedback.initialize(), completes);
  });

  test('submit() delega para o serviço e retorna o feedback criado', () async {
    when(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    ).thenAnswer((_) async => _feedback());

    final result = await AppFeedback.submit(userId: 'u1', message: 'ótimo!');

    expect(result.id, 'f1');
    verify(
      () => repository.submit(
        userId: 'u1',
        message: 'ótimo!',
        screenContext: null,
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    ).called(1);
  });

  test('propaga FeedbackRepositoryException do serviço', () async {
    when(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    ).thenThrow(const FeedbackRepositoryException('Falha de rede.'));

    await expectLater(
      AppFeedback.submit(userId: 'u1', message: 'ótimo!'),
      throwsA(isA<FeedbackRepositoryException>()),
    );
  });
}
