import 'package:flutter/material.dart';

import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';

/// Placeholder do Detalhe do Grupo (GROUP-02B.0) — existe apenas como
/// destino de navegação para `/groups/:id` (a partir de `GroupsListPage`)
/// nesta sprint. Sem lógica, sem chamada a repository. A implementação
/// completa (membros, código de convite, compartilhamento) é o
/// GROUP-02B.1, que substitui o corpo desta tela por completo.
///
/// Não usa `EmptyState`: aquele componente comunica "ausência de dados"
/// (ex.: "Você ainda não tem favoritos."), semântica diferente de
/// "funcionalidade ainda não implementada" - usar aqui confundiria as
/// duas situações para o usuário.
class GroupDetailPage extends StatelessWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppTopBar(title: 'Grupo'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Esta tela ainda está em desenvolvimento.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
