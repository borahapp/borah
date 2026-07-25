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
}
