import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_controller.dart';
import '../states/auth_status.dart';

/// Exibe um snackbar quando o AuthStatus vira AuthError — compartilhado
/// entre Login, Cadastro e Recuperação de Senha para evitar duplicação.
void listenForAuthErrors(WidgetRef ref, BuildContext context) {
  ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
    if (next is AuthError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.message)));
    }
  });
}
