/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define` (or `--dart-define-from-file`)
/// at build/run time. The `.env.*` files in the repository root document
/// the expected variables (AR-03) but are not read directly by Dart code.
abstract final class AppEnvironment {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
