import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_primary_button.dart';
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
  Uint8List? _pickedBytes;
  String? _pickedExtension;

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > _maxAvatarBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A imagem deve ter no máximo 5 MB.')),
      );
      return;
    }

    final extension = file.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato não suportado. Use JPG, PNG ou WEBP.'),
        ),
      );
      return;
    }

    setState(() {
      _pickedBytes = bytes;
      _pickedExtension = extension;
    });
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
      appBar: AppBar(title: const Text('Alterar foto')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pickedBytes != null
                  ? CircleAvatar(
                      radius: 64,
                      backgroundImage: MemoryImage(_pickedBytes!),
                    )
                  : ProfileAvatar(avatarPath: currentAvatarPath, radius: 64),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _pickImage,
                child: const Text('Escolher da galeria'),
              ),
              const SizedBox(height: 16),
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
