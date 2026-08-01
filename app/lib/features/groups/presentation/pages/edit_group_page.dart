import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/components/navigation/section_header.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../application/edit_group_controller.dart';
import '../../domain/group.dart';
import '../states/edit_group_status.dart';

/// Tela de edição de grupo (BLOCO 2) - mesmo padrão de `CreateGroupPage`,
/// pré-preenchida com [group] (recebido via `extra` da rota, sem
/// `getById` redundante - ver `GroupDetailPage._editGroup`). Só
/// nome/descrição - foto do grupo fica fora do escopo, mesma limitação
/// já aceita em `CreateGroupPage` (nenhuma tela do projeto ainda faz
/// upload de foto de grupo).
class EditGroupPage extends ConsumerStatefulWidget {
  const EditGroupPage({super.key, required this.group});

  final Group group;

  @override
  ConsumerState<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends ConsumerState<EditGroupPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.group.name);
  late final _descriptionController = TextEditingController(
    text: widget.group.description ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(editGroupControllerProvider.notifier)
        .update(
          id: widget.group.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          photoUrl: widget.group.photoUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(editGroupControllerProvider);
    final isSaving = status is EditGroupSaving;

    ref.listen<EditGroupStatus>(editGroupControllerProvider, (previous, next) {
      if (next is EditGroupError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is EditGroupSaveSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Grupo atualizado.')));
        context.pop();
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Editar grupo'),
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
                  label: 'Salvar',
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
