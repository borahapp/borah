import 'package:app/app.dart';
import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('Sem sessão salva, a Splash redireciona para o Login', (
    tester,
  ) async {
    final repository = MockAuthRepository();
    when(() => repository.currentUser).thenReturn(null);
    when(
      () => repository.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthUserData?>.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const BorahApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BORAH'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
