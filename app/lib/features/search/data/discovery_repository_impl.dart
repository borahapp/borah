import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_client_provider.dart';
import '../../users/domain/user_profile.dart';
import '../domain/discovery_repository.dart';
import 'discovery_remote_datasource.dart';

/// FASE SOCIAL 2 - implementação de "Você pode conhecer" (ver
/// `DiscoveryRepository`). No máximo 6 consultas, todas com `limit`
/// explícito - sem N+1, sem depender do tamanho da base para permanecer
/// previsível.
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl(this._datasource);

  final DiscoveryRemoteDatasource _datasource;

  /// Quantas pessoas já seguidas por [userId] usar como "sementes" da
  /// prioridade 2 (amigos de amigos) - poucas, não a lista inteira.
  static const _followingSeedsLimit = 15;

  /// Teto de candidatos de amigos-de-amigos buscados por chamada -
  /// mantém a segunda consulta pequena mesmo com muitas sementes.
  static const _friendsOfFriendsLimit = 60;

  @override
  Future<DiscoverySuggestions> suggestPeople(
    String userId, {
    required int limit,
  }) {
    return _guard(() async {
      // Prioridade 1: pessoas do mesmo grupo.
      final myGroupIds = await _datasource.fetchMyGroupIds(userId);
      final sameGroupIds = await _datasource.fetchGroupMemberIds(
        myGroupIds,
        excludeUserId: userId,
      );

      // Prioridade 2: amigos de amigos - só busca se a prioridade 1
      // ainda não preencheu sozinha o limite pedido (evita 2 consultas
      // extras quando já há candidatos suficientes).
      var friendsOfFriendsIds = <String>[];
      if (sameGroupIds.length < limit) {
        final seeds = await _datasource.fetchFollowingSeeds(
          userId,
          limit: _followingSeedsLimit,
        );
        if (seeds.isNotEmpty) {
          friendsOfFriendsIds = await _datasource.fetchFollowerIdsOf(
            seeds,
            limit: _friendsOfFriendsLimit,
          );
        }
      }

      // Mescla preservando a prioridade, remove o próprio usuário e
      // duplicados (um id pode aparecer nas 2 fontes).
      final orderedCandidateIds = <String>[];
      final seen = <String>{userId};
      for (final id in [...sameGroupIds, ...friendsOfFriendsIds]) {
        if (seen.add(id)) orderedCandidateIds.add(id);
      }

      if (orderedCandidateIds.isEmpty) {
        return const DiscoverySuggestions(people: [], hasMore: false);
      }

      // Remove quem o usuário já segue - só entre os candidatos já
      // filtrados, não a lista completa de quem ele segue.
      final alreadyFollowing = await _datasource.fetchFollowingAmong(
        userId,
        orderedCandidateIds,
      );
      final finalIds = orderedCandidateIds
          .where((id) => !alreadyFollowing.contains(id))
          .toList();

      if (finalIds.isEmpty) {
        return const DiscoverySuggestions(people: [], hasMore: false);
      }

      final hasMore = finalIds.length > limit;
      final pageIds = hasMore ? finalIds.sublist(0, limit) : finalIds;

      final rows = await _datasource.fetchProfilesByIds(pageIds);
      final rowsById = {for (final row in rows) row['id'] as String: row};
      // Preserva a ordem de prioridade - `inFilter` não garante ordem
      // correspondente (mesma decisão de `FollowerRepositoryImpl._listByIds`).
      final people = pageIds
          .where(rowsById.containsKey)
          .map((id) => _mapRow(rowsById[id]!))
          .toList();

      return DiscoverySuggestions(people: people, hasMore: hasMore);
    });
  }

  UserProfile _mapRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      fullName: row['full_name'] as String?,
      username: row['username'] as String?,
      bio: row['bio'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      city: row['city'] as String?,
      state: row['state'] as String?,
      followersCount: row['followers_count'] as int,
      followingCount: row['following_count'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw DiscoveryRepositoryException(e.message);
    }
  }
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DiscoveryRepositoryImpl(DiscoveryRemoteDatasource(client));
});
