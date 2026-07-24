import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/image_picker_service.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/user_profile_controller.dart';
import '../states/user_profile_status.dart';
import '../widgets/profile_avatar.dart';

/// Regras do DV-02 §11: máximo 5 MB, formatos JPG/PNG/WEBP.
const _maxAvatarBytes = 5 * 1024 * 1024;
const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

class ChangeAvatarPage extends ConsumerStatefulWidget {
  const ChangeAvatarPage({super.key});

  @override
  ConsumerState<ChangeAvatarPage> createState() => _ChangeAvatarPageState();
}

class _ChangeAvatarPageState extends ConsumerState<ChangeAvatarPage> {
  final _imagePickerService = ImagePickerService();
  Uint8List? _pickedBytes;
  String? _pickedExtension;

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePickerService.pickAndValidate(
        maxBytes: _maxAvatarBytes,
        allowedExtensions: _allowedExtensions,
      );
      if (picked == null) return;

      setState(() {
        _pickedBytes = picked.bytes;
        _pickedExtension = picked.extension;
      });
    } on ImageValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _upload() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _pickedBytes == null || _pickedExtension == null) {
      return;
    }
    ref
        .read(userProfileControllerProvider.notifier)
        .updateAvatar(
          userId,
          bytes: _pickedBytes!,
          fileExtension: _pickedExtension!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(userProfileControllerProvider);
    final isUploading = status is ProfileUpdating;
    final currentAvatarPath = switch (status) {
      ProfileLoaded(:final profile) ||
      ProfileUpdating(:final profile) ||
      ProfileUpdateSuccess(:final profile) => profile.avatarUrl,
      _ => null,
    };

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
      appBar: const AppTopBar(title: 'Alterar foto'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pickedBytes != null
                  ? CircleAvatar(
                      radius: 64,
                      backgroundImage: MemoryImage(_pickedBytes!),
                    )
                  : ProfileAvatar(avatarPath: currentAvatarPath, radius: 64),
              const SizedBox(height: AppSpacing.xl),
              AppOutlinedButton(
                label: 'Escolher da galeria',
                onPressed: _pickImage,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Salvar foto',
                isLoading: isUploading,
                onPressed: _pickedBytes == null ? null : _upload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
