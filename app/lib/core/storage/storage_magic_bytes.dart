import 'dart:typed_data';

/// Confirma que os primeiros bytes do arquivo correspondem à assinatura
/// binária ("magic bytes") esperada para [extension] — não confia
/// apenas no `contentType`/extensão declarados pelo chamador (RC-04B1 —
/// achado da auditoria técnica da RC-04B, confirmado por investigação:
/// o próprio Supabase Storage também só valida o Content-Type
/// declarado pelo cliente, nunca os bytes reais do arquivo — ver
/// RC-04B_STORAGE_SECURITY.md §RC-04B1 Hardening para as fontes).
///
/// Cobre só os 3 formatos hoje permitidos por `StorageUploadConfig`
/// (jpg/jpeg/png/webp) — suficiente para o allowlist atual, sem
/// precisar de nenhuma dependência nova (as assinaturas são públicas,
/// estáveis e fazem parte da própria especificação de cada formato).
///
/// Fecha a lacuna para o caminho legítimo do app (bytes reais
/// divergentes do que o `image_picker` declarou), mas não substitui
/// nenhuma garantia de servidor — um cliente que chame a API do
/// Supabase diretamente, contornando o app, não passa por esta função.
bool matchesImageSignature(Uint8List bytes, String extension) {
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return bytes.length >= 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF;
    case 'png':
      return bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A;
    case 'webp':
      return bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50;
    default:
      return false;
  }
}
