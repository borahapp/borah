import 'package:flutter/material.dart';

import '../../../../design_system/components/cards/app_card.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../domain/event.dart';

/// Cards de "Memórias" (BLOCO 6/F44-F45) derivados de uma lista de
/// rolês já realizados - "mais visitado", "campeão" (por nota média,
/// agregada por restaurante, nunca por rolê individual, ver QA-13) e
/// "quem mais escolheu" (por `Event.organizerId`, FASE B Entrega 3).
///
/// "Quem mais escolheu" mostra só a contagem (ex.: "3 rolês pela mesma
/// pessoa"), nunca o nome de quem organizou - decisão explícita do
/// usuário ao aprovar a Entrega 3: resolver nome a partir de
/// `organizerId` exigiria uma consulta de perfil extra (não existe FK
/// direta de `events.organizer_id` para `profiles`, mesma limitação já
/// documentada em `GroupRemoteDatasource.fetchProfilesByIds`), o que
/// violaria o contrato desta classe (nunca busca dado sozinha) e
/// exigiria mudança nos 2 consumidores - ambos fora do escopo aprovado
/// para esta entrega. Resolver o nome fica registrado como melhoria
/// futura, não esquecida.
///
/// FASE B, Entrega 2: extraído de `_EventsList._memoryCards()`
/// (`events_list_page.dart`) e `_MemoriesContent._buildMemoryCards()`
/// (`group_hub_page.dart`) - as duas cópias criadas deliberadamente na
/// Entrega 1 (regra combinada: extrair um componente compartilhado só
/// quando existirem 2 consumidores reais) eram, byte a byte, o mesmo
/// cálculo e a mesma árvore de widgets - nenhum dos dois lados precisou
/// mudar de comportamento para convergir aqui.
///
/// ### Contrato (o mesmo já documentado na Entrega 1, agora cumprido)
///
/// Responsabilidades - o que esta classe FAZ:
/// - Recebe a lista de rolês já filtrada como "realizados" - quem
///   chama filtra (cada tela tem seu próprio filtro hoje, ver
///   `_EventsList`/`_MemoriesContent`), esta classe nunca decide
///   sozinha o que conta como realizado.
/// - Agrega e renderiza as métricas de memória a partir dessa lista -
///   hoje: "mais visitado", "campeão" e "quem mais escolheu".
/// - Reutilizável por qualquer tela que já tenha a lista de rolês do
///   grupo carregada - hoje: `EventsListPage`, `GroupHubPage`.
///
/// O que esta classe NUNCA deve fazer, sob nenhuma justificativa futura:
/// - Nunca buscar dado sozinha - sem `ref.watch`/`ref.read` de nenhum
///   provider, sem repositório, sem controller próprio. Recebe
///   `List<Event>` já carregada por parâmetro, mesma regra já aplicada
///   a `RankingCard`/`EventCard` (componentes "burros").
/// - Nunca decidir navegação (`context.push`/`context.go`) - nenhum
///   card aqui tem `onTap` hoje; se um dia precisar, delega via
///   callback, nunca decide sozinha para onde ir.
/// - Nunca conhecer "grupo" ou "usuário atual" diretamente - só
///   recebe a lista já filtrada.
/// - Nunca crescer por antecipação - um parâmetro/métrica nova só
///   entra quando essa métrica for de fato implementada numa entrega
///   real (nunca "para o caso de precisar depois").
/// - Nunca decidir o espaçamento externo (padding/margem) ao redor do
///   próprio conteúdo - devolve só os cards; a moldura ao redor é
///   responsabilidade de cada tela chamadora, porque cada uma já
///   compõe esse conteúdo dentro de um layout próprio e diferente
///   (`ListView` com outras seções em `EventsListPage`; aba isolada em
///   `GroupHubPage`) - é por isso que as duas cópias da Entrega 1 já
///   aplicavam o padding externo de formas diferentes, e continuam
///   assim depois desta extração, cada uma no próprio arquivo.
abstract final class EventMemoryCards {
  /// Nunca lança para lista vazia - devolve `[]` (mesma garantia que já
  /// existia na cópia de `group_hub_page.dart` desde a Entrega 1;
  /// `events_list_page.dart` nunca chamava com lista vazia porque já
  /// guardava com `if (realized.isNotEmpty)` antes de chamar - continua
  /// guardando assim, sem alteração).
  static List<Widget> build(BuildContext context, List<Event> realized) {
    if (realized.isEmpty) return const [];

    final visitCounts = <String, int>{};
    final nameByRestaurant = <String, String>{};
    for (final event in realized) {
      visitCounts.update(event.restaurantId, (v) => v + 1, ifAbsent: () => 1);
      nameByRestaurant[event.restaurantId] = event.restaurantName ?? '';
    }
    final mostVisitedId = visitCounts.entries
        .reduce((a, b) => b.value > a.value ? b : a)
        .key;
    final mostVisitedCount = visitCounts[mostVisitedId]!;

    // QA-13 (RC): "Campeão" é o RESTAURANTE com a melhor nota - não o
    // rolê individual mais bem avaliado. Agrega por restaurante antes
    // de decidir o campeão - mesmo padrão da aba Estatísticas de
    // `group_hub_page.dart`.
    final ratingByRestaurant =
        <String, ({String name, double ratingSum, int ratingCount})>{};
    for (final event in realized) {
      final rating = event.averageRating;
      if (rating == null) continue;
      final current = ratingByRestaurant[event.restaurantId];
      ratingByRestaurant[event.restaurantId] = (
        name: event.restaurantName ?? '',
        ratingSum: (current?.ratingSum ?? 0) + rating,
        ratingCount: (current?.ratingCount ?? 0) + 1,
      );
    }
    String? championName;
    double? championAverage;
    for (final entry in ratingByRestaurant.values) {
      final average = entry.ratingSum / entry.ratingCount;
      if (championAverage == null || average > championAverage) {
        championName = entry.name;
        championAverage = average;
      }
    }

    // "Quem mais escolheu" (FASE B, Entrega 3): só a contagem do
    // organizador com mais rolês, nunca a identidade (ver doc da
    // classe) - por isso não precisa de nenhum critério de desempate:
    // o valor exibido é o número máximo em si, não uma pessoa
    // escolhida entre empatados. `realized` já garantido não-vazio
    // pelo guard no topo desta função, então `organizerCounts` sempre
    // tem pelo menos 1 entrada - `reduce` nunca lança aqui.
    final organizerCounts = <String, int>{};
    for (final event in realized) {
      organizerCounts.update(
        event.organizerId,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    final topOrganizerCount = organizerCounts.values.reduce(
      (a, b) => a > b ? a : b,
    );

    return [
      Row(
        children: [
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mais visitado',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    nameByRestaurant[mostVisitedId] ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    mostVisitedCount == 1
                        ? '1 rolê'
                        : '$mostVisitedCount rolês',
                  ),
                ],
              ),
            ),
          ),
          if (championName != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campeão',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      championName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${championAverage!.toStringAsFixed(1)} ⭐'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quem mais escolheu',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    topOrganizerCount == 1
                        ? '1 rolê'
                        : '$topOrganizerCount rolês',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text('pela mesma pessoa'),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
  }
}
