import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Resultado de uma seleção de imagem já validada.
class PickedImage {
  const PickedImage({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// Erro de validação client-side (tamanho/formato) — não é uma exceção de
/// infraestrutura, apenas feedback para a UI.
class ImageValidationException implements Exception {
  const ImageValidationException(this.message);

  final String message;
}

/// Seleção e validação de imagens compartilhada entre módulos (extraído
/// do DV-02 quando o DV-03 passou a precisar do mesmo fluxo, com limites
/// de tamanho/formato diferentes por caso de uso).
class ImagePickerService {
  Future<PickedImage?> pickAndValidate({
    required int maxBytes,
    required Set<String> allowedExtensions,
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > maxBytes) {
      final maxMb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      throw ImageValidationException('A imagem deve ter no máximo $maxMb MB.');
    }

    final extension = file.name.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw ImageValidationException(
        'Formato não suportado. Use ${allowedExtensions.join(', ').toUpperCase()}.',
      );
    }

    return PickedImage(bytes: bytes, extension: extension);
  }
}
