
# AR-08 — Storage Architecture

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-08_STORAGE_ARCHITECTURE.md

---

# 1. Objetivo

Definir a arquitetura de armazenamento de arquivos do BORAH utilizando o Supabase Storage, estabelecendo padrões para organização, segurança, nomenclatura, acesso e ciclo de vida dos arquivos.

---

# 2. Objetivos

- Organização padronizada
- Segurança por bucket
- Escalabilidade
- Facilidade de manutenção
- Alta disponibilidade
- Performance no carregamento de arquivos

---

# 3. Tecnologia

- Supabase Storage
- CDN do Supabase
- PostgreSQL (metadados)
- Flutter Image Cache

---

# 4. Estrutura de Buckets

```text
storage/
├── avatars/
├── restaurants/
├── groups/
├── events/
├── feed/
├── badges/
├── covers/
├── temp/
└── backups/
```

Cada bucket deverá possuir políticas independentes.

---

# 5. Finalidade dos Buckets

| Bucket | Uso |
|---------|-----|
| avatars | Fotos de perfil |
| restaurants | Imagens dos restaurantes |
| groups | Imagens dos grupos |
| events | Imagens dos eventos |
| feed | Publicações |
| badges | Medalhas e conquistas |
| covers | Capas e banners |
| temp | Uploads temporários |
| backups | Arquivos administrativos |

---

# 6. Convenção de Nomes

Padrão:

```text
<tipo>/<uuid>/<arquivo>
```

Exemplos:

```text
avatars/8d34ab12/profile.jpg
events/ab91fe22/event_cover.webp
feed/f8192da1/post_image.png
```

Evitar nomes genéricos como:

- foto.png
- imagem.jpg
- novo.webp

---

# 7. Formatos Suportados

Imagens:

- JPG
- JPEG
- PNG
- WEBP

Futuro:

- MP4
- PDF

---

# 8. Limites

Sugestão inicial:

| Bucket | Limite |
|---------|---------|
| avatars | 5 MB |
| restaurants | 10 MB |
| groups | 10 MB |
| events | 10 MB |
| feed | 15 MB |
| temp | 20 MB |

---

# 9. Políticas de Acesso

Buckets públicos:

- restaurants
- badges

Buckets privados:

- avatars
- groups
- events
- feed
- temp
- backups

O acesso deverá ser controlado por RLS e URLs assinadas quando necessário.

---

# 10. Upload

Fluxo:

```text
Flutter
   ↓
Validação
   ↓
Compressão
   ↓
Upload
   ↓
Storage
   ↓
Registro no Banco
```

---

# 11. Download

Utilizar:

- Cache local
- URLs assinadas quando necessário
- Lazy Loading
- Placeholder durante carregamento

---

# 12. Compressão

Antes do upload:

- Redimensionar imagens
- Remover metadados desnecessários
- Preferir WEBP quando suportado

---

# 13. Exclusão

Tipos:

- Exclusão lógica (registro)
- Exclusão física (arquivo)

Arquivos órfãos deverão ser removidos periodicamente.

---

# 14. Segurança

Implementar:

- Limite de tamanho
- Validação de MIME Type
- Validação de extensão
- Buckets privados por padrão
- URLs temporárias para acesso privado

---

# 15. Performance

Boas práticas:

- Cache de imagens
- Lazy Loading
- Compressão
- CDN
- Evitar downloads repetidos

---

# 16. Monitoramento

Acompanhar:

- Espaço utilizado
- Número de uploads
- Falhas de upload
- Downloads
- Arquivos órfãos

---

# 17. Boas Práticas

- Utilizar UUID nas pastas.
- Não reutilizar nomes de arquivos.
- Organizar por bucket.
- Aplicar políticas específicas.
- Remover arquivos temporários.

---

# 18. Anti-patterns

Evitar:

- Buckets públicos sem necessidade
- Arquivos gigantes
- Upload sem validação
- Links permanentes para arquivos privados
- Armazenar dados sensíveis sem proteção

---

# 19. Critérios de Aceite

- Buckets definidos
- Políticas documentadas
- Convenções estabelecidas
- Estratégia de segurança prevista
- Fluxo de upload definido

---

# 20. Checklist

- Buckets organizados
- Limites definidos
- Políticas de acesso documentadas
- Convenções registradas
- Fluxo de upload definido
- Compressão prevista
- Estratégia de exclusão definida
- Monitoramento planejado
