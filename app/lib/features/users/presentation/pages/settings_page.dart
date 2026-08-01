import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/feedback_dialog.dart';
import '../../../../design_system/components/dialogs/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../authentication/domain/auth_repository.dart';
import '../../../authentication/presentation/states/auth_status.dart';
import '../../data/user_profile_repository_impl.dart';
import '../widgets/account_deletion_dialog.dart';

/// Tela de Configurações (UX-02 §15). Mostra apenas os itens com ação real
/// nesta etapa: "Editar perfil", "Enviar feedback" (RC-03E), "Excluir
/// conta" (RC-04C) e "Sair". Os demais itens do wireframe (Notificações,
/// Privacidade, Segurança, Idioma) não têm modelo de dados correspondente
/// no DV-02 — mesma lacuna documental já registrada para a tela
/// "Preferências" — e não serão exibidos como placeholders sem persistência.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sair',
      message: 'Deseja realmente encerrar a sessão?',
      confirmLabel: 'Sair',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _isSigningOut = true);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      // Sucesso navega para fora desta tela via redirect do router (a
      // sessão vira Unauthenticated) - resetar aqui é só defensivo, para
      // o caso de a tela permanecer montada por qualquer motivo.
      if (mounted) setState(() => _isSigningOut = false);
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível encerrar a sessão.')),
      );
    }
  }

  /// Busca o `avatarUrl` atual (se houver) para a limpeza de Storage do
  /// fluxo de exclusão (RC-04C) — uma consulta avulsa ao repositório, não
  /// depende de `userProfileControllerProvider` já ter carregado o
  /// perfil nesta tela. Falha aqui não impede a exclusão em si (ver
  /// `AccountDeletionController` — limpeza de Storage é best-effort).
  Future<void> _openAccountDeletion() async {
    final authStatus = ref.read(authControllerProvider);
    if (authStatus is! Authenticated || authStatus.email == null) return;

    String? avatarPath;
    try {
      final profile = await ref
          .read(userProfileRepositoryProvider)
          .getProfile(authStatus.userId);
      avatarPath = profile.avatarUrl;
    } catch (_) {
      // Segue sem avatarPath - ver documentação do método.
    }

    if (!mounted) return;
    await AccountDeletionDialog.show(
      context,
      email: authStatus.email!,
      avatarPath: avatarPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Configurações'),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Editar perfil'),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Enviar feedback'),
            onTap: () {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null) return;
              FeedbackDialog.show(
                context,
                userId: userId,
                screenContext: 'settings',
              );
            },
          ),
          ListTile(
            leading: _isSigningOut
                ? const LoadingIndicator()
                : const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: _isSigningOut ? null : _signOut,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Excluir conta'),
            onTap: _openAccountDeletion,
          ),
        ],
      ),
    );
  }
}
