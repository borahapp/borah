import 'package:app/features/social/domain/feed_item.dart';
import 'package:app/features/social/presentation/widgets/social_feed_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

FeedActor _actor({String id = 'user-2'}) {
  return FeedActor(
    id: id,
    fullName: 'Carla Dias',
    username: 'carla',
    avatarUrl: null,
  );
}

Widget _wrap(FeedItem item) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: SocialFeedCard(item: item, currentUserId: 'user-1'),
        ),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, state) => Scaffold(
          body: Text('Public Profile Page ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => Scaffold(
          body: Text('Group Detail Page ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/groups/:id/preview',
        builder: (_, state) => Scaffold(
          body: Text('Group Preview Page ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  group('FeedBadgeItem', () {
    FeedBadgeItem item() {
      return FeedBadgeItem(
        id: 'ub-1',
        actor: _actor(),
        badgeCode: 'first_review',
        badgeName: 'Primeira Avaliação',
        badgeDescription: 'Publicou sua primeira avaliação.',
        earnedAt: DateTime(2026, 1, 1),
      );
    }

    testWidgets('mostra autor, contexto e o nome/descrição da badge', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(item()));
      await tester.pumpAndSettle();

      expect(find.text('Carla Dias'), findsOneWidget);
      expect(find.text('@carla'), findsOneWidget);
      expect(find.text('conquistou uma nova badge'), findsOneWidget);
      expect(find.text('Primeira Avaliação'), findsOneWidget);
      expect(find.text('Publicou sua primeira avaliação.'), findsOneWidget);
    });

    testWidgets('tocar no card navega para o perfil público do autor', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(item()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Primeira Avaliação'));
      await tester.pumpAndSettle();

      expect(find.text('Public Profile Page user-2'), findsOneWidget);
    });
  });

  group('FeedGroupJoinItem', () {
    FeedGroupJoinItem item({bool viewerIsMember = false}) {
      return FeedGroupJoinItem(
        memberId: 'gm-1',
        actor: _actor(),
        groupId: 'g-1',
        groupName: 'Amigos da Faculdade',
        groupPhotoUrl: null,
        memberCount: 5,
        joinedAt: DateTime(2026, 1, 1),
        viewerIsMember: viewerIsMember,
      );
    }

    testWidgets(
      'mostra autor, contexto, nome/contagem do grupo e badge Público - '
      'nunca a lista de membros',
      (tester) async {
        await tester.pumpWidget(_wrap(item()));
        await tester.pumpAndSettle();

        expect(find.text('Carla Dias'), findsOneWidget);
        expect(find.text('entrou no grupo'), findsOneWidget);
        expect(find.text('Amigos da Faculdade'), findsOneWidget);
        expect(find.text('5 membros'), findsOneWidget);
        expect(find.text('Público'), findsOneWidget);
        expect(find.text('Ver grupo'), findsOneWidget);
      },
    );

    testWidgets('quem não é membro navega para a prévia pública do grupo', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(item()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver grupo'));
      await tester.pumpAndSettle();

      expect(find.text('Group Preview Page g-1'), findsOneWidget);
    });

    testWidgets('quem já é membro navega direto para o detalhe do grupo', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(item(viewerIsMember: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver grupo'));
      await tester.pumpAndSettle();

      expect(find.text('Group Detail Page g-1'), findsOneWidget);
    });
  });
}
