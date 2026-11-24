import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_controller.dart';
import '../data/review_repository_impl.dart';

/// Rodada "perfil individual como centro" (pós-FASE 09) - quantidade de
/// restaurantes avaliados pelo usuário logado, para o Perfil e a Home.
/// `FutureProvider` simples (mesmo padrão de
/// `unreadNotificationsCountProvider`), não um `Notifier`/status
/// seladado: é um dado derivado de leitura, sem transições de estado
/// próprias para modelar.
///
/// `ref.watch(currentUserIdProvider)` (não `ref.read`) é o que faz este
/// provider recalcular sozinho em login/logout/troca de usuário - mesma
/// razão documentada em `unread_notifications_count_provider.dart`.
final userReviewsCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  return ref.watch(reviewRepositoryProvider).countByUser(userId);
});
