import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root router (AR-02). Only the bootstrap placeholder route exists here —
/// feature routes are added as each DV-xx module is implemented.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _BootstrapPlaceholderPage(),
      ),
    ],
  );
});

class _BootstrapPlaceholderPage extends StatelessWidget {
  const _BootstrapPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('BORAH')));
  }
}
