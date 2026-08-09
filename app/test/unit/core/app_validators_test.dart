import 'package:app/core/validators/app_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseRating', () {
    test('aceita ponto como separador decimal', () {
      expect(parseRating('4.5'), 4.5);
    });

    test('aceita vírgula como separador decimal (teclado numérico pt-BR)', () {
      expect(parseRating('4,5'), 4.5);
    });

    test('valor inválido retorna null', () {
      expect(parseRating('abc'), isNull);
    });

    test('nulo retorna null', () {
      expect(parseRating(null), isNull);
    });
  });

  group('validateRating', () {
    test('nota com vírgula dentro do intervalo é aceita', () {
      expect(validateRating('4,5'), isNull);
    });

    test('nota com ponto dentro do intervalo é aceita', () {
      expect(validateRating('4.5'), isNull);
    });

    test('nota fora do intervalo é rejeitada', () {
      expect(validateRating('5,5'), isNotNull);
    });

    test('valor não numérico é rejeitado', () {
      expect(validateRating('abc'), isNotNull);
    });
  });

  group('validateUsername', () {
    test('nulo é válido (username é opcional)', () {
      expect(validateUsername(null), isNull);
    });

    test('vazio é válido (username é opcional)', () {
      expect(validateUsername(''), isNull);
      expect(validateUsername('   '), isNull);
    });

    test('username válido (letras, números, ponto, underscore)', () {
      expect(validateUsername('victor_frare.2'), isNull);
    });

    test('menor que 3 caracteres é rejeitado', () {
      expect(validateUsername('ab'), isNotNull);
    });

    test('maior que 30 caracteres é rejeitado', () {
      expect(validateUsername('a' * 31), isNotNull);
    });

    test('caractere inválido é rejeitado', () {
      expect(validateUsername('victor frare'), isNotNull);
      expect(validateUsername('victor@frare'), isNotNull);
      expect(validateUsername('victor-frare'), isNotNull);
    });
  });
}
