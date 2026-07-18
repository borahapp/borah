import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/image_picker_service.dart';
import '../../application/restaurant_detail_controller.dart';
import '../states/restaurant_detail_status.dart';

/// Regras do DV-03 §12: máximo 10 MB, formatos JPG/PNG/WEBP.
const _maxCoverBytes = 10 * 1024 * 1024;
const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

/// Tela de Detalhes (DV-03 §6/UX-02 §9). "Favoritar" e "Adicionar ao
/// evento" do wireframe pertencem a outros módulos (DV-06/DV-07) e não
/// são exibidos aqui ainda.
class RestaurantDetailPage extends ConsumerStatefulWidget {
  const RestaurantDetailPage({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<RestaurantDetailPage> createState() =>
      _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends ConsumerState<RestaurantDetailPage> {
  final _imagePickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(restaurantDetailControllerProvider.notifier)
          .load(widget.restaurantId);
    });
  }

  Future<void> _changeCoverImage() async {
    try {
      final picked = await _imagePickerService.pickAndValidate(
        maxBytes: _maxCoverBytes,
        allowedExtensions: _allowedExtensions,
      );
      if (picked == null) return;
      await ref
          .read(restaurantDetailControllerProvider.notifier)
          .updateCoverImage(
            widget.restaurantId,
            bytes: picked.bytes,
            fileExtension: picked.extension,
          );
    } on ImageValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(restaurantDetailControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurante')),
      body: switch (status) {
        RestaurantDetailInitial() ||
        RestaurantDetailLoading() ||
        RestaurantDetailSaving() => const Center(
          child: CircularProgressIndicator(),
        ),
        RestaurantDetailError(:final message) => Center(child: Text(message)),
        RestaurantDetailLoaded(:final restaurant) ||
        RestaurantDetailSaveSuccess(:final restaurant) => _DetailView(
          name: restaurant.name,
          category: restaurant.category,
          description: restaurant.description,
          address: restaurant.address,
          city: restaurant.city,
          state: restaurant.state,
          averageRating: restaurant.averageRating,
          totalReviews: restaurant.totalReviews,
          onChangeCoverImage: _changeCoverImage,
        ),
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.averageRating,
    required this.totalReviews,
    required this.onChangeCoverImage,
  });

  final String name;
  final String category;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final double? averageRating;
  final int totalReviews;
  final VoidCallback onChangeCoverImage;

  @override
  Widget build(BuildContext context) {
    final location = [
      if (address != null && address!.isNotEmpty) address,
      if (city != null && city!.isNotEmpty) city,
      if (state != null && state!.isNotEmpty) state,
    ].join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(category, style: Theme.of(context).textTheme.bodyMedium),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(location),
          ],
          if (averageRating != null) ...[
            const SizedBox(height: 8),
            Text(
              '${averageRating!.toStringAsFixed(1)} ($totalReviews avaliações)',
            ),
          ],
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(description!),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onChangeCoverImage,
            child: const Text('Alterar foto de capa'),
          ),
        ],
      ),
    );
  }
}
