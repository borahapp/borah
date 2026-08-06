import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/app_icon_size.dart';
import '../../tokens/app_spacing.dart';
import '../../animations/app_motion.dart';

/// Seletor de estrelas do BORAH (RC-03, FASE A1) — substitui o padrão
/// anterior de nota numérica em texto livre (`AppTextField` +
/// `validateRating`) usado em `submit_event_review_page.dart`. É
/// `FormField<int>` para integrar com o `Form`/`validate()` já usado em
/// todo o resto do app, mesmo papel que `AppTextField` cumpre para
/// `TextFormField` — nenhum widget do projeto usa `AlertDialog`/campo
/// cru fora desse padrão, este componente não deveria ser a exceção.
///
/// Toque em uma estrela dispara `HapticFeedback.selectionClick()`
/// (silenciosamente ignorado pela plataforma quando não suportado — a
/// própria API do Flutter já trata isso, sem necessidade de try/catch
/// aqui) e uma animação curta (`AppMotion.fast`/`emphasized`, os mesmos
/// tokens já usados em microinterações de ícone do app) para resposta
/// visual imediata.
class AppStarRating extends FormField<int> {
  AppStarRating({
    super.key,
    required String label,
    int initialValue = 0,
    int starCount = 5,
    ValueChanged<int>? onChanged,
    String? caption,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    FormFieldValidator<int>? validator,
  }) : super(
         initialValue: initialValue,
         validator: validator ?? _defaultValidator,
         builder: (field) {
           return _AppStarRatingContent(
             label: label,
             caption: caption,
             starCount: starCount,
             value: field.value ?? 0,
             errorText: field.errorText,
             onChanged: (next) {
               field.didChange(next);
               onChanged?.call(next);
             },
           );
         },
       );

  static String? _defaultValidator(int? value) {
    if (value == null || value == 0) return 'Escolha uma nota.';
    return null;
  }
}

class _AppStarRatingContent extends StatelessWidget {
  const _AppStarRatingContent({
    required this.label,
    required this.caption,
    required this.starCount,
    required this.value,
    required this.errorText,
    required this.onChanged,
  });

  final String label;
  final String? caption;
  final int starCount;
  final int value;
  final String? errorText;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(caption!, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (var i = 1; i <= starCount; i++)
              _Star(
                filled: i <= value,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
              ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.filled, required this.onTap});

  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onTap,
      icon: AnimatedScale(
        scale: filled ? 1.0 : 0.85,
        duration: AppMotion.scaled(context, AppMotion.fast),
        curve: AppMotion.emphasized,
        child: Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: AppIconSize.lg,
          color: filled ? scheme.tertiary : scheme.outline,
        ),
      ),
    );
  }
}
