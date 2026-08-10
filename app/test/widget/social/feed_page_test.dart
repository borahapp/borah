import 'dart:async';

import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/social/data/feed_repository_impl.dart';
import 'package:app/features/social/domain/feed_item.dart';
import 'package:app/features/social/domain/feed_repository.dart';
import 'package:app/features/social/presentation/pages/feed_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

FeedActor _actor() {
  return const FeedActor(
    id: 'user-2',
    fullName: 'Bruno Costa',
    username: 'bruno',
    avatarUrl: null,
  );
}

FeedReviewItem _reviewItem({
  String id = 'rv-1',
  double rating = 4.5,
  String? comment = 'Ótima experiência.',
}) {
  return FeedReviewItem(
    review: Review(
      id: id,
      restaurantId: 'r-1',
      userId: 'user-2',
      rating: rating,
      comment: comment,
      likesCount: 3,
      photosCount: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    actor: _actor(),
    restaurantId: 'r-1',
    restaurantName: 'Outback Campinas',
    restaurantCoverImage: null,
    likesCount: 3,
    isLikedByUser: false,
    commentsCount: 2,
  );
}

Widget _wrap(MockFeedRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const FeedPage()),
      GoRoute(
        path: '/reviews/:id',
        builder: (_, state) => Scaffold(
          body: Text('Review Detail Page ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/reviews/:id/comments',
        builder: (_, state) =>
            Scaffold(body: Text('Comments Page ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/restaurants/:id',
        builder: (_, state) => Scaffold(
          body: Text('Restaurant Detail Page ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, state) => Scaffold(
          body: Text('Public Profile Page ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, _) => const Scaffold(body: Text('Search Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      feedRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('user-1'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _stubEmptyBoth(MockFeedRepository repository) {
  when(() => repository.listForYou('user-1', page: 1, limit: 20)).thenAnswer(
    (_) async =>
        const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
  );
  when(() => repository.listFollowing('user-1', page: 1, limit: 20)).thenAnswer(
    (_) async =>
        const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
  );
}

void main() {
  late MockFeedRepository repository;

  setUp(() {
    repository = MockFeedRepository();
  });

  testWidgets('estado de carregamento mostra indicador ao abrir a tela', (
    tester,
  ) async {
    final completer = Completer<PagedResult<FeedItem>>();
    when(
      () => repository.listForYou('user-1', page: 1, limit: 20),
    ).thenAnswer((_) => completer.future);
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    completer.complete(
      const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    await tester.pumpAndSettle();
  });

  testWidgets(
    'aba "Para Você" mostra as avaliações retornadas em um SocialFeedCard',
    (tester) async {
      when(
        () => repository.listForYou('user-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_reviewItem()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(
        () => repository.listFollowing('user-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Ótima experiência.'), findsOneWidget);
      expect(
        find.textContaining('Outback Campinas', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Bruno Costa'), findsOneWidget);
      expect(find.text('@bruno'), findsOneWidget);
    },
  );

  testWidgets(
    'aba "Para Você" vazia mostra o estado de descoberta com ação para '
    'Explorar',
    (tester) async {
      _stubEmptyBoth(repository);

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Comece a seguir pessoas e grupos para personalizar seu Feed.',
        ),
        findsOneWidget,
      );
      expect(find.text('Explorar pessoas e grupos'), findsOneWidget);

      await tester.tap(find.text('Explorar pessoas e grupos'));
      await tester.pumpAndSettle();

      expect(find.text('Search Page'), findsOneWidget);
    },
  );

  testWidgets('aba "Seguindo" vazia mostra a mensagem específica dela', (
    tester,
  ) async {
    _stubEmptyBoth(repository);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seguindo'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma atividade de quem você segue ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('estado de erro mostra a mensagem retornada pelo repositório', (
    tester,
  ) async {
    when(
      () => repository.listForYou('user-1', page: 1, limit: 20),
    ).thenThrow(const FeedRepositoryException('Não foi possível carregar.'));
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenThrow(const FeedRepositoryException('Não foi possível carregar.'));

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar.'), findsWidgets);
  });

  testWidgets('tocar no card navega para o detalhe da avaliação', (
    tester,
  ) async {
    when(() => repository.listForYou('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_reviewItem()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('4.5'));
    await tester.pumpAndSettle();

    expect(find.text('Review Detail Page rv-1'), findsOneWidget);
  });

  testWidgets('tocar no nome do autor navega para o perfil público', (
    tester,
  ) async {
    when(() => repository.listForYou('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_reviewItem()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bruno Costa'));
    await tester.pumpAndSettle();

    expect(find.text('Public Profile Page user-2'), findsOneWidget);
  });

  testWidgets(
    'tocar no botão de comentários navega para a lista de comentários',
    (tester) async {
      when(
        () => repository.listForYou('user-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_reviewItem()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(
        () => repository.listFollowing('user-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2')); // contador de comentários
      await tester.pumpAndSettle();

      expect(find.text('Comments Page rv-1'), findsOneWidget);
    },
  );

  testWidgets('trocar de aba e voltar preserva a lista já carregada (sem novo '
      'carregamento)', (tester) async {
    when(() => repository.listForYou('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_reviewItem()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seguindo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Para Você'));
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsOneWidget);
    verify(() => repository.listForYou('user-1', page: 1, limit: 20)).called(1);
  });

  testWidgets('puxar para atualizar (RefreshIndicator) mantém a lista anterior '
      'visível e reflete o novo resultado ao concluir', (tester) async {
    when(() => repository.listForYou('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_reviewItem()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsOneWidget);

    final completer = Completer<PagedResult<FeedItem>>();
    when(
      () => repository.listForYou('user-1', page: 1, limit: 20),
    ).thenAnswer((_) => completer.future);

    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await tester.pump();

    // FeedRefreshing preserva o resultado anterior: o item continua
    // visível mesmo com a atualização em andamento.
    expect(find.text('4.5'), findsOneWidget);

    completer.complete(
      const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsNothing);
    expect(
      find.text('Comece a seguir pessoas e grupos para personalizar seu Feed.'),
      findsOneWidget,
    );
  });

  testWidgets('atende às diretrizes básicas de acessibilidade', (tester) async {
    when(() => repository.listForYou('user-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_reviewItem()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.listFollowing('user-1', page: 1, limit: 20),
    ).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
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
        when(
          () => repository.listForYou('user-1', page: 1, limit: 20),
        ).thenAnswer(
          (_) async => PagedResult(
            items: [_reviewItem()],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );
        when(
          () => repository.listFollowing('user-1', page: 1, limit: 20),
        ).thenAnswer(
          (_) async => const PagedResult(
            items: [],
            page: 1,
            limit: 20,
            hasNextPage: false,
          ),
        );

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('4.5'), findsOneWidget);
      });
    }
  });
}
