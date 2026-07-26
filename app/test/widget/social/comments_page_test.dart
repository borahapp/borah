import 'package:app/core/models/paged_result.dart';
import 'package:app/features/authentication/application/auth_controller.dart';
import 'package:app/features/social/data/comment_repository_impl.dart';
import 'package:app/features/social/domain/comment.dart';
import 'package:app/features/social/domain/comment_repository.dart';
import 'package:app/features/social/presentation/pages/comments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

Comment _comment({
  String id = 'c-1',
  String userId = 'user-1',
  String content = 'Ótima avaliação!',
}) {
  return Comment(
    id: id,
    reviewId: 'rv-1',
    userId: userId,
    content: content,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(
  MockCommentRepository repository, {
  String currentUserId = 'user-1',
}) {
  return ProviderScope(
    overrides: [
      commentRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(currentUserId),
    ],
    child: const MaterialApp(home: CommentsPage(reviewId: 'rv-1')),
  );
}

void main() {
  late MockCommentRepository repository;

  setUp(() {
    repository = MockCommentRepository();
  });

  // RC-04E: excluir era imediato, sem nenhuma confirmação.
  group('excluir comentário', () {
    testWidgets('pede confirmação antes de excluir', (tester) async {
      when(
        () => repository.listByReview(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_comment(userId: 'user-1')],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(() => repository.delete(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Excluir'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      verifyNever(() => repository.delete(any()));

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Excluir'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repository.delete('c-1')).called(1);
    });
  });

  group('denunciar comentário', () {
    testWidgets('motivo vazio mostra erro de validação e não denuncia', (
      tester,
    ) async {
      when(
        () => repository.listByReview(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_comment(userId: 'user-2')],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Denunciar'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Denunciar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o motivo da denúncia.'), findsOneWidget);
      verifyNever(
        () => repository.report(
          any(),
          reportedBy: any(named: 'reportedBy'),
          reason: any(named: 'reason'),
        ),
      );
    });

    testWidgets('motivo preenchido denuncia e mostra confirmação', (
      tester,
    ) async {
      when(
        () => repository.listByReview(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [_comment(userId: 'user-2')],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(
        () => repository.report(
          any(),
          reportedBy: any(named: 'reportedBy'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Denunciar'));
      await tester.pumpAndSettle();

      // `find.byType(TextFormField)` sozinho é ambíguo aqui: o campo de
      // "Escreva um comentário" da própria CommentsPage continua na
      // árvore (por trás do diálogo) - restringir ao diálogo aberto.
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'Conteúdo ofensivo',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Denunciar'));
      await tester.pumpAndSettle();

      verify(
        () => repository.report(
          'c-1',
          reportedBy: 'user-1',
          reason: 'Conteúdo ofensivo',
        ),
      ).called(1);
      expect(find.text('Denúncia enviada.'), findsOneWidget);
    });
  });
}
