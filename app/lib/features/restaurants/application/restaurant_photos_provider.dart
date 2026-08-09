import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reviews/data/review_repository_impl.dart';

/// RC-03 F14 - fotos agregadas das avaliações individuais do restaurante
/// (ver `ReviewRepository.listRestaurantPhotos`). Puramente informativo -
/// `restaurant_detail_page.dart` continua funcionando normalmente sem
/// nenhuma foto.
final restaurantPhotosProvider = FutureProvider.family<List<String>, String>((
  ref,
  restaurantId,
) {
  return ref.watch(reviewRepositoryProvider).listRestaurantPhotos(restaurantId);
});
