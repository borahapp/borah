import 'package:app/features/users/data/account_deletion_remote_datasource.dart';
import 'package:app/features/users/data/account_deletion_repository_impl.dart';
import 'package:app/features/users/domain/account_deletion_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class MockAccountDeletionRemoteDatasource extends Mock
    implements AccountDeletionRemoteDatasource {}

void main() {
  late MockAccountDeletionRemoteDatasource datasource;
  late AccountDeletionRepositoryImpl repository;

  setUp(() {
    datasource = MockAccountDeletionRemoteDatasource();
    repository = AccountDeletionRepositoryImpl(datasource);
  });

  test('deleteOwnAccount() delega para o datasource', () async {
    when(() => datasource.deleteOwnAccount()).thenAnswer((_) async {});

    await repository.deleteOwnAccount();

    verify(() => datasource.deleteOwnAccount()).called(1);
  });

  test(
    'traduz PostgrestException para AccountDeletionRepositoryException',
    () async {
      when(() => datasource.deleteOwnAccount()).thenThrow(
        const PostgrestException(message: 'Usuário não autenticado.'),
      );

      await expectLater(
        repository.deleteOwnAccount(),
        throwsA(isA<AccountDeletionRepositoryException>()),
      );
    },
  );
}
