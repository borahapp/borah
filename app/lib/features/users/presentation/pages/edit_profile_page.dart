import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/user_profile_controller.dart';
import '../states/user_profile_status.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(UserProfileStatus status) {
    if (_prefilled) return;
    if (status is ProfileLoaded) {
      _nameController.text = status.profile.fullName ?? '';
      _usernameController.text = status.profile.username ?? '';
      _bioController.text = status.profile.bio ?? '';
      _cityController.text = status.profile.city ?? '';
      _stateController.text = status.profile.state ?? '';
      _prefilled = true;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final usernameText = _usernameController.text.trim();
    ref
        .read(userProfileControllerProvider.notifier)
        .updateProfile(
          userId,
          fullName: _nameController.text.trim(),
          // FASE SOCIAL 2 - `username` continua nullable no banco; um
          // campo vazio aqui significa "não alterar" (ver doc-comment
          // de `UserProfileRepositoryImpl.updateProfile`), não "remover
          // o username já salvo" - remoção não foi pedida nesta fase.
          username: usernameText.isEmpty ? null : usernameText,
          bio: _bioController.text.trim(),
          city: _cityController.text.trim(),
          stateProvince: _stateController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(userProfileControllerProvider);
    _prefillIfNeeded(status);
    final isSaving = status is ProfileUpdating;

    ref.listen<UserProfileStatus>(userProfileControllerProvider, (
      previous,
      next,
    ) {
      if (next is ProfileError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is ProfileUpdateSuccess) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'Editar perfil'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextButton(
                  label: 'Alterar foto',
                  onPressed: () => context.push('/profile/avatar'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _nameController,
                  label: 'Nome',
                  validator: (value) => validateRequired(value, 'seu nome'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _usernameController,
                  label: 'Nome de usuário (opcional)',
                  validator: validateUsername,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _bioController, label: 'Biografia'),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _cityController, label: 'Cidade'),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _stateController, label: 'Estado'),
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
