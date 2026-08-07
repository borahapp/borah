import 'package:app/app.dart';
import 'package:app/core/deep_link/deep_link.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/authentication/data/auth_repository_impl.dart';
import 'package:app/features/authentication/domain/auth_repository.dart';
import 'package:app/features/authentication/presentation/states/auth_status.dart';
import 'package:app/features/groups/application/pending_invite_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Simula um usuário já autenticado sem depender de nenhum repositório
/// real - `build()`/`restoreSession()` sobrescritos, mesmo padrão de
/// dublê já usado para `MockAuthRepository`, só que substituindo o
/// controller inteiro (mais simples aqui, onde o único interesse é o
/// `AuthStatus` resultante, não o fluxo de restauração em si).
class _FakeAuthenticatedController extends AuthController {
  @override
  AuthStatus build() =>
      const Authenticated(userId: 'user-1', email: 'user@teste.com');

  @override
  Future<void> restoreSession() async {}
}

void main() {
  testWidgets('Sem sessão salva, a Splash redireciona para o Login', (
    tester,
  ) async {
    final repository = MockAuthRepository();
    when(() => repository.currentUser).thenReturn(null);
    when(
      () => repository.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthSessionUpdate>.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const BorahApp(),
      ),
    );
    await tester.pumpAndSettle();

    // IV-04: logo oficial (SVG) no lugar do texto "BORAH".
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets(
    'RC-03A: rota desconhecida mostra ErrorState em vez de quebrar o app',
    (tester) async {
      final repository = MockAuthRepository();
      when(() => repository.currentUser).thenReturn(null);
      when(
        () => repository.onAuthStateChange,
      ).thenAnswer((_) => const Stream<AuthSessionUpdate>.empty());

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BorahApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/rota-que-nao-existe');
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível abrir esta tela.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Login com convite pendente redireciona para "Entrar em grupo", não Home',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthenticatedController.new),
        ],
      );
      addTearDown(container.dispose);

      // Mesmo efeito de DeepLinkDispatcher chamando receive() - sem
      // precisar de nenhum transporte real neste teste, só o resultado
      // que ele produziria.
      container
          .read(pendingInviteControllerProvider.notifier)
          .receive(const GroupJoinDeepLink(inviteCode: 'ABCD1234'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BorahApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entrar em grupo'), findsOneWidget);
      expect(find.text('ABCD1234'), findsOneWidget);
    },
  );

  testWidgets(
    'Convite pendente chegando depois do app já assentado na Home também redireciona',
    (tester) async {
      // Regressão do achado nº1 da auditoria de infraestrutura de Deep
      // Link: diferente do teste acima (que já pré-carrega o convite
      // antes do primeiro pump), este simula a chegada tardia de um
      // Deep Link - app já parado numa tela, sem nenhuma navegação
      // explícita acontecendo. Sem _GoRouterRefreshNotifier escutar
      // pendingInviteControllerProvider, esta mudança de estado nunca
      // reavaliaria o redirect - o teste falharia antes da correção.
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthenticatedController.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BorahApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Assentado em algum lugar que não é "Entrar em grupo" - sem
      // nenhum convite pendente ainda.
      expect(find.text('Entrar em grupo'), findsNothing);

      // Mesmo efeito de um Deep Link chegando agora, com o app já
      // aberto e parado (uriLinkStream, não getInitialLink) - nenhuma
      // chamada de navegação explícita a seguir.
      container
          .read(pendingInviteControllerProvider.notifier)
          .receive(const GroupJoinDeepLink(inviteCode: 'LATE1234'));
      await tester.pumpAndSettle();

      expect(find.text('Entrar em grupo'), findsOneWidget);
      expect(find.text('LATE1234'), findsOneWidget);
    },
  );
}
