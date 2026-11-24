import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_controller.dart';
import '../data/review_repository_impl.dart';

/// Rodada "perfil individual como centro" (pós-FASE 09) - grade de fotos
/// do usuário logado, para o próprio Perfil. Mesmo padrão de
/// `userReviewsCountProvider`: `FutureProvider` simples, recalcula sozinho
/// em login/logout via `ref.watch(currentUserIdProvider)`.
final userPhotosProvider = FutureProvider<List<String>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(reviewRepositoryProvider).listUserPhotos(userId);
});
