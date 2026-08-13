import 'package:app/core/models/paged_result.dart';
import 'package:app/features/social/application/feed_controller.dart';
import 'package:app/features/social/application/follow_controller.dart';
import 'package:app/features/social/application/public_profile_provider.dart';
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/social/presentation/states/follow_status.dart';
import 'package:app/features/users/data/user_profile_repository_impl.dart';
import 'package:app/features/users/domain/user_profile.dart';
import 'package:app/features/users/domain/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRepository extends Mock implements FollowerRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

UserProfile _profile(String id) {
  return UserProfile(
    id: id,
    fullName: 'Usuário $id',
    username: null,
    bio: null,
    avatarUrl: null,
    city: null,
    state: null,
    followersCount: 0,
    followingCount: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockFollowerRepository repository;
  late MockUserProfileRepository userProfileRepository;
  late MockFeedRepository feedRepository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFollowerRepository();
    userProfileRepository = MockUserProfileRepository();
    feedRepository = MockFeedRepository();
    container = ProviderContainer(
      overrides: [
        followerRepositoryProvider.overrideWithValue(repository),
        userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
        feedRepositoryProvider.overrideWithValue(feedRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FollowInitial', () {
    expect(container.read(followControllerProvider), isA<FollowInitial>());
  });

  group('load', () {
    test('não segue -> FollowLoaded(false)', () async {
      when(
        () => repository.isFollowing('user-1', 'user-2'),
      ).thenAnswer((_) async => false);

      await container
          .read(followControllerProvider.notifier)
          .load('user-1', 'user-2');

      final status = container.read(followControllerProvider);
      expect(status, isA<FollowLoaded>());
      expect((status as FollowLoaded).isFollowing, isFalse);
    });

    test('falha ao verificar -> FollowError', () async {
      when(() => repository.isFollowing('user-1', 'user-2')).thenThrow(
        const FollowerRepositoryException('Não foi possível verificar.'),
      );

      await container
          .read(followControllerProvider.notifier)
          .load('user-1', 'user-2');

      final status = container.read(followControllerProvider);
      expect(status, isA<FollowError>());
      expect((status as FollowError).message, 'Não foi possível verificar.');
    });
  });

  group('toggle', () {
    test('segue quando ainda não segue', () async {
      when(
        () => repository.isFollowing('user-1', 'user-2'),
      ).thenAnswer((_) async => false);
      when(
        () => repository.follow('user-1', 'user-2'),
      ).thenAnswer((_) async {});

      final notifier = container.read(followControllerProvider.notifier);
      await notifier.load('user-1', 'user-2');
      await notifier.toggle('user-1', 'user-2');

      final status = container.read(followControllerProvider);
      expect(status, isA<FollowLoaded>());
      expect((status as FollowLoaded).isFollowing, isTrue);
      verify(() => repository.follow('user-1', 'user-2')).called(1);
    });

    test('deixa de seguir quando já segue', () async {
      when(
        () => repository.isFollowing('user-1', 'user-2'),
      ).thenAnswer((_) async => true);
      when(
        () => repository.unfollow('user-1', 'user-2'),
      ).thenAnswer((_) async {});

      final notifier = container.read(followControllerProvider.notifier);
      await notifier.load('user-1', 'user-2');
      await notifier.toggle('user-1', 'user-2');

      final status = container.read(followControllerProvider);
      expect(status, isA<FollowLoaded>());
      expect((status as FollowLoaded).isFollowing, isFalse);
      verify(() => repository.unfollow('user-1', 'user-2')).called(1);
    });

    test(
      'self-follow é bloqueado sem chamar o repositório (FASE SOCIAL 2)',
      () async {
        final notifier = container.read(followControllerProvider.notifier);
        await notifier.toggle('user-1', 'user-1');

        final status = container.read(followControllerProvider);
        expect(status, isA<FollowError>());
        expect(
          (status as FollowError).message,
          'Você não pode seguir a si mesmo.',
        );
        verifyNever(() => repository.follow(any(), any()));
        verifyNever(() => repository.unfollow(any(), any()));
      },
    );

    test('falha ao seguir -> FollowError', () async {
      when(
        () => repository.isFollowing('user-1', 'user-2'),
      ).thenAnswer((_) async => false);
      when(() => repository.follow('user-1', 'user-2')).thenThrow(
        const FollowerRepositoryException('Não foi possível seguir.'),
      );

      final notifier = container.read(followControllerProvider.notifier);
      await notifier.load('user-1', 'user-2');
      await notifier.toggle('user-1', 'user-2');

      final status = container.read(followControllerProvider);
      expect(status, isA<FollowError>());
      expect((status as FollowError).message, 'Não foi possível seguir.');
    });
  });

  // 2B.3-G (fix do F2 da auditoria 2B.3-F): antes, um follow/unfollow bem
  // sucedido nunca avisava ninguém - Feed "Seguindo" e contadores de
  // seguidores/seguindo ficavam com dado desatualizado até o app ser
  // reiniciado (o `IndexedStack` de `HomeShellPage` mantém as páginas
  // vivas, então nem sair/voltar de aba reexecutava o carregamento).
  group('2B.3-G - atualização de dependentes após toggle', () {
    test('toggle bem-sucedido recarrega o perfil do seguidor '
        '(contador "seguindo")', () async {
      when(
        () => repository.isFollowing('user-1', 'user-2'),
      ).thenAnswer((_) async => false);
      when(
        () => repository.follow('user-1', 'user-2'),
      ).thenAnswer((_) async {});
      when(
        () => userProfileRepository.getProfile('user-1'),
      ).thenAnswer((_) async => _profile('user-1'));

      final notifier = container.read(followControllerProvider.notifier);
      await notifier.load('user-1', 'user-2');
      await notifier.toggle('user-1', 'user-2');

      verify(() => userProfileRepository.getProfile('user-1')).called(1);
    });

    test(
      'toggle bem-sucedido invalida o perfil público do seguido '
      '(contador "seguidores") - releitura busca de novo no repositório',
      () async {
        when(
          () => repository.isFollowing('user-1', 'user-2'),
        ).thenAnswer((_) async => false);
        when(
          () => repository.follow('user-1', 'user-2'),
        ).thenAnswer((_) async {});
        when(
          () => userProfileRepository.getProfile('user-1'),
        ).thenAnswer((_) async => _profile('user-1'));
        when(
          () => userProfileRepository.getProfile('user-2'),
        ).thenAnswer((_) async => _profile('user-2'));

        // Simula `PublicProfilePage` já ter lido o perfil de user-2 antes
        // do follow (cache do `FutureProvider.family`).
        await container.read(publicProfileProvider('user-2').future);
        verify(() => userProfileRepository.getProfile('user-2')).called(1);

        final notifier = container.read(followControllerProvider.notifier);
        await notifier.load('user-1', 'user-2');
        await notifier.toggle('user-1', 'user-2');

        // O cache foi invalidado - uma nova leitura busca de novo em vez
        // de devolver o valor antigo.
        await container.read(publicProfileProvider('user-2').future);
        verify(() => userProfileRepository.getProfile('user-2')).called(1);
      },
    );

    test('toggle bem-sucedido atualiza o Feed "Seguindo" já carregado '
        '(sem esperar o usuário sair e voltar da aba)', () async {
      when(
        () => repository.isFollowing('user-1', 'user-2'),
      ).thenAnswer((_) async => false);
      when(
        () => repository.follow('user-1', 'user-2'),
      ).thenAnswer((_) async {});
      when(
        () => userProfileRepository.getProfile('user-1'),
      ).thenAnswer((_) async => _profile('user-1'));
      when(
        () => feedRepository.listFollowing('user-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      // Simula a aba "Seguindo" já visitada (o `IndexedStack` de
      // `HomeShellPage` carrega o Feed uma vez no início do app).
      await container
          .read(feedFollowingControllerProvider.notifier)
          .loadForUser('user-1');
      verify(
        () => feedRepository.listFollowing('user-1', page: 1, limit: 20),
      ).called(1);

      final notifier = container.read(followControllerProvider.notifier);
      await notifier.load('user-1', 'user-2');
      await notifier.toggle('user-1', 'user-2');

      // Uma 2ª chamada real ao repositório confirma que `refresh()` foi
      // disparado - não é só um reset de estado sem rebusca (o que
      // deixaria o Feed preso em `FeedInitial` para sempre).
      verify(
        () => feedRepository.listFollowing('user-1', page: 1, limit: 20),
      ).called(1);
    });

    test('toggle antes de qualquer carregamento do Feed "Seguindo" não '
        'dispara nenhuma chamada ao repositório (sem N+1/efeito colateral '
        'indevido quando a aba nunca foi visitada)', () async {
      when(
        () => repository.isFollowing('user-1', 'user-2'),
      ).thenAnswer((_) async => false);
      when(
        () => repository.follow('user-1', 'user-2'),
      ).thenAnswer((_) async {});
      when(
        () => userProfileRepository.getProfile('user-1'),
      ).thenAnswer((_) async => _profile('user-1'));

      final notifier = container.read(followControllerProvider.notifier);
      await notifier.load('user-1', 'user-2');
      await notifier.toggle('user-1', 'user-2');

      verifyNever(
        () => feedRepository.listFollowing(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      );
    });
  });
}
