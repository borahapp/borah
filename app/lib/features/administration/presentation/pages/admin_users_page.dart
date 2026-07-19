import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../application/admin_users_controller.dart';
import '../states/admin_users_status.dart';
import '../widgets/admin_guard.dart';

/// Gestão de Usuários (DV-08 §6): apenas "Consultar". "Visualizar
/// histórico" é a própria tela de Perfil público (DV-07), que já lista as
/// avaliações do usuário. "Bloquear/Reativar" fora de escopo.
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUsersControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search() {
    ref
        .read(adminUsersControllerProvider.notifier)
        .load(query: _queryController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adminUsersControllerProvider);

    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Usuários')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _queryController,
                label: 'Buscar por nome',
                onSubmit: (_) => _search(),
              ),
            ),
            Expanded(
              child: switch (status) {
                AdminUsersInitial() || AdminUsersLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                AdminUsersError(:final message) => Center(child: Text(message)),
                AdminUsersEmpty() => const Center(
                  child: Text('Nenhum usuário encontrado.'),
                ),
                AdminUsersLoaded(:final result) => ListView.builder(
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final profile = result.items[index];
                    return ListTile(
                      title: Text(profile.fullName ?? ''),
                      subtitle: profile.city != null
                          ? Text(profile.city!)
                          : null,
                      onTap: () => context.push('/users/${profile.id}'),
                    );
                  },
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
