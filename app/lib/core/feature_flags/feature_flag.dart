import 'package:meta/meta.dart';

/// Uma Feature Flag do BORAH (RC-03D) — configuração remota simples de
/// liga/desliga, armazenada na tabela `feature_flags` do Supabase.
///
/// Estrutura pensada para expansão futura (não limitada às flags desta
/// rodada): hoje cobre um booleano por ambiente; rollout percentual,
/// segmentação por usuário ou payload JSON ficam para quando houver um
/// consumidor real (ver RC-03D_FEATURE_FLAGS.md).
@immutable
class FeatureFlag {
  const FeatureFlag({
    required this.key,
    required this.enabled,
    this.description,
    required this.updatedAt,
  });

  /// Identificador único e estável (ex.: `maintenance_mode`) — usado em
  /// todo o app para consultar a flag, nunca o `id` (UUID interno da
  /// tabela).
  final String key;

  final bool enabled;
  final String? description;
  final DateTime updatedAt;

  factory FeatureFlag.fromMap(Map<String, dynamic> map) {
    return FeatureFlag(
      key: map['key'] as String,
      enabled: map['enabled'] as bool,
      description: map['description'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
