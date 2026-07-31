# AUTH-02 — Configuração externa para o Login com Google

**Sprint:** AUTH-02
**Data:** 2026-07-30
**Escopo:** notas técnicas de configuração externa (Google Cloud Console + Supabase) e decisões de implementação tomadas ao conectar `AuthRemoteDatasource.signInWithGoogle()` (infraestrutura preparada no AUTH-01, ver `ADR-0002`).

Todas as versões/APIs citadas abaixo foram verificadas em `pub.dev` no momento da implementação (`pub.dev` está acessível a partir do ambiente de desenvolvimento assistido; `supabase.com` não está) — não são suposições de conhecimento de treinamento.

## 1. Pacote usado e por que a versão importa

`google_sign_in: ^7.2.0` (versão estável mais recente em pub.dev nesta data). A partir da **7.0.0** o pacote teve uma mudança de API incompatível com versões anteriores:

- `GoogleSignIn` passou a ser um singleton (`GoogleSignIn.instance`).
- É obrigatório chamar `initialize()` uma única vez por execução do app antes de qualquer outro método.
- Autenticação (obter identidade/`idToken`) e autorização (obter `accessToken`/escopos) são etapas separadas — não existe mais um único `signIn()` que devolve tudo de uma vez.

Qualquer exemplo de código baseado em `GoogleSignIn(clientId: ...).signIn()` (API pré-7.0.0) não compila contra a versão instalada.

## 2. Fluxo implementado

```
Botão "Continuar com Google" (UI — fora do escopo desta sprint)
        ↓
AuthController.signInWithGoogle()          (AUTH-01, sem alteração)
        ↓
AuthRepository.signInWithGoogle()          (AUTH-01, sem alteração)
        ↓
AuthRepositoryImpl.signInWithGoogle()      (AUTH-01, sem alteração — _guard())
        ↓
AuthRemoteDatasource.signInWithGoogle()    (AUTH-02 — implementado agora)
    1. GoogleSignIn.instance.initialize(clientId, serverClientId)  — uma vez, em cache
    2. GoogleSignIn.instance.authenticate()  → GoogleSignInAccount
    3. account.authentication.idToken
    4. Supabase: auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)
        ↓
Sessão Supabase criada → AuthController já reage via onAuthStateChange (AUTH-01, sem alteração)
```

Nenhuma camada acima do datasource precisou mudar — é exatamente o resultado que o `ADR-0002` previu ao escolher métodos nomeados em vez de um dispatcher genérico.

## 3. Checklist de configuração externa (Google Cloud Console)

1. **OAuth Consent Screen** — configurar nome do app, e-mail de suporte; enquanto em modo "Testing", cadastrar e-mails de teste.
2. **Web Client ID** — usado como `GOOGLE_SERVER_CLIENT_ID` (`--dart-define`). É o que o Supabase usa para validar a audiência do `idToken`.
3. **Android Client ID** — exige o **SHA-1 do certificado de assinatura**. Não existe keystore de release no repositório (`app/android/` — confirmado, nenhum `.jks`/`key.properties`); use o SHA-1 do keystore de **debug** para desenvolvimento/teste. O Client ID de produção só pode ser finalizado depois que a keystore de release existir (ver `docs/launch/google_play_checklist.md`).
4. **iOS Client ID** — Bundle ID `com.borah.app`. Usado como `GOOGLE_IOS_CLIENT_ID` (`--dart-define`) **e** como base do `CFBundleURLSchemes` em `Info.plist` (ver seção 5).

## 4. Checklist de configuração externa (Supabase)

- Authentication → Providers → Google: habilitar, informar o **Web Client ID** + **Client Secret**.
- **Nenhum Redirect URL novo é necessário.** O fluxo usado (`signInWithIdToken`, nativo) não abre navegador nem depende de deep link — diferente do `borah://password-recovery` (que é de um fluxo `signInWithOAuth` distinto e não foi alterado).

## 5. O que foi alterado no app (e por quê)

| Arquivo | Mudança |
|---|---|
| `app/pubspec.yaml` | `+google_sign_in: ^7.2.0` |
| `app/lib/core/environment/app_environment.dart` | `+googleServerClientId`, `+googleIosClientId` (`String.fromEnvironment`, vazio por padrão — mesmo padrão de `sentryDsn`/`postHogApiKey`) |
| `app/lib/features/authentication/data/auth_remote_datasource.dart` | `signInWithGoogle()` deixa de ser stub; implementação real descrita na seção 2 |
| `app/ios/Runner/Info.plist` | Novo item em `CFBundleURLTypes` com placeholder `com.googleusercontent.apps.PENDENTE-GOOGLE-IOS-CLIENT-ID` — **obrigatório mesmo configurando `clientId`/`serverClientId` via código Dart** (confirmado na documentação oficial do `google_sign_in_ios`, "step 6 is still required"); substituir pelo `REVERSED_CLIENT_ID` real quando o Client ID iOS existir |
| `app/android/**` | **Nenhuma alteração.** Confirmado via `google_sign_in_android`: sem `google-services.json`, basta passar `serverClientId` programaticamente (já feito). Sem mudança de Manifest — o fluxo usa o Android Credential Manager via Google Play Services, não um redirect por scheme customizado. |
| `AuthRepository`, `AuthRepositoryImpl`, `AuthController`, `AuthStatus`, router | **Nenhuma alteração** — infraestrutura do AUTH-01 absorveu a implementação sem mudança de contrato. |

## 6. Pendências / itens não confirmados

- **`minSdkVersion` do Android**: não foi possível confirmar com certeza, a partir da documentação consultada, o mínimo exigido pelo `google_sign_in_android` 7.x (usa Android Credential Manager, que historicamente exige uma API level mínima maior que o `flutter.minSdkVersion` padrão herdado hoje). Fica como verificação obrigatória no primeiro `flutter pub get`/build real — o Gradle reporta um erro de manifest merger claro se o mínimo não for atendido; não é uma falha silenciosa.
- **Nonce do `signInWithIdToken`**: a assinatura aceita `nonce` opcional (usado quando o `idToken` contém um claim `nonce` a validar). O fluxo padrão do Google via `google_sign_in` não define um nonce por padrão nesta implementação — se a validação do Supabase exigir, é um ajuste pontual no mesmo método.
- **Sem UI**: não há botão/tela chamando `signInWithGoogle()` ainda (fora do escopo desta sprint, conforme o fluxo definido não incluir a camada de apresentação).
- **Execução real**: não foi possível rodar `flutter pub get`/`flutter analyze`/`flutter test`/build real neste ambiente (sem Flutter/Dart SDK instalado) — revisão foi manual, linha a linha, mais validação de XML bem-formado (`Info.plist`) e YAML válido (`pubspec.yaml`). Recomenda-se rodar a suíte completa antes de qualquer merge.
