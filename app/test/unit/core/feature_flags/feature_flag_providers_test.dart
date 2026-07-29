import 'package:app/core/feature_flags/feature_flag.dart';
import 'package:app/core/feature_flags/feature_flag_providers.dart';
import 'package:app/core/feature_flags/feature_flag_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late ProviderContainer container;

  setUp(() {
    repository = MockFeatureFlagRepository();
    container = ProviderContainer(
      overrides: [featureFlagRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FeatureFlagsInitial', () {
    expect(
      container.read(featureFlagsControllerProvider),
      isA<FeatureFlagsInitial>(),
    );
  });

  group('load()', () {
    test('sucesso -> FeatureFlagsLoaded com degraded=false', () async {
      when(
        () => repository.fetchAll(),
      ).thenAnswer((_) async => [_flag('new_feed', enabled: true)]);

      await container.read(featureFlagsControllerProvider.notifier).load();

      final status = container.read(featureFlagsControllerProvider);
      expect(status, isA<FeatureFlagsLoaded>());
      final loaded = status as FeatureFlagsLoaded;
      expect(loaded.degraded, isFalse);
      expect(loaded.flags['new_feed']?.enabled, isTrue);
    });

    test('falha do repositório -> FeatureFlagsLoaded com degraded=true (nunca '
        'um estado de erro que bloqueia a tela)', () async {
      when(
        () => repository.fetchAll(),
      ).thenThrow(const FeatureFlagRepositoryException('Falha de rede.'));

      await container.read(featureFlagsControllerProvider.notifier).load();

      final status = container.read(featureFlagsControllerProvider);
      expect(status, isA<FeatureFlagsLoaded>());
      expect((status as FeatureFlagsLoaded).degraded, isTrue);
      expect(status.flags, isEmpty);
    });

    test('refresh() após sucesso, seguido de falha, mantém degraded=true '
        'mas preserva as flags já carregadas', () async {
      when(
        () => repository.fetchAll(),
      ).thenAnswer((_) async => [_flag('new_feed', enabled: true)]);
      final notifier = container.read(featureFlagsControllerProvider.notifier);
      await notifier.load();

      when(
        () => repository.fetchAll(),
      ).thenThrow(const FeatureFlagRepositoryException('Falha de rede.'));
      await notifier.refresh();

      final status =
          container.read(featureFlagsControllerProvider) as FeatureFlagsLoaded;
      expect(status.degraded, isTrue);
      expect(status.flags['new_feed']?.enabled, isTrue);
    });
  });

  test('isEnabled() delega para o serviço subjacente', () async {
    when(
      () => repository.fetchAll(),
    ).thenAnswer((_) async => [_flag('enable_admin', enabled: true)]);
    final notifier = container.read(featureFlagsControllerProvider.notifier);
    await notifier.load();

    expect(notifier.isEnabled('enable_admin'), isTrue);
    expect(notifier.isEnabled('flag_desconhecida'), isFalse);
  });
}
