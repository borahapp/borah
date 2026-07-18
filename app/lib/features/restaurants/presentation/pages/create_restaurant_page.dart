import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/restaurant_detail_controller.dart';
import '../states/restaurant_detail_status.dart';

/// Tela de Cadastro (DV-03 §5/§6). Expõe apenas os campos que existem no
/// modelo de dados aprovado (§9): CEP, horário, contato, website e redes
/// sociais aparecem na lista de funcionalidades do §5, mas não têm coluna
/// correspondente na tabela — não seriam persistidos, por isso não
/// aparecem no formulário (mesma lógica já aplicada às demais lacunas
/// documentais do projeto). Latitude/longitude ficam para quando houver
/// seleção via mapa (DV-03 §19, "Evolução prevista").
class CreateRestaurantPage extends ConsumerStatefulWidget {
  const CreateRestaurantPage({super.key});

  @override
  ConsumerState<CreateRestaurantPage> createState() =>
      _CreateRestaurantPageState();
}

class _CreateRestaurantPageState extends ConsumerState<CreateRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    ref
        .read(restaurantDetailControllerProvider.notifier)
        .create(
          createdBy: userId,
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          description: _descriptionController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          stateProvince: _stateController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(restaurantDetailControllerProvider);
    final isSaving = status is RestaurantDetailSaving;

    ref.listen<RestaurantDetailStatus>(restaurantDetailControllerProvider, (
      previous,
      next,
    ) {
      if (next is RestaurantDetailError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is RestaurantDetailSaveSuccess) {
        context.pushReplacement('/restaurants/${next.restaurant.id}');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar restaurante')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Nome',
                  validator: (value) => validateRequired(value, 'o nome'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _categoryController,
                  label: 'Categoria',
                  validator: (value) => validateRequired(value, 'a categoria'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Descrição (opcional)',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _addressController,
                  label: 'Endereço (opcional)',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _cityController,
                  label: 'Cidade (opcional)',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _stateController,
                  label: 'Estado (opcional)',
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Cadastrar',
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
