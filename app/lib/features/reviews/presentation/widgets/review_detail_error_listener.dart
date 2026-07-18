import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/review_detail_controller.dart';
import '../states/review_detail_status.dart';

/// Exibe um snackbar quando o ReviewDetailStatus vira ReviewDetailError -
/// compartilhado entre Criação, Edição e Detalhes para evitar duplicação
/// (mesmo padrão do `listenForAuthErrors` do DV-01).
void listenForReviewDetailErrors(WidgetRef ref, BuildContext context) {
  ref.listen<ReviewDetailStatus>(reviewDetailControllerProvider, (
    previous,
    next,
  ) {
    if (next is ReviewDetailError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.message)));
    }
  });
}
