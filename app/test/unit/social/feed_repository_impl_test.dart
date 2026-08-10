import 'package:app/features/social/data/feed_remote_datasource.dart';
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/domain/feed_item.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFeedRemoteDatasource extends Mock implements FeedRemoteDatasource {}

Map<String, dynamic> _reviewRow({
  String id = 'rv-1',
  String userId = 'user-2',
  String createdAt = '2026-01-03T00:00:00.000Z',
}) {
  return {
    'id': id,
    'restaurant_id': 'r-1',
    'user_id': userId,
    'rating': 4.5,
    'comment': 'Ótimo!',
    'likes_count': 3,
    'photos_count': 0,
    'created_at': createdAt,
    'updated_at': createdAt,
    'restaurants': {'id': 'r-1', 'name': 'Outback', 'cover_image': null},
  };
}

Map<String, dynamic> _badgeRow({
  String id = 'ub-1',
  String userId = 'user-2',
  String earnedAt = '2026-01-02T00:00:00.000Z',
}) {
  return {
    'id': id,
    'user_id': userId,
    'earned_at': earnedAt,
    'badges': {
      'code': 'first_review',
      'name': 'Primeira Avaliação',
      'description': 'Publicou sua primeira avaliação.',
    },
  };
}

Map<String, dynamic> _profileRow({
  required String id,
  String? fullName = 'Bruno Costa',
  String? username = 'bruno',
}) {
  return {
    'id': id,
    'full_name': fullName,
    'username': username,
    'avatar_url': null,
  };
}

Map<String, dynamic> _groupJoinRow({
  String memberId = 'gm-1',
  String groupId = 'g-1',
  String joinedAt = '2026-01-04T00:00:00.000Z',
}) {
  return {
    'member_id': memberId,
    'group_id': groupId,
    'group_name': 'Amigos da Faculdade',
    'group_photo_url': null,
    'member_count': 5,
    'user_id': 'user-3',
    'full_name': 'Carla Dias',
    'username': 'carla',
    'avatar_url': null,
    'joined_at': joinedAt,
  };
}

void main() {
  late MockFeedRemoteDatasource datasource;
  late FeedRepositoryImpl repository;

  setUp(() {
    datasource = MockFeedRemoteDatasource();
    repository = FeedRepositoryImpl(datasource);

    when(
      () => datasource.fetchLikedReviewIds(any(), any()),
    ).thenAnswer((_) async => {});
    when(
      () => datasource.fetchCommentCounts(any()),
    ).thenAnswer((_) async => {});
    when(() => datasource.fetchMyGroupIds(any())).thenAnswer((_) async => {});
    // Default: resolve um perfil sintético para qualquer id pedido -
    // testes que não verificam o autor não precisam de um stub próprio;
    // os que verificam sobrescrevem este stub.
    when(() => datasource.fetchProfilesByIds(any())).thenAnswer((
      invocation,
    ) async {
      final ids = invocation.positionalArguments.first as List<String>;
      return ids.map((id) => _profileRow(id: id)).toList();
    });
  });

  group('listForYou', () {
    test('sem seguidos, sem pares de grupo e sem grupos públicos -> vazio, '
        'nenhuma fonte de "qualquer usuário" é consultada', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      final result = await repository.listForYou('user-1', page: 1, limit: 20);

      expect(result.items, isEmpty);
      expect(result.hasNextPage, isFalse);
      verifyNever(
        () => datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
      );
      verifyNever(
        () => datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
      );
      verifyNever(() => datasource.fetchProfilesByIds(any()));
    });

    test('combina reviews + badges + entradas em grupo público, ordenados por '
        'created_at desc', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => ['user-2']);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchReviewsByUsers([
          'user-2',
        ], limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [_reviewRow(createdAt: '2026-01-03T00:00:00.000Z')],
      );
      when(
        () => datasource.fetchBadgesByUsers([
          'user-2',
        ], limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [_badgeRow(earnedAt: '2026-01-02T00:00:00.000Z')],
      );
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [_groupJoinRow(joinedAt: '2026-01-04T00:00:00.000Z')],
      );

      final result = await repository.listForYou('user-1', page: 1, limit: 20);

      expect(result.items.map((i) => i.feedKey), [
        'group_join:gm-1', // 2026-01-04
        'review:rv-1', // 2026-01-03
        'badge:ub-1', // 2026-01-02
      ]);
    });

    test('une pessoas seguidas e pares de grupo, sem duplicar a consulta de '
        'reviews por id repetido', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => ['user-2']);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => ['user-2', 'user-3']);
      when(
        () => datasource.fetchReviewsByUsers(
          any(that: unorderedEquals(['user-2', 'user-3'])),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [_reviewRow()]);
      when(
        () => datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      final result = await repository.listForYou('user-1', page: 1, limit: 20);

      expect(result.items, hasLength(1));
      verify(
        () => datasource.fetchReviewsByUsers(
          any(that: unorderedEquals(['user-2', 'user-3'])),
          limit: any(named: 'limit'),
        ),
      ).called(1);
    });

    test(
      'marca isLikedByUser/commentsCount a partir das buscas em lote',
      () async {
        when(
          () => datasource.fetchFollowingIds('user-1'),
        ).thenAnswer((_) async => ['user-2']);
        when(
          () => datasource.fetchGroupPeerIds('user-1'),
        ).thenAnswer((_) async => []);
        when(
          () =>
              datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => [_reviewRow(id: 'rv-1')]);
        when(
          () =>
              datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => []);
        when(
          () => datasource.fetchRecentPublicGroupJoins(
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => datasource.fetchLikedReviewIds('user-1', ['rv-1']),
        ).thenAnswer((_) async => {'rv-1'});
        when(
          () => datasource.fetchCommentCounts(['rv-1']),
        ).thenAnswer((_) async => {'rv-1': 4});

        final result = await repository.listForYou(
          'user-1',
          page: 1,
          limit: 20,
        );

        final item = result.items.single as FeedReviewItem;
        expect(item.isLikedByUser, isTrue);
        expect(item.commentsCount, 4);
      },
    );

    test('marca viewerIsMember do grupo a partir de fetchMyGroupIds', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer((_) async => [_groupJoinRow(groupId: 'g-1')]);
      when(
        () => datasource.fetchMyGroupIds('user-1'),
      ).thenAnswer((_) async => {'g-1'});

      final result = await repository.listForYou('user-1', page: 1, limit: 20);

      final item = result.items.single as FeedGroupJoinItem;
      expect(item.viewerIsMember, isTrue);
    });

    test('pagina o conjunto mesclado (page 2) e calcula hasNextPage', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => ['user-2']);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [
          _reviewRow(id: 'rv-1', createdAt: '2026-01-05T00:00:00.000Z'),
          _reviewRow(id: 'rv-2', createdAt: '2026-01-04T00:00:00.000Z'),
          _reviewRow(id: 'rv-3', createdAt: '2026-01-03T00:00:00.000Z'),
        ],
      );
      when(
        () => datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      final page1 = await repository.listForYou('user-1', page: 1, limit: 2);
      expect(page1.items.map((i) => i.feedKey), ['review:rv-1', 'review:rv-2']);
      expect(page1.hasNextPage, isTrue);

      final page2 = await repository.listForYou('user-1', page: 2, limit: 2);
      expect(page2.items.map((i) => i.feedKey), ['review:rv-3']);
      expect(page2.hasNextPage, isFalse);
    });
  });

  group('resolução de perfis (reviews/badges sem embed)', () {
    test('autor de review é resolvido via fetchProfilesByIds, não vem embutido '
        'na linha', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => ['user-2']);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => [_reviewRow(userId: 'user-2')]);
      when(
        () => datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(() => datasource.fetchProfilesByIds(['user-2'])).thenAnswer(
        (_) async => [
          _profileRow(id: 'user-2', fullName: 'Bruno Costa', username: 'bruno'),
        ],
      );

      final result = await repository.listForYou('user-1', page: 1, limit: 20);

      final item = result.items.single as FeedReviewItem;
      expect(item.actor.id, 'user-2');
      expect(item.actor.fullName, 'Bruno Costa');
      expect(item.actor.username, 'bruno');
      verify(() => datasource.fetchProfilesByIds(['user-2'])).called(1);
    });

    test(
      'autor de badge é resolvido pela mesma consulta em lote de perfis',
      () async {
        when(
          () => datasource.fetchFollowingIds('user-1'),
        ).thenAnswer((_) async => ['user-2']);
        when(
          () => datasource.fetchGroupPeerIds('user-1'),
        ).thenAnswer((_) async => []);
        when(
          () =>
              datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => []);
        when(
          () =>
              datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => [_badgeRow(userId: 'user-2')]);
        when(
          () => datasource.fetchRecentPublicGroupJoins(
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);
        when(() => datasource.fetchProfilesByIds(['user-2'])).thenAnswer(
          (_) async => [
            _profileRow(
              id: 'user-2',
              fullName: 'Bruno Costa',
              username: 'bruno',
            ),
          ],
        );

        final result = await repository.listForYou(
          'user-1',
          page: 1,
          limit: 20,
        );

        final item = result.items.single as FeedBadgeItem;
        expect(item.actor.id, 'user-2');
        expect(item.actor.fullName, 'Bruno Costa');
      },
    );

    test('autor sem perfil correspondente não quebra o Feed - item aparece só '
        'com o id', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => ['user-2']);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => [_reviewRow(userId: 'user-2')]);
      when(
        () => datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchProfilesByIds(['user-2']),
      ).thenAnswer((_) async => []);

      final result = await repository.listForYou('user-1', page: 1, limit: 20);

      final item = result.items.single as FeedReviewItem;
      expect(item.actor.id, 'user-2');
      expect(item.actor.fullName, isNull);
      expect(item.actor.username, isNull);
    });

    test('múltiplas reviews do mesmo autor disparam uma única consulta de '
        'perfis', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => ['user-2']);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [
          _reviewRow(id: 'rv-1', userId: 'user-2'),
          _reviewRow(
            id: 'rv-2',
            userId: 'user-2',
            createdAt: '2026-01-02T00:00:00.000Z',
          ),
        ],
      );
      when(
        () => datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      final result = await repository.listForYou('user-1', page: 1, limit: 20);

      expect(result.items, hasLength(2));
      verify(() => datasource.fetchProfilesByIds(['user-2'])).called(1);
    });

    test('reviews e badges de autores diferentes contribuem para uma única '
        'consulta batched com todos os ids envolvidos', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => ['user-2', 'user-3']);
      when(
        () => datasource.fetchGroupPeerIds('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => [_reviewRow(userId: 'user-2')]);
      when(
        () => datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => [_badgeRow(userId: 'user-3')]);
      when(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      await repository.listForYou('user-1', page: 1, limit: 20);

      verify(
        () => datasource.fetchProfilesByIds(
          any(that: unorderedEquals(['user-2', 'user-3'])),
        ),
      ).called(1);
    });
  });

  group('listFollowing', () {
    test('nunca consulta entradas em grupo público (fonte exclusiva do '
        '"Para Você")', () async {
      when(
        () => datasource.fetchFollowingIds('user-1'),
      ).thenAnswer((_) async => ['user-2']);
      when(
        () => datasource.fetchReviewsByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => [_reviewRow()]);
      when(
        () => datasource.fetchBadgesByUsers(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      await repository.listFollowing('user-1', page: 1, limit: 20);

      verifyNever(
        () =>
            datasource.fetchRecentPublicGroupJoins(limit: any(named: 'limit')),
      );
      verifyNever(() => datasource.fetchGroupPeerIds(any()));
    });
  });

  test('traduz PostgrestException em FeedRepositoryException', () async {
    when(
      () => datasource.fetchFollowingIds('user-1'),
    ).thenThrow(const PostgrestException(message: 'falhou'));

    expect(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
      throwsA(isA<FeedRepositoryException>()),
    );
  });
}
