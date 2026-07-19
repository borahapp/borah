import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/models/paged_result.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/comment.dart';
import '../domain/comment_report.dart';
import '../domain/comment_repository.dart';
import 'comment_remote_datasource.dart';

class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl(this._datasource);

  final CommentRemoteDatasource _datasource;

  @override
  Future<PagedResult<Comment>> listByReview(
    String reviewId, {
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listByReview(
        reviewId,
        page: page,
        limit: limit,
      );

      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      return PagedResult<Comment>(
        items: pageRows.map(_mapRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  @override
  Future<Comment> create({
    required String reviewId,
    required String userId,
    required String content,
  }) {
    return _guard(() async {
      final row = await _datasource.insert({
        'review_id': reviewId,
        'user_id': userId,
        'content': content,
      });
      return _mapRow(row);
    });
  }

  @override
  Future<Comment> update(String id, {required String content}) {
    return _guard(() async {
      final row = await _datasource.updateContent(id, content);
      return _mapRow(row);
    });
  }

  @override
  Future<void> delete(String id) {
    return _guard(() => _datasource.softDelete(id));
  }

  @override
  Future<void> report(
    String commentId, {
    required String reportedBy,
    required String reason,
  }) {
    return _guard(() => _datasource.report(commentId, reportedBy, reason));
  }

  @override
  Future<void> hideAsAdmin(String id) {
    return _guard(() => _datasource.softDelete(id));
  }

  @override
  Future<PagedResult<CommentReport>> listAllReports({
    required int page,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await _datasource.listAllReports(page: page, limit: limit);

      final hasNextPage = rows.length > limit;
      final pageRows = hasNextPage ? rows.sublist(0, limit) : rows;

      return PagedResult<CommentReport>(
        items: pageRows.map(_mapReportRow).toList(),
        page: page,
        limit: limit,
        hasNextPage: hasNextPage,
      );
    });
  }

  CommentReport _mapReportRow(Map<String, dynamic> row) {
    return CommentReport(
      id: row['id'] as String,
      commentId: row['comment_id'] as String,
      reportedBy: row['reported_by'] as String,
      reason: row['reason'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Comment _mapRow(Map<String, dynamic> row) {
    return Comment(
      id: row['id'] as String,
      reviewId: row['review_id'] as String,
      userId: row['user_id'] as String,
      content: row['content'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw CommentRepositoryException(e.message);
    }
  }
}

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CommentRepositoryImpl(CommentRemoteDatasource(client));
});
