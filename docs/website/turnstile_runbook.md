# BORAH — Runbook de Diagnóstico do Turnstile

**Contexto:** BETA-11C. Procedimento operacional para diagnosticar falhas no fluxo `Widget Turnstile → Edge Function website-form-submit → Cloudflare SiteVerify → Supabase`, sem depender de interpretação — cada etapa tem comando, resultado esperado e critério objetivo de passa/falha. Executável por qualquer desenvolvedor da equipe em até 15 minutos.

**Pré-requisitos:**
- Acesso ao site em produção (`https://www.appborah.com.br/`) num navegador desktop (Chrome, Edge ou Firefox).
- CLI do Supabase autenticado (`supabase login`) e vinculado ao projeto (`supabase link --project-ref uscheppbwhuuwkskhfos`) — necessário só na Etapa 3.
- Acesso ao painel Cloudflare Turnstile (`https://dash.cloudflare.com/?to=/:account/turnstile`) — necessário só na Etapa 5.

Referências de código citadas neste runbook: `supabase/functions/website-form-submit/index.ts`, `site/assets/js/main.js`, `site/{index,contato,suporte}/index.html`.

---

## Etapa 1 — Validar o widget Turnstile no navegador

**Onde abrir:** a página real de produção, não localhost — o widget é restrito por domínio no Cloudflare (Etapa 5), então testar em `localhost:4173` não valida a mesma configuração que roda em produção. Abrir uma das 3 páginas com formulário:
- `https://www.appborah.com.br/` (formulário de Beta)
- `https://www.appborah.com.br/contato/`
- `https://www.appborah.com.br/suporte/`

**DevTools:** abrir com `F12` (ou `Cmd+Option+I` no Mac). Usar as abas **Console** e **Network** (nesta, filtrar por `turnstile` ou `cloudflare`).

**Passo a passo:**

1. Recarregar a página com o Network aberto. Confirmar que aparece uma requisição para `challenges.cloudflare.com/turnstile/v0/api.js` com status **200**.
   - ❌ Se não aparecer nenhuma requisição: o `<script>` não carregou (bloqueador de anúncios, CSP, falha de rede). Testar em aba anônima sem extensões antes de prosseguir.
2. No Console, executar:
   ```js
   typeof window.turnstile
   ```
   - ✅ Esperado: `"object"`.
   - ❌ Se `"undefined"`: o script da Cloudflare não terminou de carregar ou falhou — repetir o passo 1.
3. No Console, executar:
   ```js
   document.querySelector('.cf-turnstile').innerHTML.length
   ```
   - ✅ Esperado: número maior que `0` (o widget injetou um `<iframe>` dentro da div).
   - ❌ Se `0`: **falha de renderização** — o widget nunca chegou a desenhar o captcha. Causa mais provável: a site key (`data-sitekey`) não existe no Cloudflare, ou o domínio atual não está na lista de domínios permitidos daquele widget (ir direto para a Etapa 5).
4. Resolver o desafio visualmente (marcar o checkbox do widget, se ele pedir interação).
5. No Console, executar:
   ```js
   window.turnstile.getResponse(document.querySelector('.cf-turnstile'))
   ```
   - ✅ Esperado: uma string longa (tipicamente muitas centenas de caracteres), começando por um prefixo do tipo `0.`. Guardar essa string — ela será comparada na Etapa 2.
   - ❌ **Token vazio**: se o retorno for `""` mesmo depois de resolver o desafio, marcar como falha e ir para a Etapa 5 (verificar hostnames/site key no painel). Um token vazio após interação bem-sucedida é o sintoma mais comum de hostname mismatch ou site key/secret key de widgets diferentes.
   - ❌ Se a chamada lançar um erro (`TypeError`, `undefined is not a function`): o elemento `.cf-turnstile` não existe na página, ou o widget não terminou de inicializar — repetir a partir do passo 2.

**Critério de saída da Etapa 1:** token não vazio, com formato de string longa — **avançar para a Etapa 2**. Qualquer resultado ❌ acima interrompe o diagnóstico aqui e aponta direto para a Etapa 5 (causa é client-side/config do Cloudflare, não vale a pena investigar a Edge Function ainda).

---

## Etapa 2 — Validar a requisição enviada para a Edge Function

Com o DevTools ainda aberto (aba **Network**, filtro `website-form-submit`), submeter o formulário de fato (com um e-mail de teste).

**O que conferir, clicando na requisição capturada:**

| Item | Valor esperado |
|---|---|
| URL | `https://uscheppbwhuuwkskhfos.supabase.co/functions/v1/website-form-submit` |
| Método | `POST` |
| Header `Content-Type` (aba Headers → Request Headers) | `application/json` |
| Header `Origin` (setado automaticamente pelo navegador) | `https://www.appborah.com.br` |
| Payload JSON (aba Payload/Request) | `{"type":"waitlist"` ou `"contact"`, `"turnstileToken":"..."`, `"honeypot":"", "startedAt":<timestamp>, ...campos do formulário}` |
| Campo `turnstileToken` dentro do payload | string **não vazia**, com o mesmo formato/tamanho aproximado do token capturado na Etapa 1 |
| Status da resposta (aba Response/Headers) | `200`, `400`, `409` ou `500` (ver tabela abaixo) |
| Corpo da resposta | `{"success": true|false, "message": "..."}` |

**Interpretação do status HTTP de resposta** (contrato real, `index.ts`):

| Status | `success` | Significado |
|---|---|---|
| 200 | `true` | Gravou com sucesso — Turnstile passou, sem problema. |
| 200 | `false` | Bloqueado por honeypot ou tempo mínimo de preenchimento — **não é falha de Turnstile**, é anti-spam. |
| 400 | `false`, mensagem "Verificação de segurança ausente..." | `turnstileToken` chegou vazio/nulo no payload — problema é client-side (Etapa 1/frontend), token nunca foi gerado. |
| 400 | `false`, mensagem "Não foi possível confirmar que você não é um robô..." | Token chegou preenchido, mas o `siteverify` da Cloudflare **rejeitou** — ir para a Etapa 3/4. |
| 400 | `false`, outra mensagem (e-mail/nome/mensagem inválidos) | Validação de negócio, não relacionado a Turnstile. |
| 409 | `false` | E-mail duplicado (`beta_waitlist`) — não relacionado a Turnstile. |
| 500 | `false` | Erro do Supabase ao inserir — Turnstile já passou antes disso. |

**Critério de saída da Etapa 2:**
- Se `turnstileToken` chegou **vazio** no payload apesar de a Etapa 1 ter capturado um token não vazio: bug de timing/estado no frontend (o token pode ter expirado entre a Etapa 1 manual e o submit, ou o formulário foi resetado) — repetir a Etapa 1 imediatamente antes do submit, sem pausas.
- Se `turnstileToken` chegou **preenchido** e a resposta foi 400 com a mensagem "não foi possível confirmar que você não é um robô": **avançar para a Etapa 3**.
- Qualquer outro status: a causa não é Turnstile — não avance para as próximas etapas deste runbook.

---

## Etapa 3 — Validar a Edge Function (logs)

**Onde visualizar:**
- Dashboard: `Supabase Dashboard → Edge Functions → website-form-submit → Logs`.
- CLI (equivalente, mais rápido para grep):
  ```bash
  supabase functions logs website-form-submit --project-ref uscheppbwhuuwkskhfos
  ```
  Para acompanhar em tempo real enquanto reproduz o problema (recomendado — rode este comando em um terminal e só então repita a Etapa 2 em outra aba):
  ```bash
  supabase functions logs website-form-submit --project-ref uscheppbwhuuwkskhfos --follow
  ```

**Como interpretar o que existe hoje no código:**
O código atual (`index.ts:173`, `index.ts:201`) só chama `console.error(...)` quando o **INSERT no Supabase** falha (`beta_waitlist insert failed` / `contact_messages insert failed`). **Não existe hoje nenhum log da resposta do `siteverify`** — ou seja, se a submissão falhou na validação do Turnstile (status 400, mensagem "não foi possível confirmar..."), os logs padrão **não mostrarão nada** sobre o motivo. Isso é uma lacuna conhecida, não um bug.

- ✅ Se aparecer `beta_waitlist insert failed` ou `contact_messages insert failed` nos logs: a causa é no banco (RLS, constraint, conexão), não no Turnstile — o Turnstile já havia passado antes desse ponto do código.
- ➖ Se **nada** aparecer nos logs para o horário exato da submissão testada na Etapa 2: consistente com a falha estar no `siteverify` (nenhum log é emitido nesse caminho hoje) — isso não é evidência adicional, é a ausência esperada de log. Para obter evidência real do motivo, é necessário o diagnóstico avançado abaixo.

**Diagnóstico avançado (opcional, requer decisão explícita da equipe — não é um passo padrão deste runbook):**
Se as Etapas 1, 2 e 5 não isolarem a causa, pode-se adicionar temporariamente um log da resposta completa do `siteverify` em `index.ts`, logo após `const data = await result.json();` (linha 83):

```ts
console.log("turnstile-siteverify-debug", {
  tokenLength: token.length,
  remoteIp,
  success: data.success,
  errorCodes: data["error-codes"],
  hostname: data.hostname,
  action: data.action,
  challenge_ts: data.challenge_ts,
  cdata: data.cdata,
});
```

Isso exige: aprovação explícita, deploy (`supabase functions deploy website-form-submit`), reprodução do problema, leitura do log, e **remoção do log num segundo deploy** antes de considerar o diagnóstico concluído — nunca deixar esse log em produção permanentemente (evita ruído nos logs e evita registrar dados de requisição além do necessário).

**Critério de saída da Etapa 3:** se a causa não foi confirmada via logs padrão, **avançar para a Etapa 4** assumindo que o diagnóstico avançado acima será necessário para fechar o ciclo com certeza total; ou ir direto para a Etapa 5 se já houver suspeita forte de configuração no Cloudflare.

---

## Etapa 4 — Validar o retorno do SiteVerify

Campos da resposta de `https://challenges.cloudflare.com/turnstile/v0/siteverify` (obtidos só com o diagnóstico avançado da Etapa 3, ou fornecidos pelo suporte Cloudflare caso disponibilizado por outro meio):

| Campo | Significado | Como usar no diagnóstico |
|---|---|---|
| `success` | `true`/`false` — se o token era válido no momento da chamada. | Se `false`, os próximos campos explicam o motivo. |
| `error-codes` | Array de strings, presente só quando `success:false`. Valores documentados pela Cloudflare: `missing-input-secret`, `invalid-input-secret`, `missing-input-response`, `invalid-input-response`, `bad-request`, `timeout-or-duplicate`, `internal-error`, `invalid-widget-id`, `invalid-parsed-secret`. | Ver tabela de mapeamento abaixo — cada código aponta para uma causa raiz diferente. |
| `hostname` | O hostname da página onde o desafio foi resolvido (não o hostname configurado no widget). | Comparar com `www.appborah.com.br`/`appborah.com.br`. Se vier um valor inesperado (`localhost`, um domínio de preview, vazio), confirma que o token foi gerado num contexto diferente do esperado. |
| `action` | Valor do atributo `data-action` do widget, se configurado. | Os 3 formulários do BORAH **não definem** `data-action` — esperado vir vazio/ausente. Se vier preenchido com algo inesperado, o HTML foi alterado sem atualização deste runbook. |
| `challenge_ts` | Timestamp ISO8601 de quando o desafio foi resolvido. | Comparar com o horário real da submissão (Etapa 2). Uma diferença grande (vários minutos) indica token usado após expiração (~300s de validade). |
| `cdata` | Dado customizado do atributo `data-cdata`, se configurado. | Não usado no BORAH — esperado vir vazio/ausente. |

**Mapeamento de `error-codes` → causa raiz:**

| `error-codes` contém | Causa raiz | Próxima ação |
|---|---|---|
| `invalid-input-secret` / `invalid-parsed-secret` | O valor de `TURNSTILE_SECRET_KEY` no Supabase não é uma secret key válida do Cloudflare (formato errado ou secret de outro produto). | Etapa 5, item Secret Key. |
| `missing-input-secret` | A secret não chegou na chamada — indicaria bug no código (`Deno.env.get` retornando vazio apesar do secret existir). | Reconferir `supabase secrets list` e o deploy mais recente da função. |
| `invalid-input-response` | O token em si é inválido para essa secret — inclui o caso de o token ter sido gerado por um widget de **site key diferente** da que corresponde a essa secret (par site/secret incorreto), e o caso de hostname não autorizado (token nunca foi legitimamente emitido). | Etapa 5, itens Site Key + Secret Key + Domínios permitidos. |
| `timeout-or-duplicate` | Token expirado (>300s) ou já usado uma vez antes (reenvio, duplo clique, cache). | Confirmar que `resetTurnstile()` está sendo chamado (`main.js:159`) e testar sem demora entre resolver o widget e enviar o formulário. |
| `bad-request` | A requisição ao `siteverify` está malformada (parâmetros ausentes/incorretos). | Revisar `verifyTurnstile()` em `index.ts:68-85` — não deveria ocorrer, contrato já revisado. |
| `internal-error` | Erro temporário do lado da Cloudflare. | Repetir o teste depois de alguns minutos antes de investigar mais. |
| `invalid-widget-id` | Referência a um widget que não existe/foi removido no painel Cloudflare. | Etapa 5 — confirmar que o widget da site key `0x4AAAAAAEAwMmxH12OHlb04` ainda existe e não foi excluído. |

**Critério de saída da Etapa 4:** qualquer `error-codes` recebido aponta diretamente para um item específico da Etapa 5 — **sempre avançar para a Etapa 5** para confirmar/corrigir a causa apontada.

---

## Etapa 5 — Validar a configuração no painel Cloudflare

Acessar `https://dash.cloudflare.com/?to=/:account/turnstile` → localizar o widget correspondente à site key usada em produção (`0x4AAAAAAEAwMmxH12OHlb04`, presente em `site/index.html`, `site/contato/index.html`, `site/suporte/index.html`).

Checklist completo a conferir:

- [ ] **Site Key** — o valor exibido no painel para este widget é exatamente `0x4AAAAAAEAwMmxH12OHlb04` (sem espaços, sem caracteres extras, sem confundir com outro widget do mesmo projeto).
- [ ] **Secret Key** — copiar o valor exibido no painel (Cloudflare mostra o valor completo, diferente do Supabase que só mostra metadados). Comparar/rotacionar contra o que está configurado no Supabase:
  ```bash
  supabase secrets list --project-ref uscheppbwhuuwkskhfos
  ```
  Isso só confirma **que existe** um valor para `TURNSTILE_SECRET_KEY` e a data em que foi definido — não mostra o valor em si (o Supabase nunca expõe o conteúdo de uma secret já configurada). Se houver dúvida sobre o valor estar correto, a única forma objetiva de eliminar a dúvida é copiar a Secret Key exibida agora no painel Cloudflare e rodar:
  ```bash
  supabase secrets set TURNSTILE_SECRET_KEY=<valor-copiado-do-painel> --project-ref uscheppbwhuuwkskhfos
  ```
  (ação de correção, não de diagnóstico — só executar após decisão da equipe).
- [ ] **Hostnames / Domínios permitidos** — a lista de domínios configurada para este widget deve conter, no mínimo:
  - `appborah.com.br`
  - `www.appborah.com.br`
  - (opcional, só se a equipe testar localmente) `localhost`
  Qualquer domínio de teste antigo (ex.: um domínio de preview, um `github.io`, um domínio different usado durante o desenvolvimento) que **não** seja mais usado pode ser removido, mas sua presença isolada não é a causa do problema — a causa é a **ausência** dos domínios reais de produção nessa lista.
- [ ] **Widget** — confirmar que não é um dos widgets de teste públicos documentados pela própria Cloudflare (site keys que começam com `1x`, `2x` ou `3x` seguidas de zeros são chaves de teste que sempre passam, sempre bloqueiam, ou forçam interação — nunca devem estar em produção). A site key em uso (`0x4AAAAAAEAwMmxH12OHlb04`) não segue esse padrão, então este item já está OK por inspeção, mas vale reconfirmar visualmente no painel que o widget está marcado como widget real (não um dos exemplos da documentação da Cloudflare).
- [ ] **Ambiente** — confirmar no painel que o widget não está pausado/desabilitado (Cloudflare permite desativar um widget sem excluí-lo).
- [ ] **Modo do widget** (Managed / Non-Interactive / Invisible) — não é uma causa provável para este caso (o código usa renderização implícita via `data-sitekey`, compatível com qualquer modo), mas registrar qual modo está ativo para referência futura.

**Critério de saída da Etapa 5:** qualquer item marcado incorreto acima **é a causa raiz confirmada** — a correção é pontual (ajustar a lista de domínios, ou corrigir a secret) e não exige nenhuma mudança de código.

---

## Etapa 6 — Árvore de decisão

```
INÍCIO: reproduzir uma submissão real do formulário
│
├─ Etapa 1: getResponse() retorna vazio mesmo após resolver o widget?
│   ├─ SIM → causa client-side/Cloudflare. Ir direto à Etapa 5.
│   │         Verificar "Hostnames / Domínios permitidos" primeiro
│   │         (causa mais comum de token vazio).
│   │         Se domínios OK → verificar "Widget" (pausado/excluído).
│   │         Se tudo OK → suspeitar de bloqueador de anúncios/extensão
│   │         do navegador do usuário (testar em aba anônima).
│   │
│   └─ NÃO (token gerado) → seguir para Etapa 2.
│
├─ Etapa 2: o payload da requisição contém turnstileToken vazio,
│           apesar do token ter sido gerado na Etapa 1?
│   ├─ SIM → bug de timing/estado no frontend (token expirou entre a
│   │         geração e o submit, ou o form foi resetado antes do
│   │         envio). Repetir o teste sem pausas entre resolver o
│   │         widget e clicar em enviar.
│   │
│   └─ NÃO (token chegou preenchido) → checar o status HTTP de resposta.
│       ├─ 200/success:true → sem problema, Turnstile funcionando.
│       ├─ 500 → problema é no INSERT do Supabase, Turnstile já passou.
│       │        Não é escopo deste runbook.
│       ├─ 400, mensagem "verificação de segurança ausente" → não deveria
│       │        acontecer se turnstileToken chegou preenchido; se
│       │        acontecer, é bug real no parsing do payload em
│       │        index.ts:119/133 — revisar código.
│       └─ 400, mensagem "não foi possível confirmar que você não é um
│                robô" → seguir para Etapa 3/4.
│
├─ Etapa 3/4: qual error-code o siteverify retornou (via diagnóstico
│             avançado)?
│   ├─ invalid-input-secret / invalid-parsed-secret
│   │     → Etapa 5: corrigir Secret Key no Supabase.
│   ├─ invalid-input-response
│   │     → Etapa 5: verificar Site Key + Secret Key + Domínios
│   │       permitidos (ordem de prioridade: domínios primeiro, é a
│   │       causa mais comum).
│   ├─ timeout-or-duplicate
│   │     → não é problema de configuração; confirmar reset do widget
│   │       (main.js:159) e testar com envio mais rápido.
│   ├─ missing-input-secret
│   │     → verificar se o deploy mais recente da função realmente
│   │       inclui a leitura do secret; reconfirmar
│   │       `supabase secrets list`.
│   ├─ invalid-widget-id
│   │     → Etapa 5: confirmar que o widget não foi excluído no painel.
│   └─ internal-error
│         → repetir o teste depois de alguns minutos (falha temporária
│           da Cloudflare, não do BORAH).
│
└─ Se nenhum dos ramos acima reproduzir o problema (tudo passou nos
   testes manuais) → falha é intermitente. Suspeitar de: rede instável
   do usuário reportante, extensão/bloqueador específico do navegador
   dele, ou um teste anterior a 2026-07-29 18:33 (commit 1db63ef) —
   antes dessa data o site key era um placeholder inválido, então
   qualquer relato de falha anterior a esse horário não é mais
   reproduzível nem relevante para o estado atual do código.
```

---

## Resumo de comandos usados neste runbook

```bash
# Etapa 3 — logs da Edge Function
supabase login
supabase link --project-ref uscheppbwhuuwkskhfos
supabase functions logs website-form-submit --project-ref uscheppbwhuuwkskhfos --follow

# Etapa 5 — confirmar existência/data da secret (não mostra o valor)
supabase secrets list --project-ref uscheppbwhuuwkskhfos

# Etapa 5 — corrigir a secret, só após confirmar o valor real no painel Cloudflare
supabase secrets set TURNSTILE_SECRET_KEY=<valor-copiado-do-painel> --project-ref uscheppbwhuuwkskhfos
```

```js
// Etapa 1 — console do navegador, na página real de produção
typeof window.turnstile
document.querySelector('.cf-turnstile').innerHTML.length
window.turnstile.getResponse(document.querySelector('.cf-turnstile'))
```
