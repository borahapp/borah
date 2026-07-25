import 'package:app/core/feature_flags/app_feature_flags.dart';
import 'package:app/core/feature_flags/feature_flag.dart';
import 'package:app/core/feature_flags/feature_flag_cache.dart';
import 'package:app/core/feature_flags/feature_flag_repository.dart';
import 'package:app/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeatureFlagRepository extends Mock implements FeatureFlagRepository {}

FeatureFlag _flag(String key, {bool enabled = false}) {
  return FeatureFlag(
    key: key,
    enabled: enabled,
    updatedAt: DateTime.utc(2026, 7, 25),
  );
}

void main() {
  late MockFeatureFlagRepository repository;

  setUp(() {
    repository = MockFeatureFlagRepository();
    AppFeatureFlags.debugServiceOverride = FeatureFlagService(
      repository,
      FeatureFlagCache(),
    );
  });

  tearDown(() {
    AppFeatureFlags.debugServiceOverride = null;
  });

  test('antes de initialize(), isEnabled() cai no defaultValue (false)', () {
    expect(AppFeatureFlags.isEnabled('new_feed'), isFalse);
    expect(AppFeatureFlags.hasLoaded, isFalse);
  });

  test('initialize() carrega as flags do repositório', () async {
    when(
      () => repository.fetchAll(),
    ).thenAnswer((_) async => [_flag('new_feed', enabled: true)]);

    await AppFeatureFlags.initialize();

    expect(AppFeatureFlags.hasLoaded, isTrue);
    expect(AppFeatureFlags.isEnabled('new_feed'), isTrue);
  });

  test(
    'falha do repositório nunca lança - isEnabled() cai no defaultValue',
    () async {
      when(
        () => repository.fetchAll(),
      ).thenThrow(const FeatureFlagRepositoryException('Falha de rede.'));

      await expectLater(AppFeatureFlags.initialize(), completes);

      expect(AppFeatureFlags.isEnabled('maintenance_mode'), isFalse);
      expect(
        AppFeatureFlags.isEnabled('maintenance_mode', defaultValue: true),
        isTrue,
      );
    },
  );

  test('refresh() busca novamente e atualiza o cache', () async {
    when(
      () => repository.fetchAll(),
    ).thenAnswer((_) async => [_flag('enable_admin', enabled: false)]);
    await AppFeatureFlags.initialize();
    expect(AppFeatureFlags.isEnabled('enable_admin'), isFalse);

    when(
      () => repository.fetchAll(),
    ).thenAnswer((_) async => [_flag('enable_admin', enabled: true)]);
    await AppFeatureFlags.refresh();

    expect(AppFeatureFlags.isEnabled('enable_admin'), isTrue);
  });

  test('get() retorna a flag completa; all retorna todas as flags', () async {
    when(() => repository.fetchAll()).thenAnswer(
      (_) async => [
        _flag('new_feed', enabled: true),
        _flag('new_ranking', enabled: false),
      ],
    );
    await AppFeatureFlags.initialize();

    expect(AppFeatureFlags.get('new_feed')?.enabled, isTrue);
    expect(AppFeatureFlags.get('inexistente'), isNull);
    expect(AppFeatureFlags.all.keys, containsAll(['new_feed', 'new_ranking']));
  });
}
