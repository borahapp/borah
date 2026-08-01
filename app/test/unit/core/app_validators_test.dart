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
}
