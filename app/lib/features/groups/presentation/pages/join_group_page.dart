import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/join_group_controller.dart';
import '../states/join_group_status.dart';

/// Tela de "entrar em grupo por código" (ONBOARDING-01) - formulário
/// único, `context.pop()` sem valor de retorno ao concluir (entrar num
/// grupo já existente não tem o mesmo motivo que `CreateGroupPage` tem,
/// desde a UX-01, para ir direto ao Detalhe: quem entra por código já
/// recebeu o convite de outra pessoa, não precisa compartilhar o
/// próprio). A lista de grupos recarrega ao voltar (mesmo padrão de
/// `GroupsListPage._createGroup`).
class JoinGroupPage extends ConsumerStatefulWidget {
  const JoinGroupPage({super.key});

  @override
  ConsumerState<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends ConsumerState<JoinGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Códigos são sempre gerados em maiúsculas, sem espaços
    // (`generate_group_invite_code()`, GROUP-01) - normaliza aqui para
    // não depender do usuário digitar exatamente como recebeu.
    final code = _codeController.text.trim().toUpperCase();
    ref.read(joinGroupControllerProvider.notifier).join(code);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(joinGroupControllerProvider);
    final isSaving = status is JoinGroupSaving;

    ref.listen<JoinGroupStatus>(joinGroupControllerProvider, (previous, next) {
      if (next is JoinGroupError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is JoinGroupSaveSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Você entrou no grupo "${next.group.name}".')),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Entrar em grupo'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Código de convite'),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _codeController,
                  label: 'Código',
                  validator: (value) => validateRequired(value, 'o código'),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Entrar',
                  isLoading: isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
