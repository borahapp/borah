import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/application/auth_controller.dart';

/// Tela de Configurações (UX-02 §15). Mostra apenas os itens com ação real
/// nesta etapa: "Editar perfil" e "Sair". Os demais itens do wireframe
/// (Notificações, Privacidade, Segurança, Idioma) não têm modelo de dados
/// correspondente no DV-02 — mesma lacuna documental já registrada para a
/// tela "Preferências" — e não serão exibidos como placeholders sem
/// persistência.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Editar perfil'),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
