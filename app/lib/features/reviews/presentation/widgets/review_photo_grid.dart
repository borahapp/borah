import 'package:flutter/material.dart';

import '../../../../design_system/components/feedback/app_staggered_list_item.dart';
import '../../../../design_system/components/media/borah_photo_viewer.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';

/// Grade de fotos do perfil (rodada "perfil individual como centro",
/// pós-FASE 09) - reaproveitado pelo próprio Perfil (`ProfilePage`) e
/// pelo Perfil público (`PublicProfilePage`), mesmo critério de extração
/// já aplicado a `ReviewSummaryTile`: nunca acessa datasource/repository,
/// só recebe [photoUrls] já resolvidas por quem chama.
///
/// 3 colunas (grade de verdade, diferente da tira horizontal de
/// `restaurant_detail_page.dart`), tocar numa foto abre
/// `BorahPhotoViewer` já posicionado nela (mesmo componente reutilizado
/// em toda a galeria do app).
class ReviewPhotoGrid extends StatelessWidget {
  const ReviewPhotoGrid({super.key, required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photoUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
      ),
      // Rodada "modernização visual" - entrada escalonada, mesmo
      // componente já usado pela lista de grupos da Home e pelo Feed.
      itemBuilder: (context, index) => AppStaggeredListItem(
        index: index,
        child: GestureDetector(
          onTap: () => BorahPhotoViewer.open(
            context,
            imageUrls: photoUrls,
            initialIndex: index,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.radiusSm,
            child: Image.network(photoUrls[index], fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
