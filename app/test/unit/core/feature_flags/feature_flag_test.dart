import 'package:app/core/feature_flags/feature_flag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureFlag.fromMap', () {
    test('constrói a partir de uma linha completa do Supabase', () {
      final flag = FeatureFlag.fromMap({
        'id': 'f1',
        'key': 'new_feed',
        'enabled': true,
        'description': 'Nova versão do Feed',
        'created_at': '2026-07-25T10:00:00.000Z',
        'updated_at': '2026-07-25T12:00:00.000Z',
      });

      expect(flag.key, 'new_feed');
      expect(flag.enabled, isTrue);
      expect(flag.description, 'Nova versão do Feed');
      expect(flag.updatedAt, DateTime.parse('2026-07-25T12:00:00.000Z'));
    });

    test('description nula quando ausente na linha', () {
      final flag = FeatureFlag.fromMap({
        'id': 'f1',
        'key': 'maintenance_mode',
        'enabled': false,
        'description': null,
        'updated_at': '2026-07-25T12:00:00.000Z',
      });

      expect(flag.description, isNull);
      expect(flag.enabled, isFalse);
    });
  });
}
