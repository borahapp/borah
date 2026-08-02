# BORAH — Release Candidate Report

**Data:** 2026-08-01
**Versão:** 1.0.0+1
**Branch:** `claude/turnstile-secret-diagnosis-0g0p82`
**Commit de fechamento da QA-15 Final:** `c346b67` (2026-08-01) — desenvolvimento do MVP formalmente encerrado a partir deste commit.
**Escopo:** Auditoria completa de QA (QA-01 a QA-16) conduzida como QA Lead / Staff Software Engineer / CTO / Arquiteto de Software, cobrindo todas as funcionalidades do MVP, os fluxos integrados end-to-end, revisão arquitetural e prontidão de produção — mais duas rodadas adicionais: QA-15B (auditoria arquitetural com mandato de correção, ver `docs/FASE 9 - Execution/QA-15B_ARCHITECTURAL_AUDIT_AND_FIXES.md`) e UX-01 (remoção de 2 becos sem saída identificados na auditoria de produto, ver `BORAH_BETA_PLAYBOOK.md`), encerradas por uma auditoria de fechamento (QA-15 Final, §9).

Este documento representa o estado oficial do projeto imediatamente antes da publicação do Beta.

---

## 1. Resumo executivo

O MVP está **funcionalmente completo**. Todas as 16 rodadas de QA planejadas foram concluídas, mais duas rodadas adicionais — auditoria arquitetural com correções (QA-15B) e remoção de becos sem saída de produto (UX-01) — encerradas por uma auditoria de fechamento (QA-15 Final). Nenhum bloqueador de **desenvolvimento** permanece — os itens que restam para publicação são **operacionais** (credenciais, contas de loja, builds em ambiente real) e **de conteúdo** (assets visuais, publicação de documentos legais), não bugs de código.

| Métrica | Valor |
|---|---|
| Bugs corrigidos durante todo o RC (QA-01 a QA-16 + QA-15B) | **13** (1 Bug Crítico de vazamento entre contas + 1 vulnerabilidade Alta de RLS entre grupos) |
| Becos sem saída de produto eliminados (UX-01) | **2** (Criar Grupo→Convite; Criar Rolê→Restaurante ausente) |
| Débitos técnicos restantes | **13** (nenhum bloqueia o Beta; 3 removidos na QA-15B, 1 novo de severidade Baixa achado na QA-15 Final) |
| Gaps de produto identificados | **6** (decisões de escopo, não regressões) |
| `flutter analyze` | 0 issues |
| `flutter test` | 579/579 passando (9 testes de dead code removidos na QA-15B, 5 novos adicionados no UX-01 — cobertura real cresceu) |
| `dart format --set-exit-if-changed .` | 0 arquivos |
| Migrations Postgres | 42 (41 já existentes + 1 nova de segurança, QA-15B §2.1) |

---

## 2. Bugs corrigidos durante o RC

### QA-01 a QA-10 (já resolvidos, não reavaliados nesta rodada)
1. Navegação sem volta na Etapa 2 de "Criar rolê" (`PopScope`).
2. RLS não bloqueava confirmar/recusar presença em rolê já cancelado.
3. Vírgula como separador decimal rejeitada em campos de nota (`parseRating()`).
4. `level_up`/`badge_earned` sem destino de navegação na tela de notificação.
5. Fallback de mock ausente quebrando testes (`event_restaurant_search_controller_test.dart`).
6. `pubspec.lock` fora de sincronia (`google_sign_in` nunca resolvido de verdade).
7. 2 warnings reais do `flutter analyze` (BLOCO 9).

### QA-11 a QA-16 (esta rodada)
8. **Bug:** `RestaurantDetailError` apagava a tela inteira do restaurante quando só o upload da foto de capa falhava.
9. **Bug:** lista de Favoritos não recarregava ao voltar do Detalhe do restaurante — item desfavoritado continuava aparecendo até refresh manual.
10. **Bug:** "Campeão" em Memórias calculava a nota do rolê individual mais bem avaliado, não a média por restaurante (mesma classe de bug já corrigida em Estatísticas, não propagada).
11. **Bug Crítico:** providers de dados por usuário (Grupos, Favoritos, Perfil, Notificações, Preferências, Gamificação, Feed) não eram `autoDispose` — trocar de conta no mesmo processo do app deixava dados do usuário anterior visíveis por um instante, risco real de vazamento entre contas em dispositivo compartilhado.

Todos os 11 bugs foram corrigidos com commits individuais, validados com `flutter analyze`/`flutter test` reais (Flutter 3.44.6 instalado nesta sessão) e, quando aplicável, com testes de regressão novos e/ou validação funcional real contra Postgres 16.

### QA-15B (rodada de auditoria arquitetural com correção)

12. **Vulnerabilidade Alta (RLS):** a policy de UPDATE de `event_attendances` só verificava `auth.uid() = user_id`, nunca que `event_id` permanecia o mesmo — um usuário podia redirecionar a própria linha de presença para o evento de outro grupo, fabricar uma presença "confirmed" e inserir uma avaliação coletiva num grupo do qual nunca foi membro. Corrigido via trigger (`20260801150000_lock_event_attendance_identity_columns.sql`), validado contra Postgres 16 real nesta sessão. Detalhe completo em QA-15B §2.1.
13. **Bug:** falha ao encerrar a sessão local após excluir a conta era engolida em silêncio (`catch (_) {}` sem log), inconsistente com o bloco de limpeza do Storage 30 linhas acima no mesmo arquivo. Corrigido (mesmo padrão de log). Detalhe em QA-15B §2.2.

Além dos bugs, esta rodada corrigiu 18 arquivos fora do padrão do `dart format` (quebraria a CI hoje) e removeu 9 arquivos de dead code confirmado (6 widgets + 1 token do design system + 2 cadeias de providers Riverpod nunca conectadas a nenhuma tela) — ver QA-15B §2.3-2.6 para evidência completa.

### UX-01 (melhoria de fluxo, não bug de código)

Uma auditoria de produto (`BORAH_BETA_PLAYBOOK.md`) identificou dois becos sem saída reais no funil do MVP — nenhum dos dois era um bug (o código fazia exatamente o que foi especificado), mas os dois geravam abandono real:

14. Criar um grupo devolvia o usuário à lista de grupos, exigindo tocar de novo no próprio grupo para achar o código de convite — exatamente no momento em que a pessoa está mais disposta a convidar alguém.
15. Buscar um restaurante ainda não cadastrado, dentro da criação de um rolê, terminava em "Nenhum restaurante encontrado." sem nenhuma ação — só cancelando a criação inteira do rolê para cadastrar o restaurante em outra aba e recomeçar.

Ambos corrigidos reaproveitando mecanismos já existentes no projeto (`pushReplacement`, `extra`-based page params, `ConfirmationDialog`, `Share.share()`) — nenhum controller, repositório, RPC ou migration foi tocado. Detalhe completo, incluindo a decisão de devolver o `Restaurant` recém-criado diretamente (em vez de repetir a busca) para já vir pré-selecionado, no histórico de commits (`feat(ux): improve onboarding flow and remove dead ends (UX-01)`).

---

## 3. Débitos técnicos restantes

| # | Débito | Severidade |
|---|---|---|
| 1 | `GroupStatsPage` refaz consultas já feitas por telas irmãs segundos antes — confirmado novamente em QA-15B; não corrigido porque os dois controllers envolvidos são compartilhados com outras telas e não guardam qual `groupId` está carregado, risco de exibir dados do grupo errado se "corrigido" sem essa guarda | Baixa |
| 2 | Invalidação de providers no logout cobre só as telas de entrada imediata (Home + Perfil) — providers "de detalhe" (grupo/rolê específico) não incluídos. Reconfirmado em QA-15B: nenhum OUTRO provider global escapa dessa regra além dos 7 já conhecidos | Média |
| 3 | Nenhum teste automatizado cobre `app_router.dart` | Baixa |
| 4 | `EventsListPage` (incl. seção de Memórias) sem nenhum teste de widget | Baixa |
| 5 | Nenhuma execução de CI real desde o início do RC (nada foi enviado ao GitHub nesta sessão) | Média — ação necessária antes da GA |
| 6 | Build iOS nunca validada em nenhum ambiente real (Mac/Xcode) — pré-existente, não causado por este RC | Alta |
| 7 | Upload do mapping R8/ProGuard ao Sentry não configurado (3 secrets pendentes) | Baixa |
| 8 | RPC `regenerate_group_invite_code` provavelmente órfã (sem UI) — a função em si é segura (verifica `is_group_owner`), só não tem UI | Baixa |
| 9 | `fetchProfilesByIds` duplicado em 5-6 datasources (decisão intencional documentada, não descuido) | Informativo |
| 10 | Nenhum `ref.watch(provider.select(...))` no projeto — ausência estrutural de granularidade fina de rebuild, mitigada pelo padrão de estado existente | Baixa |
| 11 | "Avaliação liberada" (notificação por passagem de tempo) e "Fotos"/"Resumo anual" em Memórias não implementados — infraestrutura de scheduler/Storage pendente | Baixa |
| 12 | **[Novo, QA-15B]** Funções `SECURITY DEFINER` de leitura (`is_group_member`, `is_event_group_member`, `can_review_event` etc.) sem `REVOKE`/`GRANT` explícito — se alcançáveis via RPC direto por `authenticated`, permitem sondar membership de grupos fechados sem ser membro (oráculo de 1 bit). Requer verificação contra o projeto Supabase real antes de qualquer correção de schema (correção às cegas arrisca quebrar toda RLS de Grupos/Rolês) — ver QA-15B §3.1 | Média — requer verificação operacional antes do Beta |
| 13 | **[Novo, QA-15 Final]** `CreateRestaurantPage` não chega pré-preenchida com o nome já buscado em `CreateEventPage` quando o usuário toca em "Cadastrar restaurante" — precisa digitar o nome de novo. Papercut, não um beco sem saída (o UX-01 já resolveu o problema real); daria para herdar o texto buscado via `extra`, mesmo mecanismo já usado no resto desta rodada, mas não foi pedido nesta sprint | Baixa |

Débitos anteriores **removidos desta lista** por terem sido corrigidos em QA-15B: dead code do design system (6 widgets + 1 token) e as 2 cadeias de infraestrutura Riverpod mortas (feature flags, storage) — ver QA-15B §2.5-2.6.

## 4. Gaps de produto (decisões de escopo, não bugs)

1. Login com Google sem botão na UI (documentado desde o AUTH-02 como fora de escopo da sprint).
2. Preferências de notificação só cobrem a categoria "social" — sem opção de desativar notificações de Grupos/Rolês na UI (backend já suporta).
3. "Editar restaurante"/"Excluir restaurante" não existem para usuários regulares (só arquivar/reativar via administração).
4. Listagem de restaurantes nunca avança da página 1 (sem paginação/scroll infinito na UI).
5. "Quem mais participou"/"Quem mais escolheu" (Memórias) nunca implementados — só "Mais visitado"/"Campeão" por restaurante.
6. Home inicial: decisão já tomada e implementada nesta rodada (Grupos substituiu Feed como aba principal).

## 5. Riscos para publicação

1. **Build iOS nunca validada em hardware real** — maior incerteza técnica do projeto, pré-existente, não introduzida por este RC.
2. **Nenhuma alteração deste RC passou por CI real** — recomendo abrir PR e confirmar os 3 checks obrigatórios antes de considerar o trabalho oficialmente validado.
3. **Nenhuma conta de loja existe** (Google Play Console / Apple Developer) — bloqueiam todo o processo de submissão.
4. **Política de Privacidade/Termos não publicados em URL real** — exigido pelo formulário de submissão de ambas as lojas (conteúdo já existe em `docs/legal/`).
5. **Nenhum asset visual final produzido** (screenshots, feature graphic) — especificação existe, produção depende de build instalável real.
6. **Keystore Android de release não existe** — build de produção cai para assinatura debug até ser gerada.
7. Vazamento residual entre contas (débito técnico #2) — mitigado para os casos de maior visibilidade, não eliminado por completo.
8. **[Novo, QA-15B]** Possível oráculo de membership via funções `SECURITY DEFINER` sem `GRANT` explícito (débito técnico #12) — verificar contra o Supabase real antes do Beta.

## 6. Prontidão para Google Play

🟡 **Parcial.** Código pronto (build debug/AAB com R8/ProGuard já validados com sucesso em sessão anterior, `docs/launch/launch_readiness.md`). Faltam: conta Google Play Console, keystore de release real, secrets de produção cadastrados, Política de Privacidade publicada em URL real, screenshots/Feature Graphic, execução do CI real contra o estado atual do código.

## 7. Prontidão para App Store

🔴 **Não pronta.** Mesmos itens operacionais do Google Play, mais o bloqueador exclusivo: **build iOS nunca testada em nenhum Mac/Xcode real** — o job de CI (`build_release_ios`) só confirma compilação sem assinatura; não existe conta Apple Developer nem validação em dispositivo/simulador real até hoje.

## 8. Percentual de conclusão do projeto

**~93%.**

- Funcionalidades do MVP: 100% implementadas (todos os 9 BLOCOs + 2 gaps de produto documentados como decisão de escopo, não pendência).
- Qualidade/QA: 100% das 16 rodadas concluídas + auditoria arquitetural com correção (QA-15B) + remoção dos 2 becos sem saída de produto (UX-01) + auditoria de fechamento (QA-15 Final, §9). 15 itens reais corrigidos (13 bugs, 1 Crítico + 1 vulnerabilidade Alta de RLS, + 2 becos sem saída de UX), 0 issues de analyzer, 0 arquivos fora do padrão de formatação, 579/579 testes passando.
- Publicação: ~70% — falta exclusivamente trabalho operacional (contas, credenciais, build iOS real, assets visuais, conteúdo legal publicado), nenhum código.

---

## 9. QA-15 Final — Auditoria de Fechamento

Rodada de fechamento, focada no que mudou desde a QA-15B (principalmente UX-01) mais uma varredura final por gaps residuais — não repete o levantamento completo já feito nas rodadas anteriores.

**Integração do UX-01 com o resto do app (checado, sem regressão):**
- Todos os outros call sites de `/groups/:id` (linha da lista, deep link de notificação) continuam sem passar `extra` — `justCreated` cai no default `false` corretamente, o diálogo de "grupo criado" nunca aparece fora do fluxo de criação.
- `/restaurants/new` idem: o único outro call site (aba Restaurantes, botão "+") continua sem `extra` — `returnToCaller` cai em `false`, comportamento de sempre preservado.
- Nenhum provider novo foi criado pelo UX-01 — a regra de invalidação no sign-out (débito #2) não ganhou nenhuma exceção nova para reavaliar.
- `PopScope` de `CreateEventPage` (Etapa 2 → Etapa 1) não interage com a navegação nova para `/restaurants/new` — são pilhas de navegação independentes.

**Varredura final:** nenhum dead code novo, nenhum TODO/FIXME pendente, nenhum comentário desatualizado além do já corrigido antes do commit do UX-01 (`join_group_page.dart`, `groups_list_page.dart`). Único achado novo: débito técnico #13 (papercut de UX, severidade Baixa, não um beco sem saída).

**Veredito:** nenhum bloqueador de desenvolvimento restante. O MVP está formalmente encerrado nesta fase — as próximas rodadas são operacionais (Sprint 2-3 do plano de Beta: build real, credenciais, publicação) e de produto (Sprint 4: analytics, funil, iteração com uso real), não mais de código.

---

## 10. Conclusão

O BORAH está **funcionalmente pronto para o Beta fechado**, condicionado a:
1. Abrir PR e confirmar CI real (Analyze/Test/Build Android) contra o estado atual do código — agora inclusive o gate de `dart format`, corrigido na QA-15B.
2. Resolver os débitos técnicos de severidade Alta/Média (build iOS real, invalidação completa de providers, verificação do oráculo de membership em §3 do QA-15B) antes da GA — não bloqueiam o Beta fechado.
3. Seguir o checklist operacional já documentado em `docs/launch/launch_readiness.md` para as contas de loja, credenciais e assets visuais.

Nenhum item nesta lista é um bug de código não resolvido. **O desenvolvimento do MVP está formalmente encerrado** (QA-15 Final, §9) — o projeto entra na fase de estabilização operacional e, em seguida, na fase de produto guiada por uso real (funil de ativação e retenção, ver `BORAH_BETA_PLAYBOOK.md` §9). Detalhe completo da rodada QA-15B (achados, evidência arquivo:linha, correções e validação) em `docs/FASE 9 - Execution/QA-15B_ARCHITECTURAL_AUDIT_AND_FIXES.md`.
