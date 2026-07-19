import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(
        body: Center(child: Text('Não foi possível verificar permissões.')),
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
