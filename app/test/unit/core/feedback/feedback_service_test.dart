import 'package:app/core/feedback/feedback_model.dart';
import 'package:app/core/feedback/feedback_repository.dart';
import 'package:app/core/feedback/feedback_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

FeedbackModel _feedback({String message = 'ok'}) {
  return FeedbackModel(
    id: 'f1',
    userId: 'u1',
    message: message,
    status: 'new',
    createdAt: DateTime.utc(2026, 7, 25),
  );
}

void main() {
  late MockFeedbackRepository repository;
  late FeedbackService service;

  setUp(() {
    repository = MockFeedbackRepository();
    service = FeedbackService(repository);

    registerFallbackValue('');
    when(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    ).thenAnswer((_) async => _feedback());
  });

  test('sanitiza a mensagem (PII) antes de repassar ao repositório', () async {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dQw4w9WgXcQ';

    await service.submit(
      userId: 'u1',
      message: 'token: $jwt',
      screenContext: 'settings',
    );

    final captured =
        verify(
              () => repository.submit(
                userId: 'u1',
                message: captureAny(named: 'message'),
                screenContext: 'settings',
                appVersion: any(named: 'appVersion'),
                environment: any(named: 'environment'),
              ),
            ).captured.single
            as String;

    expect(captured, isNot(contains(jwt)));
    expect(captured, contains('[REDACTED]'));
  });

  test('repassa userId e screenContext inalterados ao repositório', () async {
    await service.submit(
      userId: 'u42',
      message: 'sem dado sensível',
      screenContext: 'feed',
    );

    verify(
      () => repository.submit(
        userId: 'u42',
        message: 'sem dado sensível',
        screenContext: 'feed',
        appVersion: any(named: 'appVersion'),
        environment: any(named: 'environment'),
      ),
    ).called(1);
  });

  test('appVersion é null antes de initializeAppVersion() ter sido chamado '
      '(RC-03E: nunca lido via plugin durante submit)', () async {
    await service.submit(userId: 'u1', message: 'msg');

    verify(
      () => repository.submit(
        userId: any(named: 'userId'),
        message: any(named: 'message'),
        screenContext: any(named: 'screenContext'),
        appVersion: null,
        environment: any(named: 'environment'),
      ),
    ).called(1);
  });

  test('initializeAppVersion() nunca lança mesmo sem PackageInfo disponível '
      '(ambiente de teste)', () async {
    await expectLater(FeedbackService.initializeAppVersion(), completes);
  });

  test('propaga FeedbackRepositoryException do repositório', () async {
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
      service.submit(userId: 'u1', message: 'msg'),
      throwsA(isA<FeedbackRepositoryException>()),
    );
  });
}
