import 'dart:async';

import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/users/application/user_profile_controller.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:app/features/users/presentation/pages/edit_profile_page.dart';
import 'package:app/features/users/presentation/states/user_profile_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

/// Permite iniciar o widget já num estado específico de
/// `UserProfileStatus` (ex.: `ProfileLoaded`), já que `EditProfilePage`
/// não dispara nenhum carregamento próprio - ela assume que o perfil já
/// foi carregado por `ProfilePage` antes da navegação (DV-02 §4).
class _SeededUserProfileController extends UserProfileController {
  _SeededUserProfileController(this._initial);

  final UserProfileStatus _initial;

  @override
  UserProfileStatus build() => _initial;
}

UserProfile _profile({
  String fullName = 'Ana Souza',
  String bio = 'Apaixonada por gastronomia.',
  String city = 'São Paulo',
  String state = 'SP',
}) {
  return UserProfile(
    id: 'user-1',
    fullName: fullName,
    bio: bio,
    avatarUrl: null,
    city: city,
    state: state,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  MockUserProfileRepository repository, {
  required UserProfileStatus initialStatus,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/profile/edit'),
            child: const Text('Profile Page'),
          ),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/avatar',
        builder: (_, _) => const Scaffold(body: Text('Change Avatar Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userProfileRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('user-1'),
      userProfileControllerProvider.overrideWith(
        () => _SeededUserProfileController(initialStatus),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _openEditProfile(WidgetTester tester) async {
  await tester.tap(find.text('Profile Page'));
  await tester.pumpAndSettle();
}

void main() {
  late MockUserProfileRepository repository;

  setUp(() {
    repository = MockUserProfileRepository();
  });

  testWidgets(
    'renderização inicial mostra o formulário mesmo sem perfil carregado',
    (tester) async {
      await tester.pumpWidget(
        _wrap(repository, initialStatus: const ProfileInitial()),
      );
      await _openEditProfile(tester);

      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Biografia'), findsOneWidget);
      expect(find.text('Cidade'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Alterar foto'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Salvar'), findsOneWidget);
    },
  );

  testWidgets('formulário preenchido a partir do perfil carregado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openEditProfile(tester);

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Apaixonada por gastronomia.'), findsOneWidget);
    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('SP'), findsOneWidget);
  });

  testWidgets('validação exige o preenchimento do nome', (tester) async {
    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openEditProfile(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    verifyNever(
      () => repository.updateProfile(
        any(),
        fullName: any(named: 'fullName'),
        bio: any(named: 'bio'),
        city: any(named: 'city'),
        stateProvince: any(named: 'stateProvince'),
      ),
    );
  });

  testWidgets(
    'salvar envia os dados do formulário e volta ao concluir com sucesso',
    (tester) async {
      when(
        () => repository.updateProfile(
          'user-1',
          fullName: any(named: 'fullName'),
          bio: any(named: 'bio'),
          city: any(named: 'city'),
          stateProvince: any(named: 'stateProvince'),
        ),
      ).thenAnswer((_) async => _profile(fullName: 'Ana Souza Atualizada'));

      await tester.pumpWidget(
        _wrap(repository, initialStatus: ProfileLoaded(_profile())),
      );
      await _openEditProfile(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Ana Souza Atualizada',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => repository.updateProfile(
          'user-1',
          fullName: captureAny(named: 'fullName'),
          bio: any(named: 'bio'),
          city: any(named: 'city'),
          stateProvince: any(named: 'stateProvince'),
        ),
      ).captured;
      expect(captured.last, 'Ana Souza Atualizada');

      // ProfileUpdateSuccess navega de volta (context.pop()).
      expect(find.text('Profile Page'), findsOneWidget);
    },
  );

  testWidgets('estado de salvamento mostra indicador no botão Salvar', (
    tester,
  ) async {
    final completer = Completer<UserProfile>();
    when(
      () => repository.updateProfile(
        'user-1',
        fullName: any(named: 'fullName'),
        bio: any(named: 'bio'),
        city: any(named: 'city'),
        stateProvince: any(named: 'stateProvince'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openEditProfile(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_profile());
    await tester.pumpAndSettle();
  });

  testWidgets('erro ao salvar mostra a mensagem retornada pelo repositório', (
    tester,
  ) async {
    when(
      () => repository.updateProfile(
        'user-1',
        fullName: any(named: 'fullName'),
        bio: any(named: 'bio'),
        city: any(named: 'city'),
        stateProvince: any(named: 'stateProvince'),
      ),
    ).thenThrow(
      const UserProfileRepositoryException('Não foi possível atualizar.'),
    );

    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openEditProfile(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível atualizar.'), findsOneWidget);
    // O erro é exibido via snackbar - o formulário continua na tela.
    expect(find.text('Editar perfil'), findsOneWidget);
  });

  testWidgets('cancelamento (voltar) não envia alterações', (tester) async {
    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openEditProfile(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Nome Não Salvo',
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Profile Page'), findsOneWidget);
    verifyNever(
      () => repository.updateProfile(
        any(),
        fullName: any(named: 'fullName'),
        bio: any(named: 'bio'),
        city: any(named: 'city'),
        stateProvince: any(named: 'stateProvince'),
      ),
    );
  });

  testWidgets('tocar em "Alterar foto" navega para a troca de avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openEditProfile(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Alterar foto'));
    await tester.pumpAndSettle();

    expect(find.text('Change Avatar Page'), findsOneWidget);
  });

  group('responsividade', () {
    for (final size in [
      const Size(320, 640),
      const Size(412, 915),
      const Size(768, 1024),
    ]) {
      testWidgets('renderiza sem overflow em ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(repository, initialStatus: ProfileLoaded(_profile())),
        );
        await _openEditProfile(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('Ana Souza'), findsOneWidget);
      });
    }
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openEditProfile(tester);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });
}
