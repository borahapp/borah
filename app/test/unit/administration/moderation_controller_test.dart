import 'dart:async';

import 'package:app/core/logger/app_log_level.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/models/paged_result.dart';
import 'package:app/features/administration/application/moderation_controller.dart';
import 'package:app/features/administration/data/audit_log_repository_impl.dart';
import 'package:app/features/administration/domain/audit_log_repository.dart';
import 'package:app/features/administration/presentation/states/moderation_status.dart';
import 'package:app/features/reviews/data/review_repository_impl.dart';
import 'package:app/features/reviews/domain/review_repository.dart';
import 'package:app/features/social/data/comment_repository_impl.dart';
import 'package:app/features/social/domain/comment_report.dart';
import 'package:app/features/social/domain/comment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockAuditLogRepository extends Mock implements AuditLogRepository {}

CommentReport _report({String id = 'rep-1', String commentId = 'c-1'}) {
  return CommentReport(
    id: id,
    commentId: commentId,
    reportedBy: 'user-2',
    reason: 'Spam',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockCommentRepository commentRepository;
  late MockReviewRepository reviewRepository;
  late MockAuditLogRepository auditLogRepository;
  late ProviderContainer container;
  late List<Map<String, dynamic>> crashCalls;

  setUp(() {
    commentRepository = MockCommentRepository();
    reviewRepository = MockReviewRepository();
    auditLogRepository = MockAuditLogRepository();
    container = ProviderContainer(
      overrides: [
        commentRepositoryProvider.overrideWithValue(commentRepository),
        reviewRepositoryProvider.overrideWithValue(reviewRepository),
        auditLogRepositoryProvider.overrideWithValue(auditLogRepository),
      ],
    );
    addTearDown(container.dispose);

    crashCalls = [];
    AppLogger.debugMinimumLevelOverride = AppLogLevel.trace;
    AppLogger.debugCrashReportingSinkOverride =
        (level, message, {tag, userId, error, stackTrace}) async {
          crashCalls.add({'level': level, 'message': message, 'tag': tag});
        };
  });

  tearDown(() {
    AppLogger.debugMinimumLevelOverride = null;
    AppLogger.debugCrashReportingSinkOverride = null;
  });

  test('estado inicial é ModerationInitial', () {
    expect(
      container.read(moderationControllerProvider),
      isA<ModerationInitial>(),
    );
  });

  test('load com resultados -> ModerationLoaded', () async {
    when(() => commentRepository.listAllReports(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_report()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await container.read(moderationControllerProvider.notifier).load();

    expect(
      container.read(moderationControllerProvider),
      isA<ModerationLoaded>(),
    );
  });

  test('hideComment oculta e registra auditoria', () async {
    when(() => commentRepository.listAllReports(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_report()],
        page: 1,
        limit: 20,
        hasNextPage: false,
      ),
    );
    when(() => commentRepository.hideAsAdmin('c-1')).thenAnswer((_) async {});
    when(
      () => auditLogRepository.log(
        actorId: any(named: 'actorId'),
        action: any(named: 'action'),
        entity: any(named: 'entity'),
        entityId: any(named: 'entityId'),
      ),
    ).thenAnswer((_) async {});

    final notifier = container.read(moderationControllerProvider.notifier);
    await notifier.load();
    await notifier.hideComment('c-1', actorId: 'admin-1');

    verify(() => commentRepository.hideAsAdmin('c-1')).called(1);
    verify(
      () => auditLogRepository.log(
        actorId: 'admin-1',
        action: 'hide_comment',
        entity: 'comment',
        entityId: 'c-1',
      ),
    ).called(1);
  });

  group('FASE C.2.2 - falha de auditoria não bloqueia a ação principal', () {
    test('hideComment: auditoria falha -> operação continua concluída '
        '(ModerationLoaded/ModerationEmpty, não ModerationError), falha só '
        'registrada via AppLogger', () async {
      when(
        () => commentRepository.listAllReports(page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(() => commentRepository.hideAsAdmin('c-1')).thenAnswer((_) async {});
      when(
        () => auditLogRepository.log(
          actorId: any(named: 'actorId'),
          action: any(named: 'action'),
          entity: any(named: 'entity'),
          entityId: any(named: 'entityId'),
        ),
      ).thenThrow(const AuditLogRepositoryException('Falha ao gravar log.'));

      final notifier = container.read(moderationControllerProvider.notifier);
      await notifier.hideComment('c-1', actorId: 'admin-1');

      expect(
        container.read(moderationControllerProvider),
        isA<ModerationEmpty>(),
      );
      expect(crashCalls, hasLength(1));
      expect(crashCalls.single['level'], AppLogLevel.warning);
      expect(
        crashCalls.single['tag'],
        'administration/ModerationController.hideComment',
      );
    });

    test(
      'hideComment: ação principal falha -> ModerationError, auditoria nunca '
      'chamada',
      () async {
        when(() => commentRepository.hideAsAdmin('c-1')).thenThrow(
          const CommentRepositoryException('Comentário não encontrado.'),
        );

        final notifier = container.read(moderationControllerProvider.notifier);
        await notifier.hideComment('c-1', actorId: 'admin-1');

        final status = container.read(moderationControllerProvider);
        expect(status, isA<ModerationError>());
        expect(
          (status as ModerationError).message,
          'Comentário não encontrado.',
        );
        verifyNever(
          () => auditLogRepository.log(
            actorId: any(named: 'actorId'),
            action: any(named: 'action'),
            entity: any(named: 'entity'),
            entityId: any(named: 'entityId'),
          ),
        );
        expect(crashCalls, isEmpty);
      },
    );

    test('hideReview: ação e auditoria funcionando', () async {
      when(
        () => commentRepository.listAllReports(page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(() => reviewRepository.hideAsAdmin('rv-1')).thenAnswer((_) async {});
      when(
        () => auditLogRepository.log(
          actorId: any(named: 'actorId'),
          action: any(named: 'action'),
          entity: any(named: 'entity'),
          entityId: any(named: 'entityId'),
        ),
      ).thenAnswer((_) async {});

      final notifier = container.read(moderationControllerProvider.notifier);
      await notifier.hideReview('rv-1', actorId: 'admin-1');

      verify(() => reviewRepository.hideAsAdmin('rv-1')).called(1);
      verify(
        () => auditLogRepository.log(
          actorId: 'admin-1',
          action: 'hide_review',
          entity: 'review',
          entityId: 'rv-1',
        ),
      ).called(1);
      expect(
        container.read(moderationControllerProvider),
        isA<ModerationEmpty>(),
      );
      expect(crashCalls, isEmpty);
    });

    test('hideReview: auditoria falha -> operação continua concluída, falha só '
        'registrada via AppLogger', () async {
      when(
        () => commentRepository.listAllReports(page: 1, limit: 20),
      ).thenAnswer(
        (_) async => const PagedResult(
          items: [],
          page: 1,
          limit: 20,
          hasNextPage: false,
        ),
      );
      when(() => reviewRepository.hideAsAdmin('rv-1')).thenAnswer((_) async {});
      when(
        () => auditLogRepository.log(
          actorId: any(named: 'actorId'),
          action: any(named: 'action'),
          entity: any(named: 'entity'),
          entityId: any(named: 'entityId'),
        ),
      ).thenThrow(const AuditLogRepositoryException('Falha ao gravar log.'));

      final notifier = container.read(moderationControllerProvider.notifier);
      await notifier.hideReview('rv-1', actorId: 'admin-1');

      expect(
        container.read(moderationControllerProvider),
        isA<ModerationEmpty>(),
      );
      expect(crashCalls, hasLength(1));
      expect(crashCalls.single['level'], AppLogLevel.warning);
      expect(
        crashCalls.single['tag'],
        'administration/ModerationController.hideReview',
      );
    });

    test('hideReview: ação principal falha -> ModerationError, auditoria nunca '
        'chamada', () async {
      when(
        () => reviewRepository.hideAsAdmin('rv-1'),
      ).thenThrow(const ReviewRepositoryException('Avaliação não encontrada.'));

      final notifier = container.read(moderationControllerProvider.notifier);
      await notifier.hideReview('rv-1', actorId: 'admin-1');

      final status = container.read(moderationControllerProvider);
      expect(status, isA<ModerationError>());
      expect((status as ModerationError).message, 'Avaliação não encontrada.');
      verifyNever(
        () => auditLogRepository.log(
          actorId: any(named: 'actorId'),
          action: any(named: 'action'),
          entity: any(named: 'entity'),
          entityId: any(named: 'entityId'),
        ),
      );
      expect(crashCalls, isEmpty);
    });
  });

  test('loadNextPage concatena os itens da nova página aos já carregados em '
      'vez de substituir a lista', () async {
    when(() => commentRepository.listAllReports(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_report(id: 'rep-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(() => commentRepository.listAllReports(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_report(id: 'rep-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    final notifier = container.read(moderationControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(moderationControllerProvider);
    expect(status, isA<ModerationLoaded>());
    expect((status as ModerationLoaded).result.items.map((r) => r.id), [
      'rep-1',
      'rep-2',
    ]);
  });

  test('falha ao buscar a página seguinte preserva os itens já carregados '
      'em vez de virar ModerationError', () async {
    when(() => commentRepository.listAllReports(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_report(id: 'rep-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => commentRepository.listAllReports(page: 2, limit: 20),
    ).thenThrow(const CommentRepositoryException('Falha de rede.'));

    final notifier = container.read(moderationControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage();

    final status = container.read(moderationControllerProvider);
    expect(status, isA<ModerationLoaded>());
    expect((status as ModerationLoaded).result.items.map((r) => r.id), [
      'rep-1',
    ]);
  });

  test('após falha em loadNextPage, uma nova tentativa rebusca a MESMA '
      'página em vez de pular para a seguinte', () async {
    when(() => commentRepository.listAllReports(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_report(id: 'rep-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );
    when(
      () => commentRepository.listAllReports(page: 2, limit: 20),
    ).thenThrow(const CommentRepositoryException('Falha de rede.'));

    final notifier = container.read(moderationControllerProvider.notifier);
    await notifier.load();
    await notifier.loadNextPage(); // página 2 falha

    expect(
      (container.read(moderationControllerProvider) as ModerationLoaded)
          .result
          .items
          .map((r) => r.id),
      ['rep-1'],
    );

    // A segunda tentativa deve rebuscar a página 2 (a que falhou), nunca
    // pular direto para a 3.
    when(() => commentRepository.listAllReports(page: 2, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_report(id: 'rep-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );
    await notifier.loadNextPage();

    final finalStatus = container.read(moderationControllerProvider);
    expect(finalStatus, isA<ModerationLoaded>());
    expect((finalStatus as ModerationLoaded).result.items.map((r) => r.id), [
      'rep-1',
      'rep-2',
    ]);
    verifyNever(() => commentRepository.listAllReports(page: 3, limit: 20));
  });

  test('concorrência entre loadNextPage e hideComment: a resposta '
      'desatualizada do loadNextPage não sobrescreve o resultado mais '
      'recente da mutação', () async {
    when(() => commentRepository.listAllReports(page: 1, limit: 20)).thenAnswer(
      (_) async => PagedResult(
        items: [_report(id: 'rep-1', commentId: 'c-1')],
        page: 1,
        limit: 20,
        hasNextPage: true,
      ),
    );

    final notifier = container.read(moderationControllerProvider.notifier);
    await notifier.load();

    // loadNextPage (página 2) fica pendente, controlado manualmente.
    final page2Completer = Completer<PagedResult<CommentReport>>();
    when(
      () => commentRepository.listAllReports(page: 2, limit: 20),
    ).thenAnswer((_) => page2Completer.future);
    final loadNextPageFuture = notifier.loadNextPage();

    // Enquanto isso, o comentário denunciado é ocultado - hideComment
    // reseta para a página 1 já sem a denúncia resolvida.
    when(() => commentRepository.hideAsAdmin('c-1')).thenAnswer((_) async {});
    when(
      () => auditLogRepository.log(
        actorId: any(named: 'actorId'),
        action: any(named: 'action'),
        entity: any(named: 'entity'),
        entityId: any(named: 'entityId'),
      ),
    ).thenAnswer((_) async {});
    when(() => commentRepository.listAllReports(page: 1, limit: 20)).thenAnswer(
      (_) async =>
          const PagedResult(items: [], page: 1, limit: 20, hasNextPage: false),
    );
    final hideCommentFuture = notifier.hideComment('c-1', actorId: 'admin-1');

    // A resposta da página 2 (mais antiga) chega DEPOIS de hideComment
    // já ter assumido - não deve aparecer no resultado final.
    page2Completer.complete(
      PagedResult(
        items: [_report(id: 'rep-2')],
        page: 2,
        limit: 20,
        hasNextPage: false,
      ),
    );

    await loadNextPageFuture;
    await hideCommentFuture;

    final status = container.read(moderationControllerProvider);
    expect(status, isA<ModerationEmpty>());
  });
}
