import 'package:app/core/feature_flags/feature_flag.dart';
import 'package:app/core/feature_flags/feature_flag_cache.dart';
import 'package:flutter_test/flutter_test.dart';

FeatureFlag _flag(String key, {bool enabled = false}) {
  return FeatureFlag(
    key: key,
    enabled: enabled,
    updatedAt: DateTime.utc(2026, 7, 25),
  );
}

void main() {
  group('FeatureFlagCache', () {
    test('hasLoaded é falso antes da primeira atualização', () {
      final cache = FeatureFlagCache();

      expect(cache.hasLoaded, isFalse);
      expect(cache.lastLoadedAt, isNull);
      expect(cache.flags, isEmpty);
    });

    test('update() popula flags indexadas por key e marca hasLoaded', () {
      final cache = FeatureFlagCache();

      cache.update([_flag('new_feed', enabled: true), _flag('new_ranking')]);

      expect(cache.hasLoaded, isTrue);
      expect(cache.lastLoadedAt, isNotNull);
      expect(cache.get('new_feed')?.enabled, isTrue);
      expect(cache.get('new_ranking')?.enabled, isFalse);
      expect(cache.get('inexistente'), isNull);
    });

    test('update() subsequente substitui o conteúdo anterior', () {
      final cache = FeatureFlagCache();

      cache.update([_flag('new_feed', enabled: false)]);
      cache.update([_flag('new_feed', enabled: true)]);

      expect(cache.get('new_feed')?.enabled, isTrue);
      expect(cache.flags, hasLength(1));
    });

    test('flags retorna um mapa não modificável', () {
      final cache = FeatureFlagCache();
      cache.update([_flag('new_feed')]);

      expect(
        () => cache.flags['outra'] = _flag('outra'),
        throwsUnsupportedError,
      );
    });
  });
}
