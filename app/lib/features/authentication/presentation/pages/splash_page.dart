import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../application/auth_controller.dart';
import '../states/auth_status.dart';

/// Unica responsabilidade (DV-01 SS6 / UX-01 SS4): restaurar a sessao e
/// decidir o redirecionamento inicial. Nenhuma outra logica pertence aqui.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreAndRedirect());
  }

  Future<void> _restoreAndRedirect() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
    if (!mounted) return;

    final status = ref.read(authControllerProvider);
    if (status is Authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: BorahSplashLoader());
  }
}
