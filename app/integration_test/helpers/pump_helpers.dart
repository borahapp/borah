import 'package:flutter_test/flutter_test.dart';

/// Aguarda `condition` ficar verdadeira usando pumps limitados, em vez de
/// `pumpAndSettle` - várias telas deste app mostram um
/// `CircularProgressIndicator` indeterminado (animação infinita) enquanto
/// aguardam uma chamada de rede real ao Supabase, o que faria
/// `pumpAndSettle` nunca retornar (mesmo motivo documentado em
/// `app_smoke_test.dart`, Rodada A).
///
/// Lança [StateError] se `condition` nunca se tornar verdadeira dentro de
/// `maxAttempts` - sem isso, um timeout silencioso mascara a causa real
/// (ex.: um erro de rede real que impede a navegação esperada) atrás de
/// uma falha de asserção genérica e confusa no passo seguinte do teste.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration step = const Duration(milliseconds: 200),
  int maxAttempts = 50,
  String? timeoutMessage,
}) async {
  var attempts = 0;
  while (!condition() && attempts < maxAttempts) {
    await tester.pump(step);
    attempts++;
  }
  if (!condition()) {
    throw StateError(
      timeoutMessage ??
          'pumpUntil: condição não satisfeita após '
              '${maxAttempts * step.inMilliseconds}ms.',
    );
  }
}
