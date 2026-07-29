# Rollback Plan — BORAH

**Contexto:** BETA-11A1. Documento que esperamos nunca precisar usar — mas que precisa existir antes do Beta Fechado começar, não depois de um problema já ter acontecido.

---

## 1. Quando interromper o Closed Beta

Critérios objetivos para pausar ou encerrar o Beta imediatamente:

- **Falha de segurança**: qualquer indício de acesso não autorizado a dados de outro usuário (falha de RLS, vazamento de sessão) — interromper imediatamente, sem aguardar confirmação completa do escopo do problema.
- **Perda ou corrupção de dados**: qualquer relato de dados de usuário (avaliações, perfil) desaparecendo ou sendo sobrescritos incorretamente.
- **Taxa de crash anormal**: pico no Sentry indicando que uma parcela relevante das sessões está travando (referência: qualquer taxa que impeça o fluxo básico de cadastro→avaliação de ser concluído por testadores).
- **Falha jurídica/de conformidade**: descoberta de que a Política de Privacidade publicada diverge do que o app realmente faz (ex.: um dado sendo coletado sem estar declarado).
- **Feedback consistente de bug bloqueante**: múltiplos testadores relatando o mesmo problema que impede o uso básico do app (login, avaliação, exclusão de conta).

## 2. Como remover uma versão das lojas

### Google Play
- Internal Testing/Closed Testing: no Play Console, a faixa pode ser despausada/removida a qualquer momento (Release → faixa correspondente → "Halt rollout" ou remoção da faixa) — os testadores deixam de receber a build imediatamente, mas builds já instaladas continuam funcionando até serem atualizadas ou o usuário desinstalar.
- Não existe "desinstalação forçada" — a comunicação aos testadores (seção 6) é o mecanismo real de resposta.

### Apple TestFlight
- No App Store Connect, a build pode ser removida do grupo de teste (Build → remover do grupo) — novos convites param, mas quem já instalou continua com a versão até expirar (builds do TestFlight expiram automaticamente em 90 dias) ou ser removida manualmente pelo usuário.

## 3. Como desativar cadastros temporariamente

**Não há um "modo manutenção" implementado no app hoje.** A forma mais direta e imediata, sem exigir deploy de código novo:
- Revogar/pausar a chave `anon` do Supabase de Produção no Dashboard (Settings → API) — isso interrompe **todo** o tráfego do app, não só cadastros; é uma medida extrema, reservada para incidentes de segurança graves (item 1).
- Para uma resposta mais cirúrgica (só bloquear novos cadastros, preservando o uso de quem já tem conta): não existe hoje um mecanismo de feature flag para isso especificamente — **fica registrado como uma lacuna real**, já que `AppFeatureFlags`/`feature_flags` (Supabase) poderia, em uma rodada futura, ganhar uma flag dedicada para isso, mas não existe ainda.

## 4. Como desligar Feature Flags críticas

O BORAH já tem sua própria infraestrutura de feature flags (`AppFeatureFlags`, RC-03D, backed pela tabela `feature_flags` do Supabase). Para desligar qualquer flag existente:
1. Acessar a tabela `feature_flags` no Supabase Dashboard de Produção (SQL Editor ou Table Editor).
2. Atualizar o valor da flag correspondente para desabilitado.
3. O app já lê o cache de flags no próximo carregamento (`AppFeatureFlags.initialize()`, chamado no boot) — não exige nova build nem redeploy.

**Nota**: nenhuma flag crítica de negócio está cadastrada hoje (uso do sistema de flags ainda limitado) — este procedimento serve para quando alguma vier a existir.

## 5. Contatos responsáveis

| Papel | Responsável | Contato |
|---|---|---|
| Responsável pelo aplicativo / decisão final de interrupção | Victor Henrique Frare Seraphim | Borahh.app@gmail.com |
| Acesso ao Supabase Dashboard (Produção) | Proprietário | — |
| Acesso ao Google Play Console / App Store Connect | Proprietário | — |
| Acesso ao Sentry/PostHog (Produção) | Proprietário | — |

*(Time de um só responsável nesta fase — não há uma equipe distribuída ainda; qualquer decisão de rollback é do próprio proprietário.)*

## 6. Procedimento de comunicação aos testadores

1. **Canal**: e-mail direto aos endereços cadastrados como testadores (lista definida na Fase 1 do `launch_plan.md`) — não existe um canal de push notification no app (confirmado, RC-03A/BETA-09A: nenhuma infraestrutura de push implementada).
2. **Conteúdo mínimo da comunicação**:
   - O que aconteceu (em termos simples, sem jargão técnico).
   - O que o testador precisa fazer (nada, parar de usar temporariamente, ou uma ação específica).
   - Prazo estimado para retomada, se souber.
   - Agradecimento pela participação e reforço de que o feedback continua sendo bem-vindo.
3. **Prazo**: comunicar em até 24h da decisão de interrupção — mesmo que a causa raiz ainda não esteja resolvida, a transparência sobre "sabemos do problema e estamos tratando" é mais importante do que esperar a solução completa.

---

## Pendências identificadas por este documento

- Não existe hoje um mecanismo de "modo manutenção"/pausa cirúrgica de cadastros — só a opção extrema de revogar a chave `anon` inteira.
- Nenhuma feature flag crítica de negócio está cadastrada ainda — o mecanismo existe, mas não há nenhuma flag "de emergência" pré-configurada e testada.
- Este plano nunca foi exercitado em um simulacro (tabletop exercise) — recomendável fazer isso antes do início real do Beta Fechado.
