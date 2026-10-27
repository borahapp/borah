import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_controller.dart';
import '../data/notification_repository_impl.dart';

/// FASE 05 - contagem de notificações não lidas para o sino da Home.
/// `FutureProvider` simples (mesmo padrão de `rotationSuggestionProvider`),
/// não um `Notifier`/status seladado: é um dado derivado de leitura, sem
/// transições de estado próprias para modelar.
///
/// `ref.watch(currentUserIdProvider)` (não `ref.read`) é o que faz este
/// provider recalcular sozinho em login/logout/troca de usuário - sem
/// isso, a contagem do usuário anterior ficaria presa até a próxima
/// invalidação manual. Nenhum mecanismo de sessão novo: reaproveita a
/// mesma reatividade que `currentUserIdProvider` já oferece a qualquer
/// consumidor.
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  return ref.watch(notificationRepositoryProvider).countUnread(userId);
});
