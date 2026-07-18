import 'dart:developer' as developer;

/// Thin wrapper around `dart:developer` so call sites never depend on a
/// concrete logging package (nenhuma dependência extra além do escopo do AR-02).
abstract final class AppLogger {
  static void debug(String message) =>
      developer.log(message, name: 'BORAH', level: 500);

  static void info(String message) =>
      developer.log(message, name: 'BORAH', level: 800);

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      developer.log(
        message,
        name: 'BORAH',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
}
