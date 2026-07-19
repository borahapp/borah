import 'package:app/features/social/application/follow_controller.dart';
import 'package:app/features/social/data/follower_repository_impl.dart';
import 'package:app/features/social/domain/follower_repository.dart';
import 'package:app/features/social/presentation/states/follow_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFollowerRepository extends Mock implements FollowerRepository {}

void main() {
  late MockFollowerRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFollowerRepository();
    container = ProviderContainer(
      overrides: [followerRepositoryProvider.overrideWithValue(repository)],
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
  });
}
