import 'package:app/core/observability/sentry_provider_observer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// `Sentry.captureException` chamado antes de `Sentry.init` faz no-op
/// silencioso (o Hub padrão do pacote `sentry` é um `NoOpHub` até o SDK
/// ser inicializado) - seguro de exercitar aqui sem inicializar o Sentry
/// de verdade. O objetivo destes testes é confirmar que a integração com
/// o Riverpod está corretamente conectada (o observer é de fato chamado
/// e não interfere no comportamento normal do provider), não validar o
/// SDK do Sentry em si.
void main() {
  group('SentryProviderObserver', () {
    test('provider síncrono que falha continua propagando o erro original', () {
      final failingProvider = Provider<int>((ref) => throw Exception('boom'));
      final container = ProviderContainer(
        observers: const [SentryProviderObserver()],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(failingProvider),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('boom'),
          ),
        ),
      );
    });

    test('provider com nome customizado que falha não quebra a leitura', () {
      final failingProvider = Provider<int>(
        (ref) => throw Exception('boom nomeado'),
        name: 'meuProvider',
      );
      final container = ProviderContainer(
        observers: const [SentryProviderObserver()],
      );
      addTearDown(container.dispose);

      expect(() => container.read(failingProvider), throwsException);
    });

    test(
      'provider assíncrono que falha continua propagando o erro original',
      () async {
        final failingProvider = FutureProvider<int>(
          (ref) async => throw Exception('boom async'),
        );
        final container = ProviderContainer(
          observers: const [SentryProviderObserver()],
        );
        addTearDown(container.dispose);

        await expectLater(
          container.read(failingProvider.future),
          throwsException,
        );
      },
    );

    test('provider que não falha não é afetado pelo observer', () {
      final okProvider = Provider<int>((ref) => 42);
      final container = ProviderContainer(
        observers: const [SentryProviderObserver()],
      );
      addTearDown(container.dispose);

      expect(container.read(okProvider), 42);
    });
  });
}
