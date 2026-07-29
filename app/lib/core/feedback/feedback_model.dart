import 'package:meta/meta.dart';

/// Um feedback enviado por um usuário dentro do app (RC-03E), armazenado
/// na tabela `feedback` do Supabase.
///
/// Estrutura pensada para expansão futura (não limitada a esta rodada):
/// `status` já existe desde já para permitir um fluxo de triagem
/// posterior sem migration adicional (ver
/// `supabase/migrations/20260725110000_create_feedback.sql`).
@immutable
class FeedbackModel {
  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.message,
    this.screenContext,
    this.appVersion,
    this.environment,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String message;
  final String? screenContext;
  final String? appVersion;
  final String? environment;
  final String status;
  final DateTime createdAt;

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      message: map['message'] as String,
      screenContext: map['screen_context'] as String?,
      appVersion: map['app_version'] as String?,
      environment: map['environment'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
