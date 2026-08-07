import 'package:app/core/deep_link/deep_link.dart';
import 'package:app/features/groups/application/pending_invite_controller.dart';
import 'package:app/features/groups/presentation/states/pending_invite_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  PendingInviteController controller() =>
      container.read(pendingInviteControllerProvider.notifier);

  test('estado inicial é NoPendingInvite', () {
    expect(
      container.read(pendingInviteControllerProvider),
      isA<NoPendingInvite>(),
    );
    expect(controller().existe, isFalse);
    expect(controller().codigo, isNull);
  });

  test('receive com GroupJoinDeepLink guarda o código', () {
    controller().receive(const GroupJoinDeepLink(inviteCode: 'ABCD1234'));

    expect(controller().existe, isTrue);
    expect(controller().codigo, 'ABCD1234');
  });

  test('receive com um DeepLink que não é seu é ignorado silenciosamente', () {
    controller().receive(UnknownDeepLink(uri: Uri.parse('borah://x/y')));

    expect(controller().existe, isFalse);
    expect(controller().codigo, isNull);
  });

  test('consumir() devolve o código e limpa o estado', () {
    controller().receive(const GroupJoinDeepLink(inviteCode: 'ABCD1234'));

    final code = controller().consumir();

    expect(code, 'ABCD1234');
    expect(controller().existe, isFalse);
    expect(controller().codigo, isNull);
  });

  test('consumir() sem nada pendente devolve null', () {
    expect(controller().consumir(), isNull);
  });

  test('limpar() descarta sem devolver nada', () {
    controller().receive(const GroupJoinDeepLink(inviteCode: 'ABCD1234'));

    controller().limpar();

    expect(controller().existe, isFalse);
    expect(controller().codigo, isNull);
  });

  test('um novo receive substitui o código pendente anterior', () {
    controller().receive(const GroupJoinDeepLink(inviteCode: 'AAAA'));
    controller().receive(const GroupJoinDeepLink(inviteCode: 'BBBB'));

    expect(controller().codigo, 'BBBB');
  });
}
