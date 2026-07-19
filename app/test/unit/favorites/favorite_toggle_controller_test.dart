import 'package:app/features/favorites/application/favorite_toggle_controller.dart';
import 'package:app/features/favorites/data/favorite_repository_impl.dart';
import 'package:app/features/favorites/domain/favorite_repository.dart';
import 'package:app/features/favorites/presentation/states/favorite_toggle_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

void main() {
  late MockFavoriteRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFavoriteRepository();
    container = ProviderContainer(
      overrides: [favoriteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial é FavoriteToggleInitial', () {
    expect(
      container.read(favoriteToggleControllerProvider),
      isA<FavoriteToggleInitial>(),
    );
  });

  group('load', () {
    test('não favoritado -> FavoriteToggleLoaded(false)', () async {
      when(
        () => repository.isFavorited('user-1', 'r-1'),
      ).thenAnswer((_) async => false);

      await container
          .read(favoriteToggleControllerProvider.notifier)
          .load('user-1', 'r-1');

      final status = container.read(favoriteToggleControllerProvider);
      expect(status, isA<FavoriteToggleLoaded>());
      expect((status as FavoriteToggleLoaded).isFavorited, isFalse);
    });
  });

  group('toggle', () {
    test('favorita otimisticamente antes da resposta do repositório', () async {
      when(
        () => repository.isFavorited('user-1', 'r-1'),
      ).thenAnswer((_) async => false);
      when(
        () => repository.addFavorite('user-1', 'r-1'),
      ).thenAnswer((_) async {});

      final notifier = container.read(
        favoriteToggleControllerProvider.notifier,
      );
      await notifier.load('user-1', 'r-1');

      final toggleFuture = notifier.toggle('user-1', 'r-1');
      // Atualização otimista: já reflete `true` antes do await concluir.
      expect(
        (container.read(favoriteToggleControllerProvider)
                as FavoriteToggleLoaded)
            .isFavorited,
        isTrue,
      );
      await toggleFuture;

      final status = container.read(favoriteToggleControllerProvider);
      expect(status, isA<FavoriteToggleLoaded>());
      expect((status as FavoriteToggleLoaded).isFavorited, isTrue);
      verify(() => repository.addFavorite('user-1', 'r-1')).called(1);
    });

    test('reverte para o valor anterior quando o repositório falha', () async {
      when(
        () => repository.isFavorited('user-1', 'r-1'),
      ).thenAnswer((_) async => false);
      when(
        () => repository.addFavorite('user-1', 'r-1'),
      ).thenThrow(const FavoriteRepositoryException('Falha ao favoritar.'));

      final notifier = container.read(
        favoriteToggleControllerProvider.notifier,
      );
      await notifier.load('user-1', 'r-1');
      await notifier.toggle('user-1', 'r-1');

      final status = container.read(favoriteToggleControllerProvider);
      expect(status, isA<FavoriteToggleError>());
      expect((status as FavoriteToggleError).isFavorited, isFalse);
    });
  });
}
