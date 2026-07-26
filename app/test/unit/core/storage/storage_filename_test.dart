import 'package:app/core/storage/storage_filename.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeExtension', () {
    test('extrai a extensão em minúsculas', () {
      expect(normalizeExtension('Foto.JPG'), 'jpg');
      expect(normalizeExtension('avatar.png'), 'png');
    });

    test('ignora query string', () {
      expect(normalizeExtension('foto.jpg?token=abc'), 'jpg');
    });

    test('usa apenas o último segmento após o último ponto', () {
      expect(normalizeExtension('meu.arquivo.final.webp'), 'webp');
    });

    test('retorna vazio quando não há extensão', () {
      expect(normalizeExtension('semextensao'), '');
    });
  });

  group('generateStorageFileName', () {
    test('nunca reaproveita nenhuma parte do nome original', () {
      final name = generateStorageFileName('jpg');

      expect(name, endsWith('.jpg'));
      expect(name, isNot(contains('..')));
      expect(name, isNot(contains('/')));
    });

    test('duas chamadas consecutivas geram nomes diferentes', () {
      final first = generateStorageFileName('png');
      final second = generateStorageFileName('png');

      expect(first, isNot(second));
    });

    test('formato é <timestamp>-<sufixo hex>.<extensão>', () {
      final name = generateStorageFileName('webp');
      final match = RegExp(r'^\d+-[0-9a-f]{8}\.webp$').hasMatch(name);

      expect(match, isTrue, reason: 'nome gerado: $name');
    });
  });
}
