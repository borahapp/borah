# RC-02D — Smoke Test (roteiro para execução em ambiente real)

**Status: NÃO EXECUTADO.** Este sandbox não tem emulador/dispositivo Android ou iOS nem acesso a um backend Supabase de produção real — não há como instalar o app e clicar nos fluxos. O que segue é o roteiro exato para quem executar isso num ambiente real (device físico/emulador + build de produção + projeto Supabase de produção), não um resultado simulado.

## Pré-requisitos para executar

1. Build de produção instalada: `flutter build apk --release` (ou `appbundle`/`ipa`) com os 5 `--dart-define` reais de produção (Supabase URL/anon key, Sentry DSN, PostHog key, ambiente).
2. Projeto Supabase de produção provisionado e migrado (`supabase db push` das migrations em `app/supabase/migrations`).
3. Acesso ao Supabase Dashboard (Table Editor + Auth), ao projeto Sentry e ao projeto PostHog daquele ambiente.
4. Um segundo dispositivo/conta, para testar convite/confirmação de presença com 2+ usuários reais.

## Roteiro passo a passo

| # | Ação no app | Validação esperada |
|---|---|---|
| 1 | Criar conta (e-mail/senha) | Linha nova em `auth.users`; trigger cria linha correspondente em `profiles` |
| 2 | Confirmar e-mail (link recebido) | `auth.users.email_confirmed_at` preenchido; app libera acesso pós-confirmação |
| 3 | Completar perfil (nome, bio, foto) | Linha em `profiles` atualizada; upload aparece no bucket do Supabase Storage |
| 4 | Criar grupo | Linha em `groups` + linha em `group_members` com o criador como owner |
| 5 | Gerar/copiar código de convite | Código exibido corresponde ao valor persistido para o grupo |
| 6 | Segundo usuário entra pelo código | Nova linha em `group_members` (role membro) vinculada ao mesmo `group_id` |
| 7 | Criar um rolê no grupo | Linha em `events` (ou tabela equivalente) vinculada ao `group_id` |
| 8 | Ambos os usuários confirmam presença | Linhas de confirmação (RSVP) vinculadas ao `event_id` e a cada `user_id` |
| 9 | Avaliação Coletiva do rolê (nota + fotos) | Linha em `collective_reviews` (ou equivalente); fotos no Storage; notificação "avaliação liberada" disparada |
| 10 | Checar Ranking do Grupo | Lugar avaliado aparece/atualiza posição no ranking do grupo |
| 11 | Checar Estatísticas e Memórias | Números refletem o rolê recém-criado; Memórias lista o evento na timeline |
| 12 | Checar notificações recebidas | Convite, novo rolê, confirmação e avaliação liberada aparecem na lista do destinatário certo |
| 13 | Forçar um erro conhecido (ex.: rede off durante upload) | Evento aparece no Sentry Issues, com stack trace e contexto de usuário |
| 14 | Navegar pelas telas principais | Eventos de pageview/ação aparecem em tempo real no PostHog Live Events |
| 15 | Excluir a conta de teste (Configurações → Excluir conta) | Conta some de `auth.users`; conteúdo do grupo permanece (histórico preservado), desvinculado do nome |

## Sistemas a validar (fora do fluxo, checagem direta)

- **Supabase**: Table Editor confirma as linhas acima; Auth confirma o ciclo de vida da conta; Storage confirma os uploads.
- **Sentry**: Issue do erro forçado no passo 13 aparece com ambiente = produção.
- **Analytics (PostHog)**: eventos do passo 14 aparecem em Live Events, sem PII vazando nas propriedades.

## O que fica de fora deste roteiro

Push notification foi removida do escopo de validação — conforme `docs/store/branding.md`, o BORAH não tem push nesta versão, só notificações dentro do app (item 12 acima já cobre isso).

## Próximo passo real

Rodar este roteiro manualmente contra um ambiente de staging/produção real, com um dispositivo físico ou emulador Android/iOS configurado — nenhum passo aqui pode ser executado dentro deste sandbox.
