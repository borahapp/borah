/// Deep Link do BORAH, já interpretado - nunca uma `Uri` crua.
///
/// **Regra arquitetural permanente**: todo Deep Link representa
/// exatamente **domínio + ação + payload**, nunca mais que isso e nunca
/// uma pilha de navegação:
/// - **Domínio**: a raiz de agregação (`group`, `auth`, `event`,
///   `profile`, `ranking`...) - corresponde ao subtipo de [DeepLink].
/// - **Ação**: o que fazer dentro do domínio (`join`, `detail`,
///   `view`...) - parte do nome do subtipo.
/// - **Payload**: os dados mínimos necessários para executar a ação
///   (`inviteCode`, `id`...) - os campos do próprio subtipo.
///
/// Válido: `group/join?code=X`, `event/detail?id=X`,
/// `profile/view?userId=X`, `ranking/group?groupId=X`.
/// **Nunca válido**: qualquer coisa que codifique mais de uma tela ou
/// uma sequência (`group/X/event/Y/review`, por exemplo) - um Deep
/// Link aponta para **um** destino; o destino decide sozinho o que
/// mostrar, nunca a navegação inteira serializada numa URL. Se uma
/// ideia futura de Deep Link parecer exigir isso, é sinal de que
/// deveria ser 2 Deep Links, não 1.
sealed class DeepLink {
  const DeepLink();
}

/// Domínio `group`, ação `join` - `borah://group/join?code=XXXX`.
final class GroupJoinDeepLink extends DeepLink {
  const GroupJoinDeepLink({required this.inviteCode});

  final String inviteCode;
}

/// Qualquer `Uri` que [DeepLinkParser] não reconhece - nunca `null`,
/// nunca uma exceção (ver contrato em `deep_link_parser.dart`).
/// Preserva a `Uri` original para diagnóstico (log), nunca para decidir
/// nenhum comportamento por conta própria.
///
/// **Comportamento oficial**: um `UnknownDeepLink` nunca deve navegar,
/// alterar estado, abrir diálogo ou mostrar snackbar. A única ação
/// permitida é registrá-lo via `AppLogger.warning` e descartá-lo em
/// silêncio - responsabilidade do [DeepLinkDispatcher], não de cada
/// `DeepLinkReceiver` (ver `deep_link_dispatcher.dart`).
final class UnknownDeepLink extends DeepLink {
  const UnknownDeepLink({required this.uri});

  final Uri uri;
}
