import 'package:app/features/notifications/data/notification_remote_datasource.dart';
import 'package:app/features/notifications/data/notification_repository_impl.dart';
import 'package:app/features/notifications/domain/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class MockNotificationRemoteDatasource extends Mock
    implements NotificationRemoteDatasource {}

void main() {
  late MockNotificationRemoteDatasource datasource;
  late NotificationRepositoryImpl repository;

  setUp(() {
    datasource = MockNotificationRemoteDatasource();
    repository = NotificationRepositoryImpl(datasource);
  });

  group('FASE 05 - countUnread', () {
    test('repassa a contagem do datasource para o usuário correto', () async {
      when(
        () => datasource.countUnread('user-1'),
      ).thenAnswer((_) async => 7);

      final count = await repository.countUnread('user-1');

      expect(count, 7);
      verify(() => datasource.countUnread('user-1')).called(1);
    });

    test('zero notificações não lidas retorna 0, não null nem erro', () async {
      when(
        () => datasource.countUnread('user-2'),
      ).thenAnswer((_) async => 0);

      final count = await repository.countUnread('user-2');

      expect(count, 0);
    });

    test(
      'falha do PostgREST é traduzida em NotificationRepositoryException, '
      'mesmo padrão dos demais métodos deste repositório',
      () async {
        when(() => datasource.countUnread('user-1')).thenThrow(
          const PostgrestException(message: 'falhou'),
        );

        expect(
          () => repository.countUnread('user-1'),
          throwsA(isA<NotificationRepositoryException>()),
        );
      },
    );
  });
}
