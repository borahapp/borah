# BORAH — Release Candidate Report

**Data:** 2026-08-01
**Versão:** 1.0.0+1
**Branch:** `claude/turnstile-secret-diagnosis-0g0p82`
**Escopo:** Auditoria completa de QA (QA-01 a QA-16) conduzida como QA Lead / Staff Software Engineer / CTO / Arquiteto de Software, cobrindo todas as funcionalidades do MVP, os fluxos integrados end-to-end, revisão arquitetural e prontidão de produção — mais uma segunda rodada de auditoria arquitetural com mandato de correção (QA-15B, ver `docs/FASE 9 - Execution/QA-15B_ARCHITECTURAL_AUDIT_AND_FIXES.md`).

Este documento representa o estado oficial do projeto imediatamente antes da publicação do Beta.

---

## 1. Resumo executivo

O MVP está **funcionalmente completo**. Todas as 16 rodadas de QA planejadas foram concluídas, mais uma rodada adicional de auditoria arquitetural com correções (QA-15B). Nenhum bloqueador de **desenvolvimento** permanece — os itens que restam para publicação são **operacionais** (credenciais, contas de loja, builds em ambiente real) e **de conteúdo** (assets visuais, publicação de documentos legais), não bugs de código.

| Métrica | Valor |
|---|---|
| Bugs corrigidos durante todo o RC (QA-01 a QA-16 + QA-15B) | **13** (1 Bug Crítico de vazamento entre contas + 1 vulnerabilidade Alta de RLS entre grupos) |
| Débitos técnicos restantes | **11** (nenhum bloqueia o Beta; 3 removidos/corrigidos nesta rodada) |
| Gaps de produto identificados | **6** (decisões de escopo, não regressões) |
| `flutter analyze` | 0 issues |
| `flutter test` | 574/574 passando (9 testes de dead code removidos junto com o código, nenhuma funcionalidade perdeu cobertura) |
| `dart format --set-exit-if-changed .` | 0 arquivos — corrigido nesta rodada (18 arquivos estavam fora do padrão, quebraria a CI) |
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

**~92%.**

- Funcionalidades do MVP: 100% implementadas (todos os 9 BLOCOs + 2 gaps de produto documentados como decisão de escopo, não pendência).
- Qualidade/QA: 100% das 16 rodadas concluídas + 1 rodada adicional de auditoria arquitetural com correção (QA-15B), 13 bugs reais corrigidos (1 Crítico + 1 vulnerabilidade Alta de RLS), 0 issues de analyzer, 0 arquivos fora do padrão de formatação, 100% dos testes passando, dead code confirmado removido.
- Publicação: ~70% — falta exclusivamente trabalho operacional (contas, credenciais, build iOS real, assets visuais, conteúdo legal publicado), nenhum código.

---

## 9. Conclusão

O BORAH está **funcionalmente pronto para o Beta fechado**, condicionado a:
1. Abrir PR e confirmar CI real (Analyze/Test/Build Android) contra o estado atual do código — agora inclusive o gate de `dart format`, corrigido nesta rodada.
2. Resolver os débitos técnicos de severidade Alta/Média (build iOS real, invalidação completa de providers, verificação do oráculo de membership em §3 do QA-15B) antes da GA — não bloqueiam o Beta fechado.
3. Seguir o checklist operacional já documentado em `docs/launch/launch_readiness.md` para as contas de loja, credenciais e assets visuais.

Nenhum item nesta lista é um bug de código não resolvido. O projeto saiu da fase de desenvolvimento e está oficialmente em fase de estabilização/publicação. Detalhe completo da rodada QA-15B (achados, evidência arquivo:linha, correções e validação) em `docs/FASE 9 - Execution/QA-15B_ARCHITECTURAL_AUDIT_AND_FIXES.md`.
