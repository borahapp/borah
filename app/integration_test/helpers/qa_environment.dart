import 'package:app/core/environment/app_environment.dart';

/// Guard-rail dos Integration Tests (QA-03): garante que a suíte só rode
/// contra o projeto Supabase QA/Test dedicado (`borah-qa`), nunca contra
/// Development ou Production por engano.
///
/// O ref do projeto QA é fixo e conhecido (criado na Rodada 0 - EX-10
/// §7). Se o `SUPABASE_URL` fornecido via `--dart-define-from-file`
/// não apontar para ele, a suíte aborta antes de tocar em qualquer
/// dado real.
abstract final class QaEnvironment {
  static const qaProjectRef = 'fgzokfkvccgkclkmfqui';

  static void assertRunningAgainstQaProject() {
    final url = AppEnvironment.supabaseUrl;
    if (!url.contains(qaProjectRef)) {
      throw StateError(
        'Integration Tests devem rodar apenas contra o ambiente QA/Test '
        '(borah-qa, ref $qaProjectRef). SUPABASE_URL atual: "$url". '
        'Rode com --dart-define-from-file=.env.qa (ver EX-10 §7).',
      );
    }
  }
}
