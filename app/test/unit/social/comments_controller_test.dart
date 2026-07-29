import 'package:app/core/models/paged_result.dart';
import 'package:app/features/social/application/comments_controller.dart';
import 'package:app/features/social/data/comment_repository_impl.dart';
import 'package:app/features/social/domain/comment.dart';
import 'package:app/features/social/domain/comment_repository.dart';
import 'package:app/features/social/presentation/states/comments_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

Comment _comment({String id = 'c-1', String content = 'Muito bom!'}) {
  return Comment(
    id: id,
    reviewId: 'rv-1',
    userId: 'user-1',
    content: content,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockCommentRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockCommentRepository();
    container = ProviderContainer(
      overrides: [commentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é CommentsInitial', () {
    expect(container.read(commentsControllerProvider), isA<CommentsInitial>());
  });

  test('loadForReview com resultados -> CommentsLoaded', () async {
    when(() => repository.listByReview('rv-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_comment()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container
        .read(commentsControllerProvider.notifier)
        .loadForReview('rv-1');

    expect(container.read(commentsControllerProvider), isA<CommentsLoaded>());
  });

  test('loadForReview sem resultados -> CommentsEmpty', () async {
    when(() => repository.listByReview('rv-1', page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );

    await container
        .read(commentsControllerProvider.notifier)
        .loadForReview('rv-1');

    expect(container.read(commentsControllerProvider), isA<CommentsEmpty>());
  });

  test('create publica e recarrega a lista -> CommentsLoaded', () async {
    when(() => repository.listByReview('rv-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_comment()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.create(
        reviewId: 'rv-1',
        userId: 'user-1',
        content: 'Ótimo!',
      ),
    ).thenAnswer((_) async => _comment(content: 'Ótimo!'));

    final notifier = container.read(commentsControllerProvider.notifier);
    await notifier.loadForReview('rv-1');
    await notifier.create(userId: 'user-1', content: 'Ótimo!');

    expect(container.read(commentsControllerProvider), isA<CommentsLoaded>());
    verify(
      () => repository.create(
        reviewId: 'rv-1',
        userId: 'user-1',
        content: 'Ótimo!',
      ),
    ).called(1);
  });

  test('update fora da janela de edição -> CommentsError', () async {
    when(() => repository.listByReview('rv-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_comment()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.update('c-1', content: any(named: 'content')),
    ).thenThrow(
      const CommentRepositoryException('A janela de edição expirou.'),
    );

    final notifier = container.read(commentsControllerProvider.notifier);
    await notifier.loadForReview('rv-1');
    await notifier.update('c-1', content: 'Editado');

    expect(container.read(commentsControllerProvider), isA<CommentsError>());
  });

  group('delete', () {
    test('sucesso remove e recarrega a lista -> CommentsLoaded', () async {
      when(
        () => repository.listByReview('rv-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(() => repository.delete('c-1')).thenAnswer((_) async {});

      final notifier = container.read(commentsControllerProvider.notifier);
      await notifier.loadForReview('rv-1');
      await notifier.delete('c-1');

      expect(container.read(commentsControllerProvider), isA<CommentsEmpty>());
      verify(() => repository.delete('c-1')).called(1);
    });

    test('falha -> CommentsError', () async {
      when(
        () => repository.listByReview('rv-1', page: 1, limit: 20),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_comment()],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(
        () => repository.delete('c-1'),
      ).thenThrow(const CommentRepositoryException('Não é o autor.'));

      final notifier = container.read(commentsControllerProvider.notifier);
      await notifier.loadForReview('rv-1');
      await notifier.delete('c-1');

      expect(container.read(commentsControllerProvider), isA<CommentsError>());
    });
  });

  test('report envia denúncia', () async {
    when(() => repository.listByReview('rv-1', page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_comment()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(
      () => repository.report('c-1', reportedBy: 'user-2', reason: 'Spam'),
    ).thenAnswer((_) async {});

    final notifier = container.read(commentsControllerProvider.notifier);
    await notifier.loadForReview('rv-1');
    await notifier.report('c-1', reportedBy: 'user-2', reason: 'Spam');

    verify(
      () => repository.report('c-1', reportedBy: 'user-2', reason: 'Spam'),
    ).called(1);
  });
}
