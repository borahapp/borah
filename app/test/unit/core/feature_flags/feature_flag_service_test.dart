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
  late FeatureFlagService service;

  setUp(() {
    repository = MockFeatureFlagRepository();
    service = FeatureFlagService(repository, FeatureFlagCache());
  });

  group('load() — caminho feliz', () {
    test('popula o cache e retorna true', () async {
      when(
        () => repository.fetchAll(),
      ).thenAnswer((_) async => [_flag('new_feed', enabled: true)]);

      final succeeded = await service.load();

      expect(succeeded, isTrue);
      expect(service.hasLoaded, isTrue);
      expect(service.isEnabled('new_feed'), isTrue);
    });
  });

  group('load() — Supabase indisponível (RC-03D §Erros)', () {
    test('retorna false e nunca lança quando o repositório lança', () async {
      when(
        () => repository.fetchAll(),
      ).thenThrow(const FeatureFlagRepositoryException('Falha de rede.'));

      final succeeded = await service.load();

      expect(succeeded, isFalse);
    });

    test(
      'na primeira tentativa (nunca carregou), isEnabled cai no defaultValue',
      () async {
        when(
          () => repository.fetchAll(),
        ).thenThrow(const FeatureFlagRepositoryException('Falha de rede.'));

        await service.load();

        expect(service.isEnabled('maintenance_mode'), isFalse);
        expect(
          service.isEnabled('maintenance_mode', defaultValue: true),
          isTrue,
        );
        expect(service.hasLoaded, isFalse);
      },
    );

    test('depois de um load bem-sucedido, uma falha de refresh mantém o '
        'cache anterior (dado desatualizado, não vazio)', () async {
      when(
        () => repository.fetchAll(),
      ).thenAnswer((_) async => [_flag('new_feed', enabled: true)]);
      await service.load();

      when(
        () => repository.fetchAll(),
      ).thenThrow(const FeatureFlagRepositoryException('Falha de rede.'));
      final refreshed = await service.refresh();

      expect(refreshed, isFalse);
      expect(service.hasLoaded, isTrue);
      expect(service.isEnabled('new_feed'), isTrue);
    });
  });

  group('isEnabled()', () {
    test('retorna false por padrão para flag desconhecida', () async {
      when(() => repository.fetchAll()).thenAnswer((_) async => []);
      await service.load();

      expect(service.isEnabled('flag_que_nao_existe'), isFalse);
    });

    test('respeita o valor real da flag quando carregada', () async {
      when(
        () => repository.fetchAll(),
      ).thenAnswer((_) async => [_flag('enable_admin', enabled: true)]);
      await service.load();

      expect(service.isEnabled('enable_admin'), isTrue);
    });
  });

  group('get()/all', () {
    test('get() retorna a flag completa', () async {
      when(
        () => repository.fetchAll(),
      ).thenAnswer((_) async => [_flag('new_ranking', enabled: true)]);
      await service.load();

      expect(service.get('new_ranking')?.enabled, isTrue);
      expect(service.get('inexistente'), isNull);
    });

    test('all retorna todas as flags carregadas', () async {
      when(() => repository.fetchAll()).thenAnswer(
        (_) async => [_flag('a', enabled: true), _flag('b', enabled: false)],
      );
      await service.load();

      expect(service.all.keys, containsAll(['a', 'b']));
    });
  });
}
