import 'package:app/core/deep_link/deep_link.dart';
import 'package:app/core/deep_link/deep_link_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkParser.parse', () {
    test('borah://group/join?code=X vira GroupJoinDeepLink', () {
      final result = DeepLinkParser.parse(
        Uri.parse('borah://group/join?code=ABCD1234'),
      );

      expect(result, isA<GroupJoinDeepLink>());
      expect((result as GroupJoinDeepLink).inviteCode, 'ABCD1234');
    });

    test('esquema diferente de borah vira UnknownDeepLink', () {
      final uri = Uri.parse('https://group/join?code=ABCD1234');
      final result = DeepLinkParser.parse(uri);

      expect(result, isA<UnknownDeepLink>());
      expect((result as UnknownDeepLink).uri, uri);
    });

    test('domínio desconhecido vira UnknownDeepLink', () {
      final result = DeepLinkParser.parse(
        Uri.parse('borah://restaurant/join?code=ABCD1234'),
      );

      expect(result, isA<UnknownDeepLink>());
    });

    test(
      'ação desconhecida dentro de um domínio válido vira UnknownDeepLink',
      () {
        final result = DeepLinkParser.parse(
          Uri.parse('borah://group/leave?code=ABCD1234'),
        );

        expect(result, isA<UnknownDeepLink>());
      },
    );

    test('group/join sem code vira UnknownDeepLink, nunca lança', () {
      final result = DeepLinkParser.parse(Uri.parse('borah://group/join'));

      expect(result, isA<UnknownDeepLink>());
    });

    test('group/join com code vazio vira UnknownDeepLink', () {
      final result = DeepLinkParser.parse(
        Uri.parse('borah://group/join?code='),
      );

      expect(result, isA<UnknownDeepLink>());
    });

    test(
      'UnknownDeepLink preserva a Uri original intacta, para diagnóstico',
      () {
        final uri = Uri.parse('borah://something/unexpected?a=1&b=2');
        final result = DeepLinkParser.parse(uri) as UnknownDeepLink;

        expect(result.uri, uri);
        expect(result.uri.toString(), 'borah://something/unexpected?a=1&b=2');
      },
    );

    test('nunca lança, mesmo para uma Uri vazia/sem estrutura', () {
      expect(() => DeepLinkParser.parse(Uri()), returnsNormally);
      expect(DeepLinkParser.parse(Uri()), isA<UnknownDeepLink>());
    });

    test('é determinístico - mesma Uri produz o mesmo resultado sempre', () {
      final uri = Uri.parse('borah://group/join?code=XYZ');
      final first = DeepLinkParser.parse(uri);
      final second = DeepLinkParser.parse(uri);

      expect(first, isA<GroupJoinDeepLink>());
      expect(second, isA<GroupJoinDeepLink>());
      expect(
        (first as GroupJoinDeepLink).inviteCode,
        (second as GroupJoinDeepLink).inviteCode,
      );
    });
  });
}
