import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_controller.dart';
import '../data/admin_role_repository_impl.dart';

/// Papel administrativo do usuário logado, `null` se não for
/// administrador. Cada tela do painel se protege lendo este provider
/// (`AdminGuard`) - o GoRouter continua conhecendo apenas o
/// `authControllerProvider` (regra mantida desde o DV-01), a verificação
/// de papel fica inteiramente na camada de apresentação do módulo.
final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(adminRoleRepositoryProvider).getRole(userId);
});
