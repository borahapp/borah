import 'dart:typed_data';

import 'package:app/core/storage/storage_magic_bytes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchesImageSignature - jpg/jpeg', () {
    test('aceita bytes começando com FF D8 FF', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00, 0x00]);

      expect(matchesImageSignature(bytes, 'jpg'), isTrue);
      expect(matchesImageSignature(bytes, 'jpeg'), isTrue);
    });

    test('rejeita bytes que não começam com a assinatura JPEG', () {
      final bytes = Uint8List.fromList([0x00, 0x00, 0x00, 0x00, 0x00]);

      expect(matchesImageSignature(bytes, 'jpg'), isFalse);
    });

    test('rejeita quando há menos de 3 bytes', () {
      expect(
        matchesImageSignature(Uint8List.fromList([0xFF, 0xD8]), 'jpg'),
        isFalse,
      );
    });
  });

  group('matchesImageSignature - png', () {
    test('aceita a assinatura PNG completa de 8 bytes', () {
      final bytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
      ]);

      expect(matchesImageSignature(bytes, 'png'), isTrue);
    });

    test('rejeita uma assinatura PNG incompleta/incorreta', () {
      final bytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x00,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);

      expect(matchesImageSignature(bytes, 'png'), isFalse);
    });

    test('rejeita quando há menos de 8 bytes', () {
      expect(
        matchesImageSignature(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
          'png',
        ),
        isFalse,
      );
    });
  });

  group('matchesImageSignature - webp', () {
    test('aceita o formato RIFF....WEBP', () {
      final bytes = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x50,
      ]);

      expect(matchesImageSignature(bytes, 'webp'), isTrue);
    });

    test('rejeita quando falta o marcador WEBP após o RIFF', () {
      final bytes = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);

      expect(matchesImageSignature(bytes, 'webp'), isFalse);
    });

    test('rejeita quando há menos de 12 bytes', () {
      expect(
        matchesImageSignature(
          Uint8List.fromList([0x52, 0x49, 0x46, 0x46]),
          'webp',
        ),
        isFalse,
      );
    });
  });

  test('rejeita extensão desconhecida (nenhuma assinatura mapeada)', () {
    final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00, 0x00]);

    expect(matchesImageSignature(bytes, 'gif'), isFalse);
  });
}
