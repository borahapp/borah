import 'dart:async';

import 'package:app/features/administration/data/admin_role_repository_impl.dart';
import 'package:app/features/administration/domain/admin_role_repository.dart';
import 'package:app/features/administration/presentation/widgets/admin_guard.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRoleRepository extends Mock implements AdminRoleRepository {}

/// RC-04A - Security Hardening: `AdminGuard` nunca teve teste próprio
/// até agora (achado da auditoria de permissões administrativas) -
/// ele é a ÚNICA barreira do lado do cliente que impede uma tela
/// administrativa de renderizar seu conteúdo (`child`) para quem não é
/// administrador. A autorização real continua sendo garantida pela RLS
/// de `user_roles`/`is_admin()` (ver `current_user_role_provider_test.dart`
/// e a suíte de RLS em `supabase/tests/database/`) - este teste cobre
/// apenas o comportamento de apresentação: qual estado é mostrado para
/// cada resultado possível de `currentUserRoleProvider`.
Widget _wrap(MockAdminRoleRepository repository, {String? userId = 'user-1'}) {
  return ProviderScope(
    overrides: [
      adminRoleRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(userId),
    ],
    child: MaterialApp(
      home: AdminGuard(child: const Text('Conteúdo administrativo')),
    ),
  );
}

void main() {
  late MockAdminRoleRepository repository;

  setUp(() {
    repository = MockAdminRoleRepository();
  });

  testWidgets('enquanto carrega, mostra a tela de carregamento e não '
      'renderiza o conteúdo protegido', (tester) async {
    final completer = Completer<String?>();
    when(
      () => repository.getRole('user-1'),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Conteúdo administrativo'), findsNothing);

    completer.complete('admin');
    await tester.pumpAndSettle();
  });

  testWidgets('em caso de erro ao verificar o papel, mostra mensagem e '
      'não renderiza o conteúdo protegido', (tester) async {
    when(() => repository.getRole('user-1')).thenThrow(Exception('falhou'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível verificar permissões.'), findsOneWidget);
    expect(find.text('Conteúdo administrativo'), findsNothing);
  });

  testWidgets(
    'usuário sem papel administrativo (role null) nunca vê o conteúdo '
    'protegido - a RLS de user_roles nega a leitura, mas o guard também '
    'não deve exibir a tela mesmo que a consulta retornasse algo',
    (tester) async {
      when(() => repository.getRole('user-1')).thenAnswer((_) async => null);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Acesso restrito a administradores.'), findsOneWidget);
      expect(find.text('Conteúdo administrativo'), findsNothing);
    },
  );

  for (final role in ['super_admin', 'admin', 'moderator', 'support']) {
    testWidgets(
      'usuário com papel "$role" vê o conteúdo protegido normalmente',
      (tester) async {
        when(() => repository.getRole('user-1')).thenAnswer((_) async => role);

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        expect(find.text('Conteúdo administrativo'), findsOneWidget);
      },
    );
  }

  testWidgets('sem usuário logado (currentUserIdProvider nulo), nunca vê o '
      'conteúdo protegido, sem sequer consultar o repositório', (tester) async {
    await tester.pumpWidget(_wrap(repository, userId: null));
    await tester.pumpAndSettle();

    expect(find.text('Acesso restrito a administradores.'), findsOneWidget);
    expect(find.text('Conteúdo administrativo'), findsNothing);
    verifyNever(() => repository.getRole(any()));
  });
}
