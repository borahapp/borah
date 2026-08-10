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

/// Tela de criação de grupo (GROUP-02A). Ao concluir com sucesso, navega
/// direto para o Detalhe do Grupo recém-criado (UX-01) - mesmo padrão já
/// usado por `CreateRestaurantPage`/`CreateReviewPage`
/// (`context.pushReplacement('/.../${next.id}')`, sem snackbar
/// intermediário: a própria tela de destino já é a confirmação). Antes
/// desta rodada a tela só fechava (`context.pop()`) e o usuário caía de
/// volta na lista - obrigando a tocar no grupo de novo para achar o
/// código de convite, exatamente no momento em que ele está mais
/// disposto a convidar alguém (achado da auditoria de produto, UX-01
/// §2.2 do `BORAH_BETA_PLAYBOOK.md`).
class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // FASE SOCIAL 3 - privado é o padrão: nenhum grupo se torna público
  // sem escolha explícita do criador (mesmo requisito que garante que
  // todo grupo já existente continua privado).
  String _visibility = 'private';

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
          visibility: _visibility,
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
        // UX-01: vai direto para o Detalhe do Grupo (`extra: true` sinaliza
        // "acabou de ser criado" - ver GroupDetailPage) em vez de fechar a
        // tela. Sem snackbar aqui de propósito - o diálogo de
        // "Grupo criado com sucesso" na tela de destino já cobre o
        // feedback, mesmo padrão de `CreateRestaurantPage`/`CreateReviewPage`
        // (nenhuma das duas mostra snackbar antes de navegar para o
        // detalhe recém-criado).
        context.pushReplacement('/groups/${next.group.id}', extra: true);
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
                const SectionHeader(title: 'Visibilidade'),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'private', label: Text('Privado')),
                    ButtonSegment(value: 'public', label: Text('Público')),
                  ],
                  selected: {_visibility},
                  onSelectionChanged: (selection) =>
                      setState(() => _visibility = selection.first),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _visibility == 'public'
                      ? 'Aparece na busca para qualquer pessoa.'
                      : 'Só quem tiver o convite encontra o grupo.',
                  style: Theme.of(context).textTheme.bodySmall,
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
