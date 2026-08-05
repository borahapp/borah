# BORAH — Product Baseline v2.0

**Natureza deste documento:** marco executivo de governança. Não é auditoria, não é PRD, não é plano de implementação — é o registro formal que encerra a fase de planejamento da RC-03 e abre oficialmente a **BORAH 2.0 — Development Phase**.
**Data de congelamento:** 2026-08-04
**Autoridade:** este documento consolida decisões já aprovadas explicitamente pelo usuário ao longo da RC-03. Nenhuma decisão nova é tomada aqui — é registro, não análise.

---

## 1. Status Geral do Projeto

### MVP
Construído a partir da especificação técnica original (Fase 2 — ET-01 a ET-13) e dos fluxos de UX/UI (Fase 3), implementado em 12 módulos de desenvolvimento (Fase 5 — DV-01 a DV-12), e fechado através de 16 rodadas de QA (QA-01 a QA-16) mais uma auditoria arquitetural (QA-15B) e uma correção de fluxo (UX-01). Resultado registrado em `BORAH_RELEASE_CANDIDATE_REPORT.md` (2026-08-01): MVP funcionalmente completo, `flutter analyze` 0 issues, `flutter test` 579/579, `dart format` 0 arquivos, 42 migrations Postgres, ~93% do projeto concluído, 13 débitos técnicos remanescentes (nenhum bloqueante) e 6 gaps de produto registrados como decisão de escopo consciente.

### RC-01
Avaliação de prontidão de release (`RC01_RELEASE_READINESS.md`, 2026-08-02): código 100% pronto (analyze/test/format limpos), mas **nenhum artefato de build gerado** (sem SDK Android/macOS no ambiente de execução) e pendências puramente operacionais — 12 secrets de produção, keystore Android real, contas Google Play/Apple Developer, `pod install` em Mac real, Política de Privacidade em URL real. Conclusão: não pronto para Beta por motivo operacional, não de código.

### RC-02
Composta por múltiplas sub-rodadas: avaliação de prontidão para Beta (`RC02_BETA_READY.md`/RC-02E — mesma conclusão de RC-01, pendência operacional); correção da ficha de loja (`RC02_STORE_REPORT.md`/RC-02C — achado de que a cópia publicada descrevia o produto **anterior ao pivô**, reescrita para refletir Grupos/Rolês/Avaliação Coletiva/Ranking do Grupo); um Smoke Test funcional completo (1 bug de refresh de lista corrigido); e a **Integração do Bundle da Nuvem** (RC-02D) — mesclagem de 48 commits que nunca haviam chegado ao GitHub, adicionando os módulos completos de Groups, Events/Rolês, EventReviews e GroupRanking, mais Google Sign-In. 1 conflito de merge resolvido, 4 bugs corrigidos (3 de refresh de lista, 1 de ambiguidade de coluna em RLS de storage). Resultado mesclado em `develop` (`84d0f0a`, local, ainda não enviado a `origin`). **Decisão do usuário ao final da RC-02**: aprovação do merge, congelamento da arquitetura principal (Auth, Grupos, Rolês, Avaliações, Ranking, Memórias, Notificações, Perfil), e abertura da RC-03 restrita a evolução de produto/UX/UI — sem reabrir discussão arquitetural sobre o que já estava implementado.

### RC-03
Fase de planejamento formal, executada integralmente nesta sessão (2026-08-04), produzindo 7 documentos: `RC03_PRODUCT_AUDIT.md`, `RC03_UX_AUDIT.md`, `RC03_UI_AUDIT.md`, `RC03_DESIGN_GAP.md`, `RC03_FEATURE_GAP.md`, `RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md`, `RC03_IMPLEMENTATION_PLAN.md` — todos revisados e aprovados explicitamente pelo usuário, documento por documento, sem exceção. **A RC-03 está oficialmente encerrada como fase de planejamento.** Este documento (`BORAH_PRODUCT_BASELINE_v2.0.md`) é o marco que formaliza esse encerramento e abre a fase seguinte.

---

## 2. Arquitetura

**Registro oficial: a arquitetura do BORAH está congelada.**

- Flutter + Riverpod (padrão `Notifier`/`NotifierProvider`) + GoRouter.
- Feature-First + Clean Architecture (camadas domain/data/application/presentation por módulo).
- Supabase (Postgres + RLS + Auth + Storage) como backend único e definitivo — a arquitetura NestJS/Prisma descrita na especificação técnica original (ET-01/02/03) está formalmente obsoleta e não deve ser reconsiderada.
- Design System único em `design_system/` (Brand Tokens → Material Tokens → ThemeData → Components → Telas de feature).

**Nenhuma mudança estrutural será realizada durante a execução do BORAH 2.0, salvo aprovação explícita do usuário.** Isso inclui: não introduzir uma nova camada de arquitetura, não trocar o gerenciador de estado, não trocar o backend, não criar uma segunda fonte de tokens de design. Toda funcionalidade do escopo oficial (§4) deve caber dentro dessas restrições — se algum item do plano de implementação, durante a execução real, parecer exigir uma mudança estrutural, isso é motivo de pausa e novo Change Request (§8), não de decisão unilateral durante a sprint.

---

## 3. Documentos Oficiais

| Documento | Finalidade |
|---|---|
| `RC03_PRODUCT_AUDIT.md` | Confirma o pivô de produto (feed social individual → grupos fechados/rolês/avaliação coletiva/ranking de grupo) e audita as 15 áreas de produto uma a uma contra a implementação real. |
| `RC03_UX_AUDIT.md` | Audita experiência real (não telas isoladas) — fluxos, cliques, atrito, automação, eliminação, reutilização, engajamento, roadmap de evolução. |
| `RC03_UI_AUDIT.md` | Audita identidade visual e Design System — classificação ✓/△/✗ das 44 telas, dívida visual, componentes subutilizados/duplicados/removidos. |
| `RC03_DESIGN_GAP.md` | Define a visão final de design — comparação tela a tela do estado atual contra o estado desejado, Design System final oficial, nível de redesenho necessário por tela. |
| `RC03_FEATURE_GAP.md` | Define oficialmente o escopo de funcionalidades do BORAH 2.0 — matriz completa, classificação, análise das funcionalidades candidatas, anti-duplicação, impacto em banco/Flutter/produto. |
| `RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md` | PRD oficial — consolida as 5 auditorias acima em uma especificação única de produto (visão, pilares, jornada, funcionalidades, princípios, arquitetura de negócio, regras). |
| `RC03_IMPLEMENTATION_PLAN.md` | Plano de execução — 10 sprints (Sprint 0 a Sprint 9), dependências, detalhamento técnico por sprint, riscos, testes, checkpoints, critérios de conclusão. |

Estes 7 documentos, junto com este marco de governança, **são a única fonte oficial de verdade do produto BORAH 2.0** a partir desta data. Documentação anterior (ET-01 a ET-13, UX-01/UX-02 originais, DV-01 a DV-12) permanece no repositório como registro histórico, mas **não deve ser usada como referência de comportamento esperado** onde divergir dos 7 documentos acima — a divergência entre elas e o produto real é precisamente o achado central da `RC03_PRODUCT_AUDIT.md §1`.

---

## 4. Escopo Oficial do BORAH 2.0

Herdado sem alteração de `RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md §4` (única fonte de verdade sobre escopo).

**Core** — obrigatório para o BORAH 2.0 ser considerado completo:
1. XP automático para Grupos/Rolês/Avaliação Coletiva
2. Notificação de avaliação liberada
3. "Meu Grupo" (Ranking + Estatísticas + Memórias unificados)
4. Componentes `GroupCard`/`EventCard`
5. Deep link de convite de grupo
6. Verificação e correção do ponto de entrada do Feed

**Muito Importantes:**
7. Botão de Login com Google
8. Perfil redesenhado (atalhos com prévia de dado)
9. Preferências de notificação completas (categoria Grupos)
10. Badges automáticos de atividade de grupo
11. Descoberta de restaurantes guiada pelo grupo
12. Cadastro inteligente de restaurantes via Google Places

**Importantes:**
13. Galeria de fotos unificada (restaurante + rolê)
14. Avaliação por categorias em avaliações individuais de restaurante
15. Feed automático de atividade de grupo
16. Sistema de rodízio/sugestão de escolha
17. Memórias expandidas

**Opcionais:**
18. @username único
19. Desempate de ranking (4 níveis)

**Futuras** (fora do escopo formal do BORAH 2.0):
20. Privacidade de perfil
21. Desafios diário/semanal/sazonal
22. Temporadas de grupo
23. Push notifications (FCM)

**Descartadas** (não implementar, decisão já justificada):
- Check-in físico geolocalizado (substituído por confirmação prévia + passagem de tempo, funciona bem, não deve ser reconstruído)
- Nomenclatura "Wrapped" (renomeada oficialmente para "Memórias")
- Backend NestJS/Prisma (arquitetura obsoleta)
- Bottom nav antiga sem aba Grupos (já substituída)

---

## 5. Princípios Oficiais

Registrados como restrições de governança do BORAH 2.0, não como aspiração:

- **Reutilização máxima** — antes de qualquer código novo, verificar se um controller/provider/repository/trigger/RPC já existente resolve a necessidade.
- **Nenhuma duplicação** — nenhuma funcionalidade nova deve recriar um motor, componente ou fonte de dado que já existe (referência viva: os 6 componentes de design system corretamente removidos por zero uso, `4d856b7`).
- **Uma única ação deve alimentar múltiplos módulos** — todo trigger/automação novo deve seguir o padrão já validado em produção (`award_gamification_points()`, `create_notification()`), nunca um mecanismo paralelo.
- **Design System único** — toda tela nova ou alterada consome exclusivamente os tokens e componentes de `design_system/`.
- **Arquitetura congelada** — conforme §2, sem exceção não aprovada explicitamente.
- **Automação sempre que possível, nunca obrigatoriedade** — toda automação/gamificação deve ser incentivo opcional, nunca bloqueio ou mecânica de pressão sobre o usuário.
- **Integração antes de criação de novas funcionalidades** — antes de aprovar qualquer funcionalidade nova, verificar explicitamente se ela nasce de conectar peças já existentes (o mesmo exercício já aplicado em `RC03_FEATURE_GAP.md §6`).
- **Consistência visual obrigatória** — nenhuma tela nova deve introduzir um padrão visual (card, estado vazio/erro, espaçamento) diferente do já estabelecido; toda tela deve manter ou melhorar sua classificação frente à auditoria de UI original.

---

## 6. Mudanças Futuras — processo obrigatório

Nenhuma funcionalidade poderá entrar diretamente no código a partir de hoje. Toda funcionalidade nova, incluindo qualquer uma classificada Opcional/Futura no §4 que venha a ser reconsiderada, deve seguir obrigatoriamente o fluxo:

```
Ideia
  ↓
Análise (contra os 7 documentos oficiais — existe? é duplicação? é reutilizável?)
  ↓
Documento (Change Request formal, respondendo ao §8 abaixo)
  ↓
Aprovação (explícita do usuário, documento por documento — mesmo padrão já usado em toda a RC-03)
  ↓
Sprint (planejada e sequenciada conforme dependências reais, mesmo padrão do RC03_IMPLEMENTATION_PLAN.md)
  ↓
Implementação
  ↓
QA (flutter analyze + flutter test + Smoke Test + revisão visual)
  ↓
Merge
```

Nenhuma etapa pode ser pulada. Em particular, nenhuma "Implementação" pode começar sem uma "Aprovação" prévia e explícita — o mesmo padrão de aprovação documento-por-documento que regeu toda a RC-03 continua valendo para qualquer mudança futura, não só para o escopo já aprovado.

---

## 7. Critérios de Qualidade

Toda Sprint (as já planejadas em `RC03_IMPLEMENTATION_PLAN.md` e qualquer futura, via o processo do §6) deve terminar obrigatoriamente com:

- ✓ `flutter analyze` limpo (0 issues)
- ✓ `flutter test` — 100% da suíte passando (existente + nova, nenhuma regressão)
- ✓ Smoke Test — mesma metodologia já estabelecida nas rodadas RC-02C/RC-02D (dispositivo real, conta QA permanente, roteiro de fluxo completo)
- ✓ Revisão visual — validação manual contra a classificação-alvo definida em `RC03_DESIGN_GAP.md`
- ✓ Documentação atualizada — o plano de implementação e, quando aplicável, os documentos oficiais (§3) refletem o estado real
- ✓ Commit — a entrega está registrada em um commit (ou série de commits) que referencia claramente a sprint/funcionalidade correspondente

**Nenhuma sprint pode avançar para a próxima sem cumprir todos os 6 critérios.** Isso é uma extensão formal do checklist de checkpoint já definido em `RC03_IMPLEMENTATION_PLAN.md §8`, com a adição explícita do critério de commit como fechamento obrigatório de cada sprint.

---

## 8. Critérios para Change Request

Qualquer mudança futura — nova funcionalidade, alteração de escopo, reconsideração de item Opcional/Futuro/Descartado — deve responder formalmente, por escrito, antes de qualquer análise técnica começar:

1. **Por quê?** — motivação da mudança.
2. **Qual problema resolve?** — problema real, de preferência já observado (dado, feedback, achado de auditoria), não hipotético.
3. **Qual valor entrega?** — para o usuário e para o produto, nos mesmos termos já usados em `RC03_FEATURE_GAP.md §9` (retenção, engajamento, tempo de uso, criação de grupos/rolês, avaliações, descoberta de restaurantes).
4. **Qual impacto no banco?** — migration, trigger, RLS, Edge Function, Storage, ou "nenhum".
5. **Qual impacto na UX?** — fluxo novo ou alterado, cliques, atrito, conforme o padrão de análise de `RC03_UX_AUDIT.md`.
6. **Qual impacto na UI?** — telas novas/alteradas, componentes novos/reutilizados, conforme o padrão de `RC03_UI_AUDIT.md`/`RC03_DESIGN_GAP.md`.
7. **Qual impacto na arquitetura?** — por padrão, a resposta esperada é "nenhum" (arquitetura congelada, §2); qualquer resposta diferente exige aprovação explícita adicional, específica sobre a mudança estrutural, antes de qualquer outra etapa do processo do §6.
8. **Quais documentos precisam ser atualizados?** — no mínimo `RC03_FEATURE_GAP.md` (escopo) e `RC03_IMPLEMENTATION_PLAN.md` (sequenciamento); potencialmente `RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md` se a mudança afetar a jornada ou os pilares do produto.

---

## 9. Início Oficial da Fase de Desenvolvimento

**A RC-03 encerra oficialmente a fase de planejamento do BORAH 2.0.**

A partir da aprovação deste documento pelo usuário, inicia-se formalmente a **BORAH 2.0 — Development Phase**, regida por:
- O escopo oficial do §4 (nada além dele sem passar pelo processo do §6).
- Os princípios do §5.
- Os critérios de qualidade do §7, aplicados a cada sprint sem exceção.
- O processo de Change Request do §8 para qualquer mudança não coberta pelo escopo já aprovado.

Nenhuma sprint é iniciada pela aprovação deste documento isoladamente — cada sprint do `RC03_IMPLEMENTATION_PLAN.md` continua exigindo autorização explícita e específica antes de sua execução real, conforme já reafirmado ao final daquele plano.

---

## 10. Próximos Passos — ordem de execução

Herdada sem alteração de `RC03_IMPLEMENTATION_PLAN.md §10` (Roteiro Executivo):

| Ordem | Sprint | Objetivo |
|---|---|---|
| 1 | Sprint 0 (trilha paralela) | Fechar o motor social de Grupos/Rolês (XP automático, notificação de avaliação liberada, badges de grupo, preferências completas) + verificar o ponto de entrada do Feed |
| 2 | Sprint 1 | Design System — `GroupCard`, `EventCard`, componente de Tabs, tokens novos, unificação de avatar, correção de `review_summary_tile.dart` |
| 3 | Sprint 2 | Splash, Login, Cadastro — botão de Login com Google |
| 4 | Sprint 3 | Home, Feed, Bottom Navigation — `GroupCard` aplicado, entrada do Feed corrigida |
| 5 | Sprint 4 | Restaurantes, Google Places, Cards |
| 6 | Sprint 5 | Grupos, Rolês, `EventCard`, deep link de convite, rodízio/sorteio |
| 7 | Sprint 6 | Perfil, Favoritos, Fotos — perfil redesenhado, fusão de troca de avatar, galeria unificada |
| 8 | Sprint 7 | Avaliações, Categorias, Feed Automático |
| 9 | Sprint 8 | Ranking, Gamificação, Memórias — "Meu Grupo" |
| 10 | Sprint 9 | Polimento, Animações, Performance — cluster Administração, `settings_page`, `public_profile_page` |

Sprint 0, Sprint 1 e Sprint 2 podem começar em paralelo, conforme o grafo de dependências já registrado em `RC03_IMPLEMENTATION_PLAN.md §2`.

---

**Fim do documento. Nenhum código, migration ou commit foi criado nesta sessão além dos 8 documentos de planejamento da RC-03 (os 7 já aprovados + este marco). Aguardando aprovação deste documento antes de autorizar o início da Sprint 0.**
