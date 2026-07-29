import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../application/current_user_role_provider.dart';

/// Protege as telas do painel administrativo (DV-08). O GoRouter continua
/// conhecendo apenas o `authControllerProvider` (regra mantida desde o
/// DV-01) - a checagem de papel fica aqui, na apresentação, não no router.
class AdminGuard extends ConsumerWidget {
  const AdminGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => const Scaffold(body: LoadingScreen()),
      error: (_, _) => Scaffold(
        body: ErrorState(
          message: 'Não foi possível verificar permissões.',
          onRetry: () => ref.invalidate(currentUserRoleProvider),
        ),
      ),
      data: (role) {
        if (role == null) {
          return const Scaffold(
            body: Center(child: Text('Acesso restrito a administradores.')),
          );
        }
        return child;
      },
    );
  }
}
