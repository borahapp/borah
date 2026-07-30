# ADR-0002 — Estratégia de Autenticação Multi-Provedor (métodos nomeados vs. dispatcher unificado)

**ID:** ADR-0002
**Título:** Estratégia de extensão do `AuthRepository` para múltiplos provedores de autenticação (E-mail, Google, Apple, Facebook, Anonymous)
**Status:** Aprovado
**Data:** 2026-07-30
**Autor da decisão:** Product Owner do BORAH (aprovação registrada em sessão de planejamento da sprint AUTH-01)

---

## 1. Contexto

A sprint AUTH-01 tem como objetivo preparar a arquitetura de autenticação do app Flutter do BORAH para suportar múltiplos provedores (Google, Apple, Facebook, Anonymous), além do login por e-mail já implementado. Antes de qualquer alteração de código, uma investigação da arquitetura existente (`app/lib/features/authentication/`) confirmou que a infraestrutura de autenticação **já existe e está em produção**: `AuthRepository` (domínio), `AuthRepositoryImpl`/`AuthRemoteDatasource` (dados, sobre `supabase_flutter`), `AuthController`/`AuthStatus` (aplicação, Riverpod) e proteção de rotas via `redirect` do GoRouter (`core/router/app_router.dart`). Login por e-mail, cadastro, recuperação de senha e verificação de e-mail já estão implementados e cobertos por parte dos 503 testes unitários/widget do projeto.

Isso eliminou a hipótese inicial de "criar toda a arquitetura do zero" (que geraria uma arquitetura paralela) e trouxe a decisão real desta ADR: **qual formato de contrato usar no `AuthRepository` para acomodar os 4 novos provedores**, dado que o app deve crescer continuamente e novos provedores (ex.: Microsoft, GitHub) podem surgir no futuro.

## 2. Problema

Dois formatos de contrato foram propostos para os métodos de login social/anônimo:

- **Opção A:** um método nomeado por provedor (`signInWithGoogle()`, `signInWithApple()`, `signInWithFacebook()`, `signInAnonymously()`), adicionado à interface `AuthRepository` já existente.
- **Opção B:** um único método dispatcher (`Future<void> signIn(AuthCredential credential)`), recebendo uma `sealed class AuthCredential` com uma subclasse por provedor (`GoogleCredential`, `AppleCredential`, `FacebookCredential`, `AnonymousCredential`), evitando crescer a interface pública a cada novo provedor.

A decisão impacta: a assinatura pública do `AuthRepository`/`AuthController` que as sprints futuras (conexão real de cada SDK) vão herdar, o esforço de adicionar um provedor novo depois, e a superfície de testes (`MockAuthRepository`, via `mocktail`, em 9 arquivos de teste).

## 3. Alternativas avaliadas

### Opção A — Métodos nomeados por provedor

```dart
abstract interface class AuthRepository {
  // ... métodos já existentes (signUp, signIn, signOut, requestPasswordReset,
  // updatePassword, resendVerificationEmail) ...

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signInWithFacebook();
  Future<void> signInAnonymously();
}
```

- **Prós:** segurança de tipos plena por provedor (cada método ganhará, na sprint que conectar o SDK real, exatamente os parâmetros que precisa — ex.: `idToken` para Google); espelha 1:1 a API do próprio `GoTrueClient` do Supabase (`signInWithIdToken`, `signInAnonymously`), reduzindo a distância entre domínio e SDK; consistente com o padrão já adotado no projeto (um método por operação: `signUp`, `signIn`, `requestPasswordReset`, ...); descoberta trivial via autocomplete; não exige nenhum conceito novo — os testes existentes (`MockAuthRepository extends Mock implements AuthRepository`, via `mocktail`) absorvem os métodos novos sem qualquer alteração.
- **Contras:** a interface cresce em número de métodos a cada provedor novo (cada crescimento, porém, é estritamente aditivo); alguma repetição estrutural no `AuthController` (mitigada nesta implementação com um helper privado compartilhado, `_signInWithProvider`).
- **Impacto de manutenção:** a 2 anos, custo desprezível (cada provedor novo = ~3 linhas por camada, 4 arquivos). A 5 anos, se surgir a necessidade de operações que tratam provedores de forma genérica (linkar múltiplas credenciais à mesma conta, listar provedores vinculados), o custo de migrar para a Opção B se paga — nesse momento, com os formatos reais de credencial de 3+ provedores já implementados e testados, não especulados.

### Opção B — Dispatcher unificado com `sealed class`

```dart
sealed class AuthCredential {
  const AuthCredential();
}
final class GoogleCredential extends AuthCredential {
  const GoogleCredential({required this.idToken, this.accessToken});
  final String idToken;
  final String? accessToken;
}
// ... AppleCredential, FacebookCredential, AnonymousCredential ...

abstract interface class AuthRepository {
  Future<void> signIn(AuthCredential credential); // substitui/convive com signIn(email, password)?
}
```

- **Prós:** um único ponto de entrada para provedores baseados em token; adicionar um provedor novo não exige método novo na interface pública — apenas uma subclasse de `AuthCredential` e um `case` no `switch` exaustivo do datasource; útil especificamente para features futuras de "gerenciar múltiplos provedores vinculados à mesma conta".
- **Contras (determinantes para a rejeição nesta sprint):**
  1. `signIn(email, password)` já é usado hoje por `login_page.dart` e pelos testes existentes com essa assinatura — unificá-lo sob `AuthCredential` seria uma alteração de contrato já em uso, violando a exigência explícita desta sprint de preservar integralmente a arquitetura e a UI existentes. A alternativa (manter `signIn(email, password)` separado e criar `signInWithProvider(AuthCredential)` só para os novos) introduz **mais** assimetria de design, não menos.
  2. O formato real de credencial de cada SDK (Google/Apple/Facebook) ainda é desconhecido nesta sprint — esta mesma sprint decidiu deliberadamente não adicionar os SDKs nativos (`google_sign_in`, `sign_in_with_apple`, `flutter_facebook_auth`) ao `pubspec.yaml`. Desenhar `AuthCredential` agora é apostar num formato sem os dados reais dos 3 SDKs (que diferem entre si: idToken+accessToken para Google, identityToken para Apple, accessToken para Facebook via `signInWithOAuth`, não `signInWithIdToken`).
  3. `AuthCredential` seria, na prática, uma segunda representação de identidade de sessão convivendo com `AuthUserData`/`AuthSessionUpdate` já existentes — o tipo de duplicação conceitual que esta sprint pediu explicitamente para evitar.
  4. O objetivo declarado de "desacoplar da Supabase" já é cumprido hoje pela própria interface `AuthRepository` (nenhum tipo do `supabase_flutter` cruza a fronteira de `data/` para cima); um `OAuthProvider`/`AuthSession` abaixo do `AuthRemoteDatasource` desacoplaria a camada cuja única responsabilidade é justamente depender do Supabase — redundante, não um ganho novo de desacoplamento.
- **Impacto de manutenção:** a 2 anos, ganho marginal sobre a Opção A (evita alterar a interface pública a cada provedor, mas ainda exige alterar o `switch` exaustivo do datasource — o custo não desaparece, só migra de lugar). A 5 anos, se a necessidade de "gerenciar múltiplos provedores por conta" se concretizar, esta opção compensa mais claramente — porém como refactor informado por implementações reais, não como aposta antecipada.

## 4. Decisão

**O BORAH adota a Opção A (métodos nomeados por provedor) para a sprint AUTH-01.** A interface `AuthRepository` recebe `signInWithGoogle()`, `signInWithApple()`, `signInWithFacebook()` e `signInAnonymously()` como métodos próprios, implementados nesta sprint apenas como stubs (`throw AuthRepositoryException('Login com <provedor> ainda não está disponível.')` em `AuthRemoteDatasource`), a serem conectados a cada SDK real em sprints futuras (AUTH-02+), sem necessidade de alterar a assinatura pública já exposta ao `AuthController`.

## 5. Motivo da escolha

1. A Opção B, aplicada de forma consistente, exigiria alterar a assinatura de login por e-mail já em uso pela UI e pelos testes — incompatível com a exigência desta sprint de preservar integralmente a arquitetura e não implementar/alterar UI.
2. O formato de credencial de cada provedor é desconhecido nesta sprint (SDKs nativos deliberadamente não incluídos ainda) — desenhar `AuthCredential` agora é decisão especulativa, sem dados reais para validar o desenho.
3. A Opção A não fecha a porta para a Opção B: o refactor de "N métodos nomeados" para "1 dispatcher com sealed class" é mecânico e de baixo risco em Dart, e fica mais barato de acertar quando informado por 3+ integrações reais já funcionando.
4. O objetivo original de "fluxo compartilhado entre todos os provedores" é atendido no lugar correto — um helper privado no `AuthController` (`_signInWithProvider`) reaproveitado pelos 4 métodos novos — sem exigir mudança na forma pública do `AuthRepository`.
5. Zero risco para os 503 testes existentes: os 9 arquivos que usam `MockAuthRepository` (via `mocktail`, `extends Mock implements AuthRepository`) absorvem métodos novos na interface automaticamente, sem qualquer edição.

## 6. Consequências

- `AuthRepository`, `AuthRepositoryImpl`, `AuthRemoteDatasource` e `AuthController` recebem 4 métodos novos cada, todos como extensão aditiva dos arquivos já existentes — nenhum arquivo/pasta novo, nenhuma dependência nova, nenhuma alteração de UI.
- Login social/anônimo permanece indisponível (lança `AuthRepositoryException`) até a sprint que conectar cada SDK — comportamento esperado e intencional desta etapa.
- Quando uma sprint futura conectar um SDK real (ex.: Google), o método correspondente provavelmente ganhará parâmetros (`idToken`, `accessToken`) — mudança aditiva na assinatura, não uma reestruturação.
- Este ADR não implica nenhuma migration, alteração de API pública do backend, ou mudança de comportamento visível ao usuário nesta sprint.

## 7. Critério objetivo para revisão futura

Esta decisão deve ser revisitada — migrando para a Opção B (dispatcher unificado com `sealed class`) — quando **qualquer** um dos gatilhos abaixo se concretizar, e não antes:

1. O BORAH precisar permitir **vincular mais de um provedor à mesma conta** (ex.: usuário logado por e-mail quer também habilitar login via Google).
2. Surgir a necessidade de **listar/gerenciar provedores vinculados** a uma conta de forma genérica (ex.: tela "Métodos de login" nas configurações).
3. O número de provedores nomeados no `AuthRepository` ultrapassar **~6-8 métodos de sign-in**, tornando a interface visivelmente repetitiva mesmo com o helper compartilhado do Controller.

Até que um desses critérios se concretize, a Opção A permanece a decisão vigente.

## 8. Referências

- `app/lib/features/authentication/domain/auth_repository.dart`
- `app/lib/features/authentication/data/auth_repository_impl.dart`, `auth_remote_datasource.dart`
- `app/lib/features/authentication/application/auth_controller.dart`
- `app/lib/core/router/app_router.dart` (proteção de rotas, não alterada por esta decisão)
- `docs/FASE 9 - Execution/EX-08_KNOWLEDGE_BASE_AND_ADR.md` (modelo/processo de ADR)
- `docs/knowledge-base/adr/ADR-0001-backend-architecture-supabase.md` (ADR anterior, mesmo processo)
