import 'user_progress.dart';

/// Uma linha do Ranking de Usuários (DV-10 §5) - o progresso do usuário
/// com o nome para exibição. `fullName` nulo indica que o perfil não pôde
/// ser resolvido (mesma tolerância usada em `FollowerRepositoryImpl`).
class RankingEntry {
  const RankingEntry({required this.progress, this.fullName});

  final UserProgress progress;
  final String? fullName;
}
