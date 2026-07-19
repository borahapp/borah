import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../application/rankings_controller.dart';
import '../states/rankings_status.dart';

/// Tela de Ranking (DV-05). Geral (sem filtros), por Cidade, por
/// Categoria e Personalizado (cidade + categoria) são a mesma consulta
/// com filtros diferentes - não há abas separadas, só os dois campos de
/// filtro combináveis. Ranking entre Amigos não é exibido (fora de
/// escopo do DV-05 nesta versão).
class RankingsPage extends ConsumerStatefulWidget {
  const RankingsPage({super.key});

  @override
  ConsumerState<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends ConsumerState<RankingsPage> {
  final _cityController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref
        .read(rankingsControllerProvider.notifier)
        .load(
          city: _cityController.text.trim(),
          category: _categoryController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(rankingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppTextField(
                  controller: _cityController,
                  label: 'Cidade (opcional)',
                  onSubmit: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _categoryController,
                  label: 'Categoria (opcional)',
                  onSubmit: (_) => _applyFilters(),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (status) {
              RankingsInitial() || RankingsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              RankingsError(:final message) => Center(child: Text(message)),
              RankingsEmpty() => const Center(
                child: Text('Nenhum restaurante avaliado ainda.'),
              ),
              RankingsLoaded(:final result) => ListView.builder(
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final restaurant = result.items[index];
                  final position = (result.page - 1) * result.limit + index + 1;
                  return ListTile(
                    leading: CircleAvatar(child: Text('$position')),
                    title: Text(restaurant.name),
                    subtitle: Text(
                      [
                        restaurant.category,
                        if (restaurant.city != null) restaurant.city,
                      ].join(' · '),
                    ),
                    trailing: Text(
                      '${restaurant.averageRating?.toStringAsFixed(1)} (${restaurant.totalReviews})',
                    ),
                    onTap: () => context.push('/restaurants/${restaurant.id}'),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}
