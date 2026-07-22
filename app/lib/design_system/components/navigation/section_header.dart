import 'package:flutter/material.dart';

/// Cabeçalho de seção do BORAH — título + ação opcional à direita
/// (ex.: "Ver tudo"). Estilo de texto vem de `Theme.of(context)`
/// (`textTheme.titleMedium`, Fredoka).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;

  /// Ex.: `AppTextButton(label: 'Ver tudo', onPressed: ...)`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?action,
      ],
    );
  }
}
