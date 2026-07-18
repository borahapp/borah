import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(UserProfileStatus status) {
    if (_prefilled) return;
    if (status is ProfileLoaded) {
      _nameController.text = status.profile.fullName ?? '';
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

    ref
        .read(userProfileControllerProvider.notifier)
        .updateProfile(
          userId,
          fullName: _nameController.text.trim(),
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
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextButton(
                  onPressed: () => context.push('/profile/avatar'),
                  child: const Text('Alterar foto'),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _nameController,
                  label: 'Nome',
                  validator: (value) => validateRequired(value, 'seu nome'),
                ),
                const SizedBox(height: 16),
                AppTextField(controller: _bioController, label: 'Biografia'),
                const SizedBox(height: 16),
                AppTextField(controller: _cityController, label: 'Cidade'),
                const SizedBox(height: 16),
                AppTextField(controller: _stateController, label: 'Estado'),
                const SizedBox(height: 24),
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
