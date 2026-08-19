/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define` (or `--dart-define-from-file`)
/// at build/run time. The `.env.*` files in the repository root document
/// the expected variables (AR-03) but are not read directly by Dart code.
abstract final class AppEnvironment {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// DSN do Sentry (RC-03A). Vazio por padrão - o pacote `sentry` não
  /// envia nenhum evento quando o DSN está vazio (comportamento nativo,
  /// documentado em `SentryOptions.dsn`), então rodar sem `--dart-define`
  /// (ex.: `flutter run` local sem configuração) fica silencioso por
  /// padrão, sem nenhum gate extra necessário no código.
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Nome do ambiente atual (RC-03A): `development` | `qa` | `beta` |
  /// `production`. Marca todo evento reportado ao Sentry, permitindo
  /// filtrar por ambiente no dashboard. Default `development` - o valor
  /// mais seguro quando o app roda sem nenhum `--dart-define`.
  static const environmentName = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Project token do PostHog (RC-03C). Vazio por padrão - `Posthog()
  /// .setup()` já no-opa graciosamente quando o token está vazio (mesmo
  /// espírito do `SENTRY_DSN` vazio acima).
  static const postHogApiKey = String.fromEnvironment('POSTHOG_API_KEY');

  /// Host de ingestão do PostHog (RC-03C). Default aponta para a nuvem
  /// pública US do PostHog — trocar via `--dart-define` para uma instância
  /// self-hosted ou região EU, quando aplicável.
  static const postHogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );

  /// AUTH-02: Client ID "Web" do Google Cloud Console — é o que o
  /// Supabase usa para validar o `idToken` (audience do token). Vazio
  /// por padrão - `AuthRemoteDatasource.signInWithGoogle()` recusa o
  /// login com uma mensagem clara em vez de tentar inicializar o SDK
  /// sem credencial (mesmo espírito do `sentryDsn` vazio acima).
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// AUTH-02: Client ID "iOS" do Google Cloud Console. Necessário apenas
  /// na plataforma iOS (o Android resolve via SHA-1 do keystore, sem
  /// precisar deste valor) - vazio por padrão nas demais plataformas.
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// F12 - chave da Google Places API (New), restrita no Google Cloud a
  /// `com.borah.app` + SHA-1 (Android). Vazio por padrão - mesmo espírito
  /// de `sentryDsn`/`googleServerClientId`: `GooglePlacesRemoteDatasource`
  /// recusa a busca com uma mensagem clara em vez de chamar a API sem
  /// credencial. Nunca logada, nunca hardcoded, nunca commitada.
  static const googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
  );
}
