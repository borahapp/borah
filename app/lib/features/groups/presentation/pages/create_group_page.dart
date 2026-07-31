import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/create_group_controller.dart';
import '../states/create_group_status.dart';

/// Tela de criação de grupo (GROUP-02A). Ao concluir com sucesso, só
/// fecha a própria tela (`context.pop()`, sem valor de retorno) - mesmo
/// padrão já usado por `change_avatar_page.dart`/`edit_profile_page.dart`/
/// `edit_review_page.dart` (nenhuma tela do projeto hoje faz
/// `context.pop(valor)`; introduzir isso agora seria um padrão novo).
/// A navegação para o Detalhe do Grupo fica para o GROUP-02B, cuja tela
/// (ainda inexistente) decide, ao ser reaberta/atualizada, o que fazer
/// com o grupo recém-criado.
class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(createGroupControllerProvider.notifier)
        .create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(createGroupControllerProvider);
    final isSaving = status is CreateGroupSaving;

    ref.listen<CreateGroupStatus>(createGroupControllerProvider, (
      previous,
      next,
    ) {
      if (next is CreateGroupError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is CreateGroupSaveSuccess) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Criar grupo'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Informações do grupo'),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _nameController,
                  label: 'Nome',
                  validator: (value) => validateRequired(value, 'o nome'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Descrição (opcional)',
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Criar grupo',
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
