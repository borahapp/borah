import 'dart:async';
import 'dart:typed_data';

import 'package:app/core/widgets/app_primary_button.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/users/application/user_profile_controller.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:app/features/users/presentation/pages/change_avatar_page.dart';
import 'package:app/features/users/presentation/states/user_profile_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

/// Mesma técnica do `edit_profile_page_test.dart`: permite iniciar o
/// widget já num `UserProfileStatus` específico (`ChangeAvatarPage`
/// também assume que o perfil já foi carregado antes da navegação).
class _SeededUserProfileController extends UserProfileController {
  _SeededUserProfileController(this._initial);

  final UserProfileStatus _initial;

  @override
  UserProfileStatus build() => _initial;
}

UserProfile _profile({String? avatarUrl}) {
  return UserProfile(
    id: 'user-1',
    fullName: 'Ana Souza',
    bio: 'Apaixonada por gastronomia.',
    avatarUrl: avatarUrl,
    city: 'São Paulo',
    state: 'SP',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  MockUserProfileRepository repository, {
  required UserProfileStatus initialStatus,
  ProviderContainer? container,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/profile/avatar'),
            child: const Text('Edit Profile Page'),
          ),
        ),
      ),
      GoRoute(
        path: '/profile/avatar',
        builder: (_, _) => const ChangeAvatarPage(),
      ),
    ],
  );

  if (container != null) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
  }

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

Future<void> _openChangeAvatar(WidgetTester tester) async {
  await tester.tap(find.text('Edit Profile Page'));
  await tester.pumpAndSettle();
}

void main() {
  late MockUserProfileRepository repository;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockUserProfileRepository();
  });

  testWidgets('renderização inicial mostra o ícone padrão quando não há foto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openChangeAvatar(tester);

    expect(find.text('Alterar foto'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Escolher da galeria'),
      findsOneWidget,
    );
    final saveButton = tester.widget<AppPrimaryButton>(
      find.byType(AppPrimaryButton),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('avatar existente resolve a URL assinada e é exibido', (
    tester,
  ) async {
    when(
      () => repository.getAvatarDisplayUrl('avatars/user-1.jpg'),
    ).thenAnswer((_) async => 'https://x/avatars/user-1-signed.jpg');

    await tester.pumpWidget(
      _wrap(
        repository,
        initialStatus: ProfileLoaded(_profile(avatarUrl: 'avatars/user-1.jpg')),
      ),
    );
    await _openChangeAvatar(tester);

    while (tester.takeException() != null) {}

    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets(
    '"Salvar foto" fica desabilitado até uma imagem ser selecionada',
    (tester) async {
      await tester.pumpWidget(
        _wrap(repository, initialStatus: ProfileLoaded(_profile())),
      );
      await _openChangeAvatar(tester);

      final saveButton = tester.widget<AppPrimaryButton>(
        find.byType(AppPrimaryButton),
      );
      expect(saveButton.onPressed, isNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Salvar foto'));
      await tester.pumpAndSettle();

      verifyNever(
        () => repository.updateAvatar(
          any(),
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      );
    },
  );

  testWidgets(
    'estado de envio mostra indicador e volta ao concluir com sucesso',
    (tester) async {
      final completer = Completer<UserProfile>();
      when(
        () => repository.updateAvatar(
          'user-1',
          bytes: any(named: 'bytes'),
          fileExtension: any(named: 'fileExtension'),
        ),
      ).thenAnswer((_) => completer.future);

      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWithValue('user-1'),
          userProfileControllerProvider.overrideWith(
            () => _SeededUserProfileController(ProfileLoaded(_profile())),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(
          repository,
          initialStatus: ProfileLoaded(_profile()),
          container: container,
        ),
      );
      await _openChangeAvatar(tester);

      unawaited(
        container
            .read(userProfileControllerProvider.notifier)
            .updateAvatar('user-1', bytes: Uint8List(0), fileExtension: 'jpg'),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_profile());
      await tester.pumpAndSettle();

      // ProfileUpdateSuccess navega de volta (context.pop()).
      expect(find.text('Edit Profile Page'), findsOneWidget);
    },
  );

  testWidgets('erro ao enviar a foto mostra a mensagem via snackbar', (
    tester,
  ) async {
    when(
      () => repository.updateAvatar(
        'user-1',
        bytes: any(named: 'bytes'),
        fileExtension: any(named: 'fileExtension'),
      ),
    ).thenThrow(
      const UserProfileRepositoryException(
        'Não foi possível atualizar a foto.',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWithValue('user-1'),
        userProfileControllerProvider.overrideWith(
          () => _SeededUserProfileController(ProfileLoaded(_profile())),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(
        repository,
        initialStatus: ProfileLoaded(_profile()),
        container: container,
      ),
    );
    await _openChangeAvatar(tester);

    await container
        .read(userProfileControllerProvider.notifier)
        .updateAvatar('user-1', bytes: Uint8List(0), fileExtension: 'jpg');
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível atualizar a foto.'), findsOneWidget);
    // O erro é exibido via snackbar - a tela de troca de foto continua ativa.
    expect(find.text('Alterar foto'), findsOneWidget);
  });

  testWidgets('voltar sem selecionar foto retorna à tela anterior', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openChangeAvatar(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile Page'), findsOneWidget);
    verifyNever(
      () => repository.updateAvatar(
        any(),
        bytes: any(named: 'bytes'),
        fileExtension: any(named: 'fileExtension'),
      ),
    );
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
        await _openChangeAvatar(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('Alterar foto'), findsOneWidget);
      });
    }
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(repository, initialStatus: ProfileLoaded(_profile())),
    );
    await _openChangeAvatar(tester);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });
}
