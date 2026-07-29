import 'package:app/core/environment/app_environment.dart';

import 'qa_restaurant_helper.dart';
import 'qa_social_helper.dart';
import 'test_user_helper.dart';

/// Configuração compartilhada dos Integration Tests que precisam criar
/// ou remover dados via Admin API/PostgREST (Rodada B em diante).
///
/// A `SUPABASE_QA_SERVICE_ROLE_KEY` nunca é hardcoded - é sempre lida em
/// tempo de execução via `--dart-define`, nunca gravada em `.env.qa` nem
/// em qualquer arquivo versionado.
abstract final class QaTestConfig {
  static const _serviceRoleKey = String.fromEnvironment(
    'SUPABASE_QA_SERVICE_ROLE_KEY',
  );

  static void _assertServiceRoleKeyProvided() {
    if (_serviceRoleKey.isEmpty) {
      throw StateError(
        'SUPABASE_QA_SERVICE_ROLE_KEY não foi informada. Rode com '
        '--dart-define=SUPABASE_QA_SERVICE_ROLE_KEY=`<chave>`, além de '
        '--dart-define-from-file=.env.qa (ver EX-10 §7, Rodada B).',
      );
    }
  }

  static QaTestUserHelper buildUserHelper() {
    _assertServiceRoleKeyProvided();
    return QaTestUserHelper(
      supabaseUrl: AppEnvironment.supabaseUrl,
      serviceRoleKey: _serviceRoleKey,
    );
  }

  static QaRestaurantHelper buildRestaurantHelper() {
    _assertServiceRoleKeyProvided();
    return QaRestaurantHelper(
      supabaseUrl: AppEnvironment.supabaseUrl,
      serviceRoleKey: _serviceRoleKey,
    );
  }

  static QaSocialHelper buildSocialHelper() {
    _assertServiceRoleKeyProvided();
    return QaSocialHelper(
      supabaseUrl: AppEnvironment.supabaseUrl,
      serviceRoleKey: _serviceRoleKey,
    );
  }
}
