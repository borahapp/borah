import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reviews/data/review_repository_impl.dart';

/// Resolve a primeira foto de uma avaliação sob demanda (FASE SOCIAL 4,
/// requisito de performance: nenhuma das 20 fotos de uma página do Feed é
/// buscada na consulta principal). Como o `SocialFeedCard` só é construído
/// pela `ListView.builder` quando entra na viewport (+ pequena margem de
/// cache), este provider só é lido - e só então dispara `listPhotoUrls` -
/// para cards efetivamente próximos da tela, sem nenhuma biblioteca de
/// detecção de visibilidade. `autoDispose` libera o provider assim que o
/// card sai da árvore (rolagem para longe), evitando acúmulo.
///
/// Reaproveita `ReviewRepository.listPhotoUrls`/bucket `review-photos` já
/// existentes - nenhum Storage/tabela novo.
final feedReviewPhotoProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, reviewId) async {
      final photos = await ref
          .read(reviewRepositoryProvider)
          .listPhotoUrls(reviewId);
      return photos.isEmpty ? null : photos.first;
    });
