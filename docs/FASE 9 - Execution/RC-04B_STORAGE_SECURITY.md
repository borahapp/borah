# RC-04B — Storage & Upload Security

**Data:** 2026-07-25
**Branch:** `feature/rc-04b-storage-security`
**Status:** Implementado — infraestrutura completa e testada; nenhuma tela consome a nova camada nesta rodada (ver §9)
**Escopo:** exclusivamente a infraestrutura de armazenamento seguro do BORAH via Supabase Storage. LGPD, Exclusão de Conta, Política de Privacidade, Termos de Uso, Publicação e funcionalidades de Beta são itens separados do backlog (RC-04C/D/E) e não foram tocados nesta rodada.

---

## 1. Objetivo

Dar ao BORAH uma camada de acesso ao Supabase Storage desacoplada e segura — mesmo padrão arquitetural de `CrashReporting`/`AppLogger`/`AppAnalytics`/`AppFeatureFlags`/`AppFeedback` (RC-03A-E) e da disciplina de auditoria da RC-04A: nenhuma feature acessa o SDK de Storage diretamente, toda autorização é garantida pelo Supabase (RLS), e nenhuma tela é conectada nesta rodada — só infraestrutura.

---

## 2. Achado arquitetural registrado no início da rodada

Antes de escrever qualquer código novo, a exploração do repositório revelou que **3 datasources de feature já acessam o Supabase Storage diretamente**: `UserRemoteDatasource.uploadAvatar`/`createSignedAvatarUrl` (bucket `avatars`), `RestaurantRemoteDatasource.uploadCoverImage`/`getPublicCoverImageUrl` (bucket `restaurants`) e `ReviewRemoteDatasource.uploadPhoto`/`listPhotoUrls` (bucket `review-photos`) — exatamente o padrão que esta rodada existe para eliminar. Como a instrução desta rodada também é explícita ("não implementar upload em telas específicas nesta etapa"), esses três arquivos **permanecem intocados** — a nova infraestrutura em `lib/core/storage/` é construída em paralelo, sem migrar nenhuma tela existente. Migrar essas três telas para `AppStorage` fica registrado como trabalho futuro (ver §11).

**Decisão de nomenclatura registrada explicitamente pelo usuário**: o bucket de fotos de avaliação desta rodada é `review-photos` (não o nome genérico `reviews` inicialmente sugerido) — escolhido para casar imediatamente com o nome já usado pelo código existente em `ReviewRemoteDatasource`, evitando fragmentar o domínio em dois nomes de bucket diferentes quando as telas forem migradas numa rodada futura. Qualquer referência anterior a um bucket `reviews` deve ser considerada substituída por este nome.

---

## 3. Arquitetura

```
lib/core/storage/
├── storage_exception.dart        # StorageException — única exceção da camada
├── storage_repository.dart       # interface StorageRepository (agnóstica de bucket)
├── supabase_storage_service.dart # SupabaseStorageService — única classe que toca o SDK
├── storage_filename.dart         # normalizeExtension()/generateStorageFileName() — puras, testáveis isoladamente
├── storage_upload_config.dart    # StorageUploadConfig — regras de validação + presets (avatar/restaurantCover/reviewPhoto)
├── storage_service.dart          # StorageService — orquestra validação + geração de nome + repositório
├── storage_providers.dart        # Providers Riverpod (storageRepositoryProvider/storageServiceProvider)
└── app_storage.dart              # fachada estática AppStorage (API pública)
```

```
Feature (futura, ainda não conectada nesta rodada)
    ↓ chama
AppStorage.upload(...)                      ← API pública estática
    ou
ref.read(storageServiceProvider)            ← API pública reativa (Riverpod)
    ↓ delega para
StorageService                               ← valida (tamanho/MIME/extensão), gera o nome, nunca lança direto ao Supabase
    ↓ usa
StorageRepository (interface)
    ↓ implementado por
SupabaseStorageService                       ← única fronteira com o SDK do Supabase Storage
```

### 3.1 Nomenclatura dos componentes

Os nomes de classe seguem exatamente a especificação desta rodada, incluindo uma aparente inversão em relação à convenção RC-03 (`SupabaseFeedbackRepository implements FeedbackRepository`): aqui, `SupabaseStorageService implements StorageRepository` — a implementação concreta é a "Service", a interface é a "Repository". `StorageService` (a camada de orquestração) é uma classe **diferente** de `SupabaseStorageService` (a implementação concreta da interface) — apesar do nome parecido, não devem ser confundidas: `StorageService` nunca importa o SDK do Supabase, só conhece `StorageRepository`.

### 3.2 Agnóstico de bucket

`StorageRepository`/`StorageService`/`AppStorage` recebem `bucket` como parâmetro em todo método — nenhuma classe é específica de um bucket. Adicionar um bucket novo no futuro ("permitir expansão futura", ver §4) não exige nenhuma classe nova, só uma migration com o bucket e suas policies.

---

## 4. Buckets

Migration `supabase/migrations/20260725120000_create_storage_buckets.sql` cria os 3 buckets efetivamente usados pelo código de feature já existente:

| Bucket | Público | Limite | MIME permitidos | Convenção de caminho |
|---|---|---|---|---|
| `avatars` | Não | 5 MB | image/jpeg, image/png, image/webp | `<userId>/avatar.<ext>` |
| `restaurants` | Sim | 10 MB | image/jpeg, image/png, image/webp | `<restaurantId>/cover.<ext>` |
| `review-photos` | Sim | 10 MB | image/jpeg, image/png, image/webp | `<reviewId>/<nome gerado>.<ext>` |

O `AR-08_STORAGE_ARCHITECTURE.md` original (Fase 4) descrevia uma lista aspiracional de 9 buckets (`avatars`/`restaurants`/`groups`/`events`/`feed`/`badges`/`covers`/`temp`/`backups`) — só estes 3 têm código de feature correspondente hoje; os demais ficam para quando houver um consumidor real, sem antecipar funcionalidade (Beta/RC-04E fora de escopo).

### 4.1 Validação em duas camadas redundantes

O limite de tamanho e os tipos MIME são aplicados **duas vezes, de propósito**: uma vez no próprio bucket (`file_size_limit`/`allowed_mime_types`, checado pelo Supabase Storage antes de qualquer policy rodar) e uma vez no cliente (`StorageService`, ver §6). A camada do bucket nunca depende do cliente se comportar corretamente — mesmo princípio de "nenhuma autorização depende exclusivamente do cliente" (RC-04A), estendido para validação de upload.

---

## 5. Políticas de Storage (RLS)

Toda regra abaixo está em `storage.objects` (RLS já habilitada por padrão pelo Supabase em qualquer projeto — reforçada na migration só por consistência). Nenhum `GRANT` foi adicionado: diferente das tabelas de `public` (onde a ausência de GRANT já causou um bug histórico, ver RC-04A/migration `20260720130000`), `storage.objects`/`storage.buckets` são provisionadas pela própria plataforma Supabase no bootstrap do projeto, já com GRANT correto.

| Bucket | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `avatars` | qualquer autenticado (mesmo modelo de `profiles_select_authenticated` — ver §5.1) | dono (pasta = `auth.uid()`) | dono | dono |
| `restaurants` | qualquer autenticado | dono do restaurante OU `can_moderate()` | dono OU `can_moderate()` | dono OU `can_moderate()` |
| `review-photos` | qualquer autenticado | autor da avaliação | não implementado (cada foto é um arquivo novo, nunca substituído) | autor OU `can_moderate()` |

A ownership de `restaurants`/`review-photos` é resolvida por uma subconsulta às tabelas `public.restaurants`/`public.reviews` (`r.created_by = auth.uid()`/`rv.user_id = auth.uid()`), comparando o primeiro segmento do caminho (`storage.foldername(name)[1]`) com o `id` da linha correspondente. Essa subconsulta roda com o privilégio do próprio usuário chamador (não `SECURITY DEFINER`) — sem risco de recursão, já que `restaurants_select_authenticated`/`reviews_select_authenticated` (RC-03/DV-03/04) já permitem a qualquer autenticado ler qualquer linha dessas tabelas.

### 5.1 `avatars` é "privado" mas legível por qualquer autenticado

Achado da auditoria: embora `avatars` seja um bucket privado (`public = false`, sem URL pública direta), a policy de SELECT permite **qualquer autenticado**, não só o dono. Isso é intencional — `ProfileAvatar` (widget existente, não tocado nesta rodada) resolve o avatar de **qualquer** usuário via `createSignedAvatarUrl`, usado tanto na própria tela de perfil quanto em `public_profile_page.dart`/`follow_list_page.dart` (perfil de terceiros). A visibilidade do avatar precisa espelhar a visibilidade do próprio perfil (`profiles_select_authenticated`, público a qualquer autenticado) — restringir a leitura só ao dono quebraria a exibição do avatar de outros usuários em todo o app.

### 5.2 Administrador

Moderação de conteúdo em `restaurants`/`review-photos` segue exatamente o mesmo critério já estabelecido para as tabelas de dados (`restaurants_update_admin`/`reviews_update_admin`, RC-03/DV-08/RC-04A): `can_moderate()`, verdadeiro para `super_admin`/`admin`/`moderator`, falso para `support`. Nenhuma autorização administrativa de Storage depende do cliente — a mesma garantia já auditada na RC-04A para as tabelas se estende ao Storage.

### 5.3 Suíte de testes de RLS (pgTAP)

`supabase/tests/database/40_rls_storage.test.sql` — 18 asserções cobrindo os 3 buckets: leitura cruzada permitida (por design), escrita cruzada negada, escrita do dono permitida, e moderação por `can_moderate()` nos buckets públicos. Mesma decisão já registrada na RC-04A: escrita e revisada estaticamente, **não executada nesta sessão** (sem Docker local disponível) — pronta para rodar via:

```bash
cd supabase
supabase start
supabase test db --local supabase/tests/database
```

---

## 6. Validações

`StorageService.upload()`/`.replace()` rejeitam, antes de qualquer chamada ao Supabase:

| Validação | Mecanismo |
|---|---|
| Tamanho máximo | `bytes.lengthInBytes > config.maxBytes` — configurável por chamada via `StorageUploadConfig` |
| Tipos MIME permitidos | `contentType` comparado contra `config.allowedMimeTypes` |
| Extensões permitidas | extensão normalizada (`normalizeExtension`) comparada contra `config.allowedExtensions` |
| Arquivo vazio | `bytes.isEmpty` rejeitado |
| Path traversal | `folder` rejeitado se contiver `..`, `/` ou `\` (ver §7) |

`StorageUploadConfig` tem três presets estáticos (`.avatar`, `.restaurantCover`, `.reviewPhoto`) que **espelham exatamente** os limites já usados pelas telas existentes (5 MB para avatar, 10 MB para capa de restaurante e foto de avaliação; sempre jpg/jpeg/png/webp) — não são novos valores inventados nesta rodada, e ficam disponíveis para quando uma tela futura for conectada a `AppStorage`.

---

## 7. Padrão de nomes

`generateStorageFileName()` (`storage_filename.dart`, função pura e testável em isolamento — mesmo padrão de `flattenAnalyticsEventForPostHog`, RC-03C) **nunca reaproveita o nome enviado pelo usuário**: o resultado é sempre `<timestamp em microssegundos>-<8 caracteres hexadecimais aleatórios, `Random.secure()`>.<extensão>`. A extensão é a única parte do nome original que sobrevive ao caminho final — e só depois de validada contra `config.allowedExtensions`.

`folder` (o identificador de dono — `userId`/`restaurantId`/`reviewId`) é sempre fornecido pelo próprio app a partir de um UUID do banco, nunca texto livre digitado por alguém — mesmo assim, `StorageService` rejeita qualquer `folder` contendo `..`, `/` ou `\` antes de construir o caminho, como defesa em profundidade contra path traversal.

Nenhuma dependência nova foi adicionada para isso — `Random.secure()` é parte do SDK do Dart (`dart:math`), evitando declarar `uuid` como dependência direta só para gerar um sufixo aleatório (o pacote existe apenas transitivamente no projeto hoje).

---

## 8. Tratamento de erros

`StorageException` (`storage_exception.dart`) é a **única** exceção de toda a camada — lançada tanto pela validação (`StorageService`, antes de qualquer chamada ao Supabase) quanto pela fronteira com o SDK (`SupabaseStorageService`, traduzindo qualquer `StorageException` do próprio `supabase_flutter` ou falha de rede genérica). Nunca expõe a mensagem interna do Supabase — sempre uma mensagem amigável.

**Colisão de nomes resolvida deliberadamente**: `supabase_flutter` já exporta sua própria classe `StorageException`. `supabase_storage_service.dart` importa o pacote com `hide StorageException` e reimporta só a exceção deles com prefixo (`as supabase_storage`), garantindo que o nome `StorageException` sem prefixo, em todo o arquivo, sempre se refira à exceção própria do BORAH.

`replace()` segue a mesma filosofia de erro de `FeedbackService` (RC-03E), não de `FeatureFlagService` (RC-03D): existe sempre um chamador aguardando o resultado de forma síncrona, então a exceção se propaga — nunca é engolida silenciosamente pela camada de orquestração.

---

## 9. Offline / Supabase indisponível

- `SupabaseStorageService` traduz qualquer falha (rede, Supabase fora do ar, RLS) em `StorageException` — nunca deixa uma exceção crua do SDK escapar.
- `StorageService`/`AppStorage` deixam essa exceção se propagar — o app nunca trava; quem chamar (uma tela futura) decide como exibir o erro e permitir nova tentativa, mesmo padrão já usado por `FeedbackController`/`FeedbackDialog` (RC-03E).
- `replace()` é resiliente por construção: o arquivo novo só é considerado bem-sucedido após o upload confirmar; a remoção do arquivo anterior é *best-effort* — uma falha ao apagar o arquivo antigo nunca desfaz o upload novo nem deixa o usuário sem nenhum arquivo.

---

## 10. O que foi (e o que não foi) integrado nesta rodada

Mesma disciplina de escopo já usada na RC-03A–D: construir a infraestrutura completa e testada, sem instrumentar telas.

**Feito nesta rodada:**
- Toda a estrutura de código listada em §3.
- Migration com os 3 buckets, limites de tamanho/MIME no próprio bucket, e RLS completa (própria + admin) para os 3.
- Suíte pgTAP de RLS de Storage (18 asserções).

**Não feito nesta rodada (explicitamente fora de escopo):**
- Nenhuma tela foi conectada a `AppStorage`/`storageServiceProvider` — `UserRemoteDatasource`/`RestaurantRemoteDatasource`/`ReviewRemoteDatasource` continuam acessando o Storage diretamente, como antes desta rodada (ver §2).
- Nenhum dos 6 buckets aspiracionais restantes do `AR-08_STORAGE_ARCHITECTURE.md` (`groups`/`events`/`feed`/`badges`/`covers`/`temp`/`backups`) foi criado — sem consumidor real hoje.

---

## 11. Backlog (fora do escopo desta rodada)

1. **Migrar `UserRemoteDatasource`/`RestaurantRemoteDatasource`/`ReviewRemoteDatasource` para `AppStorage`** — eliminaria de vez o acesso direto ao SDK de Storage identificado em §2. Não feito aqui por instrução explícita ("não implementar upload em telas específicas nesta etapa").
2. **Buckets aspiracionais do AR-08** (`groups`/`events`/`feed`/`badges`/`covers`/`temp`/`backups`) — sem consumidor real ainda.
3. **Compressão de imagem antes do upload** (AR-08 §12, "preferir WEBP quando suportado") — hoje delegada ao `ImagePickerService` existente (`imageQuality: 85`, `maxWidth: 1024`), não à nova camada de Storage; reavaliar quando as telas forem migradas.
4. **Limpeza de arquivos órfãos** (AR-08 §13/§16) — nenhum mecanismo de monitoramento/limpeza periódica existe ainda.

---

## 12. Testes

| Arquivo | Cobertura |
|---|---|
| `test/unit/core/storage/storage_filename_test.dart` | `normalizeExtension` (minúsculas, query string, múltiplos pontos, sem extensão); `generateStorageFileName` (nunca reaproveita o nome original, nomes distintos entre chamadas, formato) |
| `test/unit/core/storage/storage_service_test.dart` | `upload()` (caminho feliz, tamanho, MIME, extensão, path traversal); `replace()` (upload+delete best-effort, sem `previousPath`, falha no delete não derruba a operação, upload que falha nunca chama delete); `download()`/`delete()`/`getPublicUrl()`/`createSignedUrl()` (delegação e propagação de erro) |
| `test/unit/core/storage/storage_providers_test.dart` | `storageServiceProvider` constrói corretamente, usa o repositório injetado, é uma instância estável, propaga chamadas |
| `test/unit/core/storage/app_storage_test.dart` | Fachada estática: `upload`/`delete`/`replace`/`getPublicUrl`/`getSignedUrl`/`download`, incluindo propagação de erro de validação |
| `supabase/tests/database/40_rls_storage.test.sql` | 18 asserções de RLS cross-user (ver §5.3) — **não executada nesta sessão** |

**Nota de teste**: `SupabaseStorageService` não é testada diretamente contra um `SupabaseClient` real (mesma decisão já tomada para `SupabaseFeedbackRepository`/`SupabaseFeatureFlagRepository`/`PostHogAnalyticsService`) — os testes de `StorageService`/`AppStorage` usam um `StorageRepository` mockado via `mocktail`.

Suíte completa do projeto (`flutter test`): **444/444**, zero regressão (baseline anterior: 408/408 + 36 novos testes desta rodada).

---

## 13. Limitações desta rodada

- Nenhuma tela usa `AppStorage` ainda — os três pontos de upload já existentes no app continuam com acesso direto ao Storage (ver §2/§11).
- Suíte pgTAP de RLS de Storage não executada — mesma limitação de ambiente já registrada na RC-04A (sem Docker local disponível nesta sessão).
- `SupabaseStorageService` não validada contra uma instância real do Supabase Storage (mesma limitação de todas as migrations do projeto, ver AR-06/EX-01B).
