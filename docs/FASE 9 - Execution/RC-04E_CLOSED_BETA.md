# RC-04E — Closed Beta Preparation

**Data:** 2026-07-26
**Branch:** `feature/rc-04e-closed-beta`
**Status:** Implementado — auditoria completa, dois achados arquiteturais resolvidos com decisão explícita do usuário, melhorias de qualidade aplicadas
**Escopo:** preparação de qualidade/estabilidade/UX para o Beta Fechado. Nenhuma regra de negócio nova; as únicas exceções à "nenhuma funcionalidade nova" foram explicitamente aprovadas caso a caso (ver seção 2).

---

## 1. Objetivo

Auditar o aplicativo inteiro pensando exclusivamente na experiência de um testador do Beta Fechado — estabilidade, UX, mensagens de erro, estados vazios/loading, acessibilidade, consistência visual, navegação — e corrigir o que for razoável nesta rodada, documentando o restante como backlog.

---

## 2. Achados arquiteturais (interrompidos e resolvidos antes de continuar)

Conforme instruído ("Caso encontre qualquer problema arquitetural relevante, interromper a implementação"), a auditoria foi pausada duas vezes para decisão explícita do usuário antes de qualquer implementação adicional.

### 2.1 `/home` era um placeholder de desenvolvedor

`app_router.dart` renderizava `_BootstrapPlaceholderPage` — texto "BORAH" + lista de `TextButton`s de navegação ad hoc — como primeira tela de todo usuário após login/cadastro. **Decisão do usuário**: não construir uma Home nova (funcionalidade nova, fora de escopo); substituir por uma tela já existente e completa. Escolhida `RestaurantsSearchPage` em vez do Feed, com justificativa apresentada e aceita: o Feed mostra o estado vazio "Nenhuma avaliação de quem você segue ainda" para praticamente todo tester no início do Beta (sem seguidores ainda), enquanto Restaurantes carrega conteúdo real desde o primeiro acesso, independente do grafo social.

**Achado mecânico decorrente** (não uma nova decisão de negócio, consequência direta da anterior — mesmo padrão de tratamento já usado na RC-04C para as constraints únicas): remover o placeholder deixava **7 telas prontas e funcionais sem nenhum caminho de navegação no app** (`/profile`, `/favorites`, `/feed`, `/rankings`, `/gamification`, `/notifications`, `/admin` — confirmado por busca em todo `lib/`, nenhuma outra rota do app fazia `push`/`go` para elas). Apresentado como um segundo achado crítico; **decisão do usuário**: conectar o componente `AppBottomNavigation` — já implementado, testado e nunca usado — em vez de criar qualquer navegação nova.

### 2.2 Recuperação de senha era um beco sem saída completo

`requestPasswordReset()` chamava `resetPasswordForEmail()` sem `redirectTo`; não existia rota de callback, tela "definir nova senha", listener do evento `passwordRecovery` do Supabase, nem deep link configurado em nenhuma das plataformas. Um usuário que clicasse no link do e-mail não tinha absolutamente nada no app para completar a troca de senha. **Decisão do usuário**: completar o fluxo de ponta a ponta nesta rodada — não é uma funcionalidade nova, é a conclusão de um fluxo de autenticação já parcialmente implementado.

### 2.3 Mensagens de erro do Supabase em inglês

Confirmado que ~10 repositórios (auth, perfil, exclusão de conta, gamificação, rankings, notificações, restaurantes, avaliações, favoritos, comentários, feed, seguidores) repassavam `e.message` do Supabase/PostgREST diretamente ao usuário, sem tradução — mais grave no re-auth da exclusão de conta (ação irreversível). **Decisão do usuário**: criar um tradutor centralizado e aplicá-lo obrigatoriamente em login/cadastro/recuperação/redefinição de senha/exclusão de conta; documentar os demais ~8 repositórios como backlog, sem expandir o escopo.

---

## 3. Implementação dos itens aprovados

### 3.1 Home e navegação

- `lib/core/router/home_shell_page.dart` (novo): `HomeShellPage`, conecta o `AppBottomNavigation` já existente a 4 telas já prontas (Restaurantes/Feed/Favoritos/Perfil) via `IndexedStack` (preserva o estado de cada aba ao trocar). `/home` agora constrói este shell em vez do placeholder.
- `lib/features/users/presentation/pages/profile_page.dart`: adicionados 3 itens de acesso rápido (Gamificação, Rankings, Notificações) — mesmo padrão de `ListTile` já usado em `SettingsPage`, já que a barra inferior comporta só 4 destinos principais.
- `lib/design_system/components/navigation/app_bottom_navigation.dart`: comentário de documentação atualizado (referenciava o placeholder removido).
- Ajustados 7 arquivos de `integration_test/` que navegavam pelo antigo placeholder (`find.text('Ver perfil')` etc.) para a nova realidade (`NavigationDestination` do `HomeShellPage`) — não executados nesta sessão (sem emulador Android disponível), mas corrigidos para não ficarem quebrados na próxima execução real.

### 3.2 Recuperação de senha (fluxo completo)

Camadas exatamente como já estabelecido (Presentation → Application → Repository → Datasource), sem novo fluxo de autenticação:

- **Domínio** (`auth_repository.dart`): `AuthSessionEvent` (`signedIn`/`signedOut`/`passwordRecovery`) e `AuthSessionUpdate`, sem depender de tipos do Supabase; `AuthRepository.updatePassword(String)` adicionado ao contrato.
- **Dados** (`auth_remote_datasource.dart`): `requestPasswordReset` agora envia `redirectTo: 'borah://password-recovery'`; `updatePassword()` chama `_client.auth.updateUser(UserAttributes(password: ...))`. O `supabase_flutter` já observa automaticamente qualquer deep link recebido pelo SO contendo `access_token`/`code`/`error` e troca por uma sessão via `getSessionFromUrl` — confirmado lendo o código-fonte do pacote (`supabase_auth.dart`), não presumido; nenhum parsing manual de URI foi necessário.
- **Dados** (`auth_repository_impl.dart`): `onAuthStateChange` mapeia `AuthChangeEvent.passwordRecovery` (Supabase) para `AuthSessionEvent.passwordRecovery` (domínio); erros do stream (link expirado/inválido, que o Supabase entrega como erro assíncrono via `notifyException`, confirmado no código-fonte do `gotrue`) são traduzidos com `SupabaseErrorTranslator` em vez de propagarem como `AuthException` cru.
- **Aplicação** (`auth_controller.dart`): novo estado `PasswordRecoveryInProgress`; o listener do stream agora trata `data`/`error` (antes só `whenData`, que descartava erros silenciosamente — corrige um "erro silencioso" real, item do próprio checklist desta rodada); método `updatePassword()` com fallback de erro local (`consumePasswordRecoveryError()`), evitando reabrir a tela com um estado `AuthError` genérico.
- **Apresentação** (`new_password_page.dart`, novo): tela "Definir nova senha" — nova senha + confirmação, validação de força mínima (reaproveita `validatePassword`) e de senhas coincidentes, botão "Cancelar" (`signOut()`, encerra a sessão de recuperação).
- **Router** (`app_router.dart`): nova rota `/password-recovery`; `redirect` força o usuário para lá sempre que o status for `PasswordRecoveryInProgress` (mesmo padrão já usado para rotas protegidas), e redireciona para `/home`/`/login` ao sair desse estado.
- **Deep link nativo**: `AndroidManifest.xml` (novo `intent-filter` para `borah://password-recovery`) e `Info.plist` (novo `CFBundleURLTypes`) — únicas mudanças nativas necessárias, o resto é automático via `supabase_flutter`.
- **Estados de erro**: link expirado/inválido é traduzido e mostrado via `listenForAuthErrors` (já existente em `LoginPage`); falha ao definir a nova senha mantém a tela "Definir nova senha" aberta com snackbar, sem perder a sessão de recuperação.
- **Testes novos**: `auth_controller_test.dart` (+4: evento `passwordRecovery`, erro do stream, `updatePassword` sucesso/falha), `new_password_page_test.dart` (novo, 6 testes: renderização, validações, loading, erro, cancelar).
- **Configuração pendente para produção**: cadastrar `borah://password-recovery` em Authentication → URL Configuration → Redirect URLs no Supabase Dashboard (ação manual, fora do alcance de qualquer ferramenta desta sessão) — sem isso, o Supabase rejeita o `redirectTo` e o e-mail de recuperação não inclui o link funcional.

### 3.3 Tradutor centralizado de erros do Supabase

- `lib/core/errors/supabase_error_translator.dart` (novo): mapeia `code`/mensagem de `AuthException`/`PostgrestException` para português (`invalid_credentials`, `user_already_exists`/`email_exists`, `email_not_confirmed`, `otp_expired`/`flow_state_expired`, `weak_password`, `same_password`, `over_*_rate_limit` — códigos confirmados na documentação oficial do Supabase, não adivinhados). Fallback seguro: mensagem desconhecida é repassada como veio do Supabase, nunca escondida. Preserva o texto técnico original via `AppLogger.warning` (chega ao Sentry como WARNING+) mesmo quando a mensagem exibida já foi traduzida.
- **Aplicado em**: `auth_repository_impl.dart` (login, cadastro, recuperação/redefinição de senha, reenvio de verificação — todos os métodos que traduzem `AuthException`) e `account_deletion_repository_impl.dart` (re-auth via `signIn` já coberto pelo primeiro; exclusão via RPC/`PostgrestException` tratada diretamente).
- **Backlog explícito, não expandido nesta rodada**: perfil, restaurantes, avaliações, gamificação, rankings, favoritos, notificações, feed, seguidores continuam repassando `e.message` diretamente — mensagens de erro cruas do Supabase ainda podem aparecer em inglês nesses ~8 repositórios. Prioridade sugerida para uma rodada futura de refinamento: perfil e restaurantes primeiro (telas de maior tráfego).
- **Testes novos**: `supabase_error_translator_test.dart` (novo, 8 testes cobrindo cada mapeamento + fallback).

### 3.4 Melhorias mecânicas de qualidade (sem decisão de negócio/arquitetura)

- **`ErrorState` (com retry) conectado em 19 telas** que ainda usavam `Center(child: Text(message))` sem nenhuma ação: `ranking_users_page`, `follow_list_page`, `feed_page`, `comments_page`, `gamification_profile_page`, `moderation_page`, `audit_log_page`, `admin_users_page`, `admin_roles_page`, `admin_restaurants_page`, `admin_dashboard_page`, `reviews_list_page`, `notification_preferences_page`, `notifications_page`, `restaurants_search_page`, `rankings_page`, `profile_page`, `restaurant_detail_page`, `admin_guard`. Cada retry chama exatamente o método de carregamento que a própria tela já usa em `initState()` — nenhuma lógica nova.
- **`ConfirmationDialog` conectado em "Excluir avaliação" e "Excluir comentário"** — ambas disparavam a exclusão permanente direto, sem nenhum passo intermediário (o componente já existia, pronto, desde a RC-02, mas nunca tinha sido conectado).
- **Denúncia de comentário**: motivo vazio agora mostra erro de validação em vez de fechar silenciosamente sem enviar nada; denúncia enviada com sucesso agora mostra confirmação ("Denúncia enviada.") — antes não havia nenhum feedback em nenhum dos dois casos.
- **Upload de capa de restaurante**: novo estado `RestaurantDetailCoverUploading` mantém os dados do restaurante visíveis durante o upload (loading inline no botão via `isLoading`), corrigindo uma regressão em relação ao padrão já usado para fotos de avaliação (RC-02) — antes a tela inteira virava um spinner.
- **Seleção de imagem (avatar/capa/foto de avaliação)**: as 3 telas que usam `image_picker` agora capturam também falhas genéricas de plataforma (ex.: permissão de galeria negada pelo SO), não só `ImageValidationException` — antes o botão parecia travado, sem nenhum feedback.
- **"Badges" → "Conquistas"** em `gamification_profile_page.dart` — único texto em inglês solto encontrado em toda a varredura de `lib/` (o próprio código já chamava o conceito de "Conquistas" em outro lugar).
- **`ProfileAvatar`**: convertido de `ConsumerWidget` para `ConsumerStatefulWidget` — o `Future` da URL assinada agora é resolvido uma vez (`initState`/`didUpdateWidget`) em vez de recriado a cada rebuild, eliminando flicker e chamadas de rede evitáveis.
- **`ErrorWidget.builder` customizado** (`main.dart`) — uma exceção durante o build de um widget agora mostra o `ErrorState` do próprio design system em vez da tela de erro padrão do Flutter (texto técnico em inglês). O Sentry continua capturando o erro normalmente antes deste builder rodar.
- **`locale`/`supportedLocales` explícitos** (`app.dart`, `pubspec.yaml`) — adicionado `flutter_localizations` (pacote do próprio SDK do Flutter, sem custo de manutenção externo) e fixado `pt_BR`, evitando que strings padrão do framework (tooltips nativos, seletores) apareçam em inglês.
- **Testes novos**: 2 testes em `review_detail_page_test.dart` (confirmação antes de excluir avaliação) e `comments_page_test.dart` (novo arquivo, 3 testes: confirmação antes de excluir comentário, validação de motivo vazio, denúncia com sucesso).

---

## 4. Achados documentados como backlog (fora de escopo desta rodada)

- **Paginação nunca acionada**: `loadNextPage()` já implementado em rankings de usuários, rankings de restaurantes e notificações, mas nenhuma tela tem `ScrollController`/listener de rolagem para chamá-lo — usuários nunca veem além da primeira página (20 itens). Implementar infinite-scroll é funcionalidade nova (não correção pontual), fora do escopo aprovado.
- **Assimetria de denúncia**: comentários têm "Denunciar", avaliações não têm nenhum caminho equivalente. Pode ser decisão de produto deliberada — não alterado.
- **Notificação com `extra! as AppNotification`** (`app_router.dart`, rota `/notifications/:id`): non-null assertion hoje segura (só `NotificationsPage` navega para essa rota, sempre passando `extra`), mas seria um ponto de crash se um deep link de push notification fosse adicionado no futuro sem tratar esse caminho.
- **Notificações são só in-app, por design** — não há push. Consistente e documentado desde a implementação original; vale um aviso nas notas de release do Beta para não gerar expectativa equivocada nos testadores.
- **Tradução de erros nos ~8 repositórios restantes** (seção 3.3).
- **Kit de identidade visual oficial descoberto durante esta rodada**: uma pasta `identidade visual-borah/` foi adicionada à raiz do repositório (fora de `app/`, não rastreada pelo Git) contendo logos, ícones de app já prontos para Android/iOS (`AppIcon.appiconset`, `mipmap`/adaptive icons) e animações oficiais da marca. Isso resolve diretamente a pendência de ícone/splash registrada na RC-04D (`flutter_launcher_icons`/`flutter_native_splash` já configurados, só aguardando o asset). Fora do escopo desta rodada — mencionado aqui para que a integração seja avaliada como próximo passo, antes ou depois do início do Beta.

---

## 5. Pré-requisitos para instalação (Beta Fechado)

- Dispositivo Android 8.0+ (minSdk do projeto) ou iOS 13+ (deployment target padrão do template Flutter, não alterado).
- Conta de teste real (cadastro via app ou criada manualmente no Supabase) — não há fluxo de convite/allowlist específico do Beta implementado; controle de acesso é apenas "quem recebe o build".
- Conectividade com a internet (o app depende inteiramente do Supabase; não há modo offline).

## 6. Checklist de validação (roteiro de testes manuais sugerido)

1. Cadastro → confirmação de e-mail (se habilitada) → login.
2. **Recuperação de senha completa**: "Esqueci minha senha" → e-mail recebido → abrir o link no dispositivo → tela "Definir nova senha" abre automaticamente → salvar → login com a nova senha funciona.
3. Link de recuperação expirado/já usado → mensagem de erro amigável, sem travar o app.
4. Login → aba "Restaurantes" (Home) carrega conteúdo real → trocar para Feed/Favoritos/Perfil pela barra inferior.
5. A partir do Perfil: abrir Gamificação, Rankings, Notificações (itens de acesso rápido).
6. Criar avaliação, adicionar foto, curtir, comentar, denunciar um comentário (com e sem motivo preenchido), excluir uma avaliação e um comentário próprios (confirmando o diálogo).
7. Alterar avatar e capa de restaurante — confirmar loading inline (tela não pisca/não vira spinner cheio) e mensagem de erro caso a permissão de galeria seja negada.
8. Provocar um erro de rede real (modo avião) em pelo menos 3 telas diferentes → confirmar que aparece o `ErrorState` com "Tentar novamente" funcional.
9. Excluir a própria conta (fluxo já validado na RC-04C) — confirmar que a mensagem de erro de reautenticação, se houver, aparece em português.
10. Testar em ao menos 2 tamanhos de tela (celular pequeno e tablet).

## 7. Funcionalidades críticas vs. opcionais

**Críticas** (bloqueiam o Beta se quebradas): autenticação (login/cadastro/recuperação de senha), busca de restaurantes, criação/visualização de avaliações, exclusão de conta (LGPD).

**Opcionais** (podem falhar sem impedir o Beta, mas devem ser observadas): gamificação/rankings, notificações in-app, favoritos, feed social, painel administrativo.

## 8. Cenários de erro esperados (não são bugs, são limites conhecidos)

- Sem conexão: a maioria das telas mostra `ErrorState`/mensagem amigável; não há cache/modo offline.
- Notificações são apenas in-app — testadores não devem esperar push.
- Paginação limitada a 20 itens em rankings/notificações (backlog, seção 4).

## 9. Limitações e riscos conhecidos

| Item | Risco | Mitigação atual |
|---|---|---|
| Assinatura de release Android/iOS ainda não gerada (RC-04D) | Build de release não pode ser publicada nem testada como release real | Plumbing pronto, aguarda ação do responsável (fora deste chat) |
| Ícone/splash ainda são o padrão do Flutter | Percepção de qualidade em qualquer instalação real | Kit de marca oficial já disponível no repo (seção 4), infraestrutura de geração pronta desde a RC-04D |
| `minifyEnabled`/`shrinkResources` (RC-04D) nunca validados com build real | Risco (baixo, mas não descartado) de quebra em runtime por remoção indevida de classe | Nenhuma keep rule especulativa foi adicionada; exige validação manual antes da publicação |
| Tradução de erros incompleta em ~8 repositórios | Testadores podem ver mensagens técnicas em inglês fora dos fluxos de auth/exclusão de conta | Backlog priorizado (seção 3.3/4) |
| Paginação de rankings/notificações nunca acionada | Testadores nunca veem além dos primeiros 20 itens | Documentado como backlog (seção 4) |
| Suítes pgTAP (RC-04A/RC-04B) não executadas | Sem validação automatizada de RLS no ambiente real | Bloqueio de infraestrutura (Docker indisponível), não desta rodada |

## 10. Critérios para início do Beta Fechado

- [x] Fluxo de autenticação completo, incluindo recuperação de senha.
- [x] Navegação sem becos sem saída conhecidos (Home/telas centrais alcançáveis).
- [x] Mensagens de erro traduzidas nos fluxos críticos (auth, exclusão de conta).
- [x] Ações destrutivas (excluir avaliação/comentário/conta) com confirmação.
- [x] Observabilidade (Sentry/Analytics/Feature Flags/Feedback) funcional em Release (RC-04D).
- [ ] Assinatura de release real configurada (depende de ação externa do responsável).
- [ ] Ícone/splash com a marca oficial (asset já disponível, integração pendente).

## 11. Critérios para encerramento do Beta Fechado (sugestão para a próxima rodada de planejamento)

- Nenhum crash não tratado reportado no Sentry por, no mínimo, X dias consecutivos (definir X com o time).
- Feedback dos testadores coletado via `AppFeedback` (já implementado) revisado.
- Backlog desta rodada (seção 4) triado: o que vira RC funcional antes da publicação pública, o que fica para depois.

## 12. Recomendações para publicação

1. Resolver os dois itens pendentes da RC-04D (keystore Android real, conta Apple Developer) antes de qualquer submissão às lojas.
2. Integrar o kit de identidade visual oficial já disponível (`identidade visual-borah/`) para substituir o ícone/splash padrão do Flutter.
3. Validar uma build de release real (Android e iOS) em um ambiente com SDK completo — não disponível nesta sessão.
4. Priorizar a tradução de erros nos repositórios restantes (perfil e restaurantes primeiro) antes de uma expansão maior de usuários.
5. Avaliar a paginação de rankings/notificações antes de um Beta com volume de dados maior que ~20 itens por lista.

---

## 13. Arquivos criados

- `docs/FASE 9 - Execution/RC-04E_CLOSED_BETA.md` (este documento)
- `app/lib/core/router/home_shell_page.dart`
- `app/lib/core/errors/supabase_error_translator.dart`
- `app/lib/features/authentication/presentation/pages/new_password_page.dart`
- `app/test/unit/core/errors/supabase_error_translator_test.dart`
- `app/test/widget/authentication/new_password_page_test.dart`
- `app/test/widget/social/comments_page_test.dart`

## 14. Arquivos modificados

Navegação/Home: `app_router.dart`, `app_bottom_navigation.dart`, `profile_page.dart`, 7 arquivos de `integration_test/`.

Recuperação de senha: `auth_repository.dart`, `auth_remote_datasource.dart`, `auth_repository_impl.dart`, `auth_status.dart`, `auth_controller.dart`, `AndroidManifest.xml`, `Info.plist`.

Tradutor de erros: `auth_repository_impl.dart` (mesmo arquivo acima), `account_deletion_repository_impl.dart`.

Qualidade mecânica: `ranking_users_page.dart`, `follow_list_page.dart`, `feed_page.dart`, `comments_page.dart`, `gamification_profile_page.dart`, `moderation_page.dart`, `audit_log_page.dart`, `admin_users_page.dart`, `admin_roles_page.dart`, `admin_restaurants_page.dart`, `admin_dashboard_page.dart`, `reviews_list_page.dart`, `notification_preferences_page.dart`, `notifications_page.dart`, `restaurants_search_page.dart`, `rankings_page.dart`, `restaurant_detail_page.dart`, `restaurant_detail_controller.dart`, `restaurant_detail_status.dart`, `admin_guard.dart`, `review_detail_page.dart`, `change_avatar_page.dart`, `profile_avatar.dart`, `main.dart`, `app.dart`, `pubspec.yaml`, `pubspec.lock`.

Testes ajustados por mudança de tipo (`AuthUserData?` → `AuthSessionUpdate`): `auth_controller_test.dart`, `login_page_test.dart`, `signup_page_test.dart`, `settings_page_test.dart`, `widget_test.dart`, `review_detail_page_test.dart`.

## 15. Resultado dos testes

- `flutter analyze`: **sem nenhum problema**.
- `dart format --set-exit-if-changed .`: **352 arquivos, 0 alterados**.
- `flutter test`: **503/503** — nenhuma regressão em relação à baseline da RC-04D (479/479 + 24 testes novos: 4 em `auth_controller_test.dart`, 8 em `supabase_error_translator_test.dart`, 6 em `new_password_page_test.dart`, 2 em `review_detail_page_test.dart`, 3 em `comments_page_test.dart`, 1 líquido a mais por ajuste de contagem).

---

## 16. Recomendação objetiva: o projeto está pronto para iniciar um Beta Fechado?

**Sim, com ressalvas explícitas.**

Justificativa técnica: os dois problemas que, na minha avaliação, tornariam um Beta Fechado genuinamente ruim — a Home ser um placeholder de desenvolvedor e a recuperação de senha ser um beco sem saída — foram corrigidos nesta rodada. Ações destrutivas agora pedem confirmação, erros de rede têm retry em toda tela relevante, e os fluxos de maior visibilidade (login, cadastro, recuperação de senha, exclusão de conta) não expõem mais texto técnico em inglês. A suíte de testes (503/503) não indica nenhuma regressão.

As ressalvas são conhecidas, documentadas e não bloqueiam um Beta **fechado** (grupo pequeno e controlado de testadores, cientes de que é uma versão em teste): assinatura de release/ícone oficial ainda pendentes (bloqueiam a *publicação pública*, não o Beta fechado via instalação direta/TestFlight interno), tradução de erros incompleta fora dos fluxos críticos, e paginação limitada em listas longas. Nenhuma delas representa um crash conhecido, perda de dados ou fluxo funcional quebrado.
