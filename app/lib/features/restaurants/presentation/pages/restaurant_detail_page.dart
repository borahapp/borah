import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/image_picker_service.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/app_pulse_icon.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../favorites/application/favorite_toggle_controller.dart';
import '../../../favorites/presentation/states/favorite_toggle_status.dart';
import '../../application/restaurant_detail_controller.dart';
import '../states/restaurant_detail_status.dart';

/// Regras do DV-03 §12: máximo 10 MB, formatos JPG/PNG/WEBP.
const _maxCoverBytes = 10 * 1024 * 1024;
const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

/// Tela de Detalhes (DV-03 §6/UX-02 §9). "Adicionar ao evento" do
/// wireframe pertence ao DV-07 e não é exibido aqui ainda.
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
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      ref
          .read(favoriteToggleControllerProvider.notifier)
          .load(userId, widget.restaurantId);
    });
  }

  void _toggleFavorite() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref
        .read(favoriteToggleControllerProvider.notifier)
        .toggle(userId, widget.restaurantId);
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
    final favoriteStatus = ref.watch(favoriteToggleControllerProvider);
    final isFavorited = switch (favoriteStatus) {
      FavoriteToggleLoaded(:final isFavorited) ||
      FavoriteToggleError(:final isFavorited) => isFavorited,
      _ => false,
    };

    return Scaffold(
      appBar: AppTopBar(
        title: 'Restaurante',
        actions: [
          AppPulseIcon(
            trigger: isFavorited,
            child: AppIconButton(
              icon: isFavorited ? Icons.favorite : Icons.favorite_border,
              tooltip: 'Favoritar restaurante',
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          RestaurantDetailInitial() ||
          RestaurantDetailLoading() ||
          RestaurantDetailSaving() => const LoadingScreen(
            key: ValueKey('loading'),
          ),
          RestaurantDetailError(:final message) => Center(
            key: const ValueKey('error'),
            child: Text(message),
          ),
          RestaurantDetailLoaded(:final restaurant) ||
          RestaurantDetailSaveSuccess(:final restaurant) => _DetailView(
            key: const ValueKey('loaded'),
            name: restaurant.name,
            category: restaurant.category,
            description: restaurant.description,
            address: restaurant.address,
            city: restaurant.city,
            state: restaurant.state,
            averageRating: restaurant.averageRating,
            totalReviews: restaurant.totalReviews,
            onChangeCoverImage: _changeCoverImage,
            onViewReviews: () =>
                context.push('/restaurants/${widget.restaurantId}/reviews'),
          ),
        },
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    super.key,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.averageRating,
    required this.totalReviews,
    required this.onChangeCoverImage,
    required this.onViewReviews,
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
  final VoidCallback onViewReviews;

  @override
  Widget build(BuildContext context) {
    final location = [
      if (address != null && address!.isNotEmpty) address,
      if (city != null && city!.isNotEmpty) city,
      if (state != null && state!.isNotEmpty) state,
    ].join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(category, style: Theme.of(context).textTheme.bodyMedium),
          if (location.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/borah_location.png',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(child: Text(location)),
              ],
            ),
          ],
          if (averageRating != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${averageRating!.toStringAsFixed(1)} ($totalReviews avaliações)',
            ),
          ],
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(child: Text(description!)),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppOutlinedButton(
            label: 'Alterar foto de capa',
            onPressed: onChangeCoverImage,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppOutlinedButton(label: 'Ver avaliações', onPressed: onViewReviews),
        ],
      ),
    );
  }
}
