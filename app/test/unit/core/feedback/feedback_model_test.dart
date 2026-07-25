import 'package:app/core/feedback/feedback_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackModel.fromMap', () {
    test('constrói a partir de uma linha completa do Supabase', () {
      final feedback = FeedbackModel.fromMap({
        'id': 'f1',
        'user_id': 'u1',
        'message': 'Adorei o app!',
        'screen_context': 'settings',
        'app_version': '1.0.0+1',
        'environment': 'production',
        'status': 'new',
        'created_at': '2026-07-25T12:00:00.000Z',
      });

      expect(feedback.id, 'f1');
      expect(feedback.userId, 'u1');
      expect(feedback.message, 'Adorei o app!');
      expect(feedback.screenContext, 'settings');
      expect(feedback.appVersion, '1.0.0+1');
      expect(feedback.environment, 'production');
      expect(feedback.status, 'new');
      expect(feedback.createdAt, DateTime.parse('2026-07-25T12:00:00.000Z'));
    });

    test('campos opcionais nulos quando ausentes na linha', () {
      final feedback = FeedbackModel.fromMap({
        'id': 'f1',
        'user_id': 'u1',
        'message': 'Sem contexto extra.',
        'screen_context': null,
        'app_version': null,
        'environment': null,
        'status': 'new',
        'created_at': '2026-07-25T12:00:00.000Z',
      });

      expect(feedback.screenContext, isNull);
      expect(feedback.appVersion, isNull);
      expect(feedback.environment, isNull);
    });
  });
}
