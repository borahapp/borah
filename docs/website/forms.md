# Website Institucional — Formulários (Beta e Contato)

**Contexto:** BETA-11C. Substitui o mecanismo `mailto:` interino da BETA-11B por uma integração real com o Supabase, aprovada em revisão de arquitetura antes da implementação.

---

## 1. Fluxo de escrita

```
Browser → Cloudflare Turnstile → Edge Function (website-form-submit) → service_role → INSERT
```

O navegador **nunca** grava direto nas tabelas. A única porta de entrada é a Edge Function `website-form-submit` (`supabase/functions/website-form-submit/index.ts`), que roda com a chave `service_role` (ignora RLS) depois de validar:

1. **Honeypot** — um campo (`hp_field`) escondido via CSS (`.hp-field`, `site/assets/css/style.css`) e de `aria-hidden`/`tabindex="-1"` (invisível também para leitores de tela, ao contrário do utilitário `.visually-hidden` do design system, que é lido de propósito). Qualquer valor não vazio nesse campo indica um bot e a submissão é descartada silenciosamente.
2. **Tempo mínimo de preenchimento** — o site registra `pageLoadedAt` (`Date.now()`) quando o JS carrega e envia como `startedAt` no payload. A função rejeita envios com menos de 2 segundos de diferença — bots costumam enviar em bem menos de 100ms.
3. **Cloudflare Turnstile** — o token gerado pelo widget no navegador é verificado no servidor contra `https://challenges.cloudflare.com/turnstile/v0/siteverify`, usando o `TURNSTILE_SECRET_KEY` (nunca exposto ao navegador). Sem secret configurado, a função recusa por padrão (falha fechada).

Só depois dessas 3 camadas a função insere na tabela correta.

## 2. Por que uma única Edge Function para os dois formulários

`website-form-submit` recebe um campo `type` (`"waitlist"` ou `"contact"`) e despacha internamente — evita duplicar a lógica de CORS/Turnstile/honeypot em duas funções separadas. Decisão tomada em revisão de arquitetura antes da implementação.

## 3. Por que `anon` não tem nenhum privilégio nas tabelas

Achado da auditoria desta rodada: **nenhuma tabela do projeto BORAH concede qualquer privilégio ao papel `anon`** — invariante documentada explicitamente em `supabase/migrations/20260720130000_grant_authenticated_privileges.sql` ("`anon` não recebe nada - nenhuma policy do projeto concede acesso a `anon`"). Em vez de abrir uma exceção com uma policy de `INSERT` para `anon` (desenho inicialmente cogitado e descartado em revisão), a BETA-11C **preserva essa invariante** — toda escrita passa pelo `service_role` da Edge Function, nunca por uma policy pública. Isso reduz a superfície de ataque: mesmo que alguém descubra a URL/chave pública do projeto, não há nenhum caminho de escrita direta às tabelas.

## 4. Schema

Ver as migrations para o DDL completo:
- `supabase/migrations/20260728100000_create_beta_waitlist.sql`
- `supabase/migrations/20260728100015_create_contact_messages.sql`

### `beta_waitlist`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | uuid | PK |
| `email` | text | dedup case-insensitive via `unique index (lower(email))` |
| `name` | text, nullable | opcional |
| `source` | text, default `'website'` | ver seção 5 |
| `status` | text, `check` | ver seção 6 |
| `created_at` | timestamptz | default `now()` |
| `confirmed_at` | timestamptz, nullable | preenchido manualmente |
| `invited_at` | timestamptz, nullable | preenchido manualmente |
| `notes` | text, nullable | uso interno |

### `contact_messages`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | uuid | PK |
| `name` | text | obrigatório |
| `email` | text | obrigatório |
| `subject` | text, nullable | opcional |
| `message` | text | obrigatório |
| `status` | text, `check` | `new` / `read` / `archived` — triagem manual |
| `created_at` | timestamptz | default `now()` |

## 5. Semântica de `source`

Não é restringido por `CHECK` (para não travar novas origens ainda não previstas), mas o vocabulário esperado nesta fase é:

`website`, `instagram`, `linkedin`, `qr_code`, `manual`, `friend`, `google`, `closed_beta`

O formulário do site sempre envia `source: "website"` — os demais valores são para uso manual (ex.: inserir via Supabase Studio um lote de e-mails capturados presencialmente com `source: 'qr_code'`).

## 6. Semântica de `status` (`beta_waitlist`)

Fluxo esperado, curado manualmente via Supabase Studio (não existe painel administrativo no app para isso ainda):

1. **`pending`** — acabou de entrar na lista (estado inicial, definido pela Edge Function).
2. **`invited`** — recebeu o convite por e-mail para o Beta Fechado (atualizado manualmente quando o convite é enviado; preencher `invited_at`).
3. **`confirmed`** — aceitou o convite e efetivamente criou a conta no app (atualizado manualmente ao cruzar o e-mail da waitlist com o cadastro real no app; preencher `confirmed_at`).
4. **`declined`** — pediu para sair da lista, ou não respondeu ao convite.

Não há hoje nenhuma automação que promova o `status` sozinha — é uma decisão deliberada desta rodada (evitar acoplar o site ao app/autenticação, fora do escopo pedido).

## 7. Contrato da API e fluxo do formulário (client-side, `site/assets/js/main.js`)

**Resposta HTTP** (todas as respostas da função, ajustado nesta rodada — ver seção 11):

```json
{ "success": true | false, "message": "texto pronto para exibição" }
```

| Situação | HTTP | `success` |
|---|---|---|
| Cadastro/mensagem gravados | 200 | `true` |
| E-mail duplicado (`beta_waitlist`) | 409 | `false` |
| Validação inválida (e-mail/nome/mensagem/Content-Type/Turnstile ausente) | 400 | `false` |
| Bloqueado por honeypot/tempo mínimo | 200 | `false` (silencioso, não revela a um bot que foi detectado) |
| Erro do Supabase/servidor | 500 | `false` |
| Método não permitido | 405 | `false` |

- **Validação de e-mail**: `type="email"` + `required` no HTML; a Edge Function também valida o formato no servidor (nunca confia só no client).
- **Validação de nome**: `name` continua **opcional** em `beta_waitlist` (decisão de produto já aprovada, campo nullable); quando informado, a função exige um mínimo de 2 caracteres (HTTP 400 caso contrário). Em `contact_messages`, `name` continua obrigatório (já era antes).
- **Duplicidade**: a função retorna HTTP 409 + `{success:false, message:"Este e-mail já está cadastrado."}` quando o `unique index` rejeita o INSERT (`23505`); o JS do formulário de Beta mostra "Este e-mail já está cadastrado na lista de espera." como uma mensagem de sucesso amigável (o formulário se comporta como se tivesse dado certo do ponto de vista do visitante).
- **Mensagens ao usuário (Beta/waitlist)**: 3 mensagens fixas no cliente (`main.js`), conforme especificado — sucesso ("🎉 Cadastro realizado!..."), duplicado ("Este e-mail já está cadastrado na lista de espera.") e erro genérico ("Não foi possível concluir seu cadastro. Tente novamente em alguns instantes."). Erros de validação (400, exceto duplicidade) mostram a `message` específica devolvida pelo servidor (ex.: "E-mail inválido."), mais informativo que o genérico.
- **Mensagens ao usuário (Contato)**: usa a `message` devolvida pelo servidor diretamente (sem cópia fixa adicional — não fazia parte do prompt que motivou este ajuste).
- **Loading**: o botão de submit mostra "Enviando..." e fica desabilitado durante a chamada; volta ao rótulo original (sucesso ou erro).
- **Erro de rede**: falha do `fetch()` (sem resposta HTTP nenhuma) cai no `.catch()` e mostra a mesma mensagem genérica de erro.
- **Proteção contra múltiplos envios**: o botão de submit é desabilitado assim que clicado e reabilitado só após a resposta (sucesso ou erro); o widget do Turnstile é resetado (`turnstile.reset()`) a cada tentativa, já que um token só pode ser usado uma vez.

## 8. Configuração necessária antes do deploy (pendências reais)

Nenhum destes 3 itens tem um valor real inserido no código — todos são placeholders claramente marcados, seguindo o mesmo padrão já usado para GA4/Search Console (`docs/website/seo.md`):

1. **`TURNSTILE_SECRET_KEY`** — criar um widget gratuito em https://dash.cloudflare.com/?to=/:account/turnstile (não exige mover DNS/hospedagem para a Cloudflare — Turnstile é um produto standalone). Configurar como secret da Edge Function: `supabase secrets set TURNSTILE_SECRET_KEY=...`.
2. **Site key do Turnstile** (público, não é segredo) — substituir `data-sitekey="YOUR-TURNSTILE-SITE-KEY"` nos 3 formulários (`site/index.html`, `site/suporte/index.html`, `site/contato/index.html`).
3. **URL da Edge Function** — substituir `FUNCTIONS_URL` em `site/assets/js/main.js` (hoje `https://YOUR-PROJECT-REF.supabase.co/functions/v1/website-form-submit`) pelo project ref real do BORAH (o mesmo já usado pelo app Flutter, injetado via `--dart-define SUPABASE_URL` em CI — ver `docs/operations/CI_CD_SECRETS.md`).

## 9. Deploy da Edge Function (ação futura, não executada nesta rodada)

```bash
supabase functions deploy website-form-submit
supabase secrets set TURNSTILE_SECRET_KEY=<valor-real>
```

`verify_jwt = false` já está configurado em `supabase/config.toml` para esta função — o Turnstile é a camada de proteção real, não o gateway de JWT do Supabase (a chamada é pública por natureza, o site não tem login).

## 10. Validação executada nesta rodada

Docker não está disponível neste ambiente (confirmado via `docker info`), então não foi possível rodar `supabase functions serve`/`supabase db reset` localmente — mesma limitação já registrada em rodadas anteriores (AR-06/EX-01B). As migrations e a Edge Function foram **escritas e revisadas estaticamente**, seguindo os mesmos padrões (GRANT explícito, RLS habilitada, comentários `ATENÇÃO`) já usados em todas as migrations anteriores do projeto. Antes do primeiro deploy real, recomenda-se rodar `supabase db reset` e `supabase functions serve website-form-submit` localmente (com Docker disponível) para validar de ponta a ponta.

## 11. Divergência registrada: prompt "BETA-11C" recebido após esta rodada já estar em produção

Um prompt formal reapresentando o nome "BETA-11C" pediu uma tabela `waitlist` e uma função `join-waitlist` mais simples (sem Turnstile/honeypot, schema reduzido a `id/name/email/source/created_at`, `name` obrigatório). Nesse momento `beta_waitlist`/`contact_messages`/`website-form-submit` já estavam commitados e mesclados em `main`. Decisão tomada com o usuário: **não recriar/duplicar** — manter a tabela, a função e a proteção Turnstile/honeypot como estão, adotando apenas o ajuste de contrato de resposta que fazia sentido:

- `{ok, error}` → `{success, message}` (mensagem já pronta para exibição, em vez de um código que o cliente precisava traduzir).
- E-mail duplicado: HTTP 200 → **HTTP 409**.
- Validação de nome: adicionado mínimo de 2 caracteres em `beta_waitlist` **quando o nome é informado** — mas o campo **continua opcional** (`name` nullable), não se tornou obrigatório como o prompt pedia, para não reverter a decisão de produto já aprovada em BETA-09B1/BETA-11B. Se a intenção for realmente tornar o nome obrigatório no formulário de Beta, isso exige uma decisão explícita separada (mudaria a migration `name text` → `name text not null` e o HTML do formulário).
- Validação de `Content-Type: application/json` explícita (o prompt pedia; antes era implícito via `req.json()`).
- Loading visual no botão de submit ("Enviando...").

Todos os outros elementos do prompt (Turnstile, honeypot, tempo mínimo, `status`/`invited_at`/`confirmed_at`/`notes`, tabela `contact_messages`) foram **mantidos**, por já estarem revisados, aprovados e em produção — recriá-los do zero introduziria uma segunda tabela/função conflitante e removeria a única camada de proteção contra spam automatizado hoje existente.
