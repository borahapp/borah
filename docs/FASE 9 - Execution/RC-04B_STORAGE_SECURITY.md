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

---

## 14. RC-04B1 — Storage Hardening

**Data:** 2026-07-25
**Branch:** `feature/rc-04b1-storage-hardening`
**Objetivo:** eliminar as 5 ressalvas apontadas pela auditoria técnica independente da RC-04B (não uma nova RC — nenhuma tela foi conectada, nenhuma funcionalidade nova foi implementada).

### 14.1 Item 1 — Código morto removido

`StorageRepository.update()`/`SupabaseStorageService.update()` foram auditados: busca em todo `lib/` e `test/` confirmou **zero consumidores e zero testes** referenciando o método (as únicas ocorrências de `.update(` no projeto pertencem a `comments`/`reviews`, features completamente não relacionadas). Sem nenhuma justificativa arquitetural documentada para mantê-lo, o método foi **removido** da interface e da implementação — não havia teste a remover, já que nenhum jamais existiu para ele.

### 14.2 Item 2 — Observabilidade adicionada a `replace()`

O `catch` best-effort ao apagar o arquivo anterior agora registra telemetria via `AppLogger.warning(...)` (mesma infraestrutura da RC-03B — WARNING é sempre encaminhado ao Sentry via `CrashReporting.captureLog`) — inclui o bucket/caminho do arquivo órfão e o erro original, sem propagar a exceção (o upload continua sendo sucesso do ponto de vista de quem chamou). Esta é a **primeira chamada real a `AppLogger` em código de feature/`core`** do projeto — até aqui, `AppLogger` era infraestrutura pronta desde a RC-03B, mas nunca efetivamente invocada fora de seus próprios testes. Cobertura nova: 2 testes (telemetria disparada na falha; telemetria **ausente** no caminho de sucesso, para descartar falso-positivo de log em toda chamada).

### 14.3 Item 3 — Migration dos buckets: reconciliação parcial, sem editar a migration original

**Achado antes de implementar**: o plano inicial (trocar `ON CONFLICT DO NOTHING` por `DO UPDATE` diretamente na migration `20260725120000_create_storage_buckets.sql`) violaria a própria disciplina histórica do projeto — nenhuma migration já mesclada em `develop` é editada; toda correção retroativa vira uma migration nova (mesmo padrão de `20260718212615`, `20260720130000`, `20260720130015`, `20260720130030`). Corrigido: a migration original permanece intocada; uma nova migration (`20260725130000_reconcile_storage_bucket_limits.sql`) faz o `UPDATE` de reconciliação.

**Decisão arquitetural aprovada pelo usuário**: a reconciliação cobre **apenas** `file_size_limit`/`allowed_mime_types` — nunca a coluna `public`. `file_size_limit`/`allowed_mime_types` só afetam uploads futuros (sem risco de expor nada já armazenado). `public`, ao contrário, tem efeito imediato de controle de acesso (o Supabase Storage decide se serve um objeto publicamente consultando essa flag em tempo de requisição) — uma mudança de público/privado deve sempre passar por sua própria migration nova e explícita, revisável em code review, nunca por um `UPDATE` genérico que possa se repetir por engano.

### 14.4 Item 4 — Suíte pgTAP: bloqueio documentado, não simulado

Confirmado nesta sessão: o Docker Desktop **não está em execução** (`com.docker.service` no estado `Stopped`; conexão a `npipe:////./pipe/dockerDesktopLinuxEngine` falha). Não foi feita nenhuma tentativa de iniciar o Docker Desktop automaticamente (ação pesada no sistema do usuário, mesma decisão já tomada na RC-04A). **As suítes pgTAP da RC-04A (`10`/`20`/`30_rls_*.test.sql`) e da RC-04B (`40_rls_storage.test.sql`) continuam não executadas.** Nenhuma delas deve ser considerada validada até rodarem com sucesso via:
```bash
cd supabase
supabase start
supabase test db --local supabase/tests/database
```

### 14.5 Item 5 — Validação de MIME: vulnerabilidade confirmada e corrigida

**Investigação** (fontes oficiais do próprio repositório `supabase/storage`, o backend real do Storage):
- [GitHub Issue #576](https://github.com/supabase/storage/issues/576) — confirma que a validação de `allowed_mime_types` não inspeciona bytes reais; a *issue* pedindo detecção por magic number foi **fechada como "not planned"** pelos mantenedores.
- [GitHub Issue #639](https://github.com/supabase/storage/issues/639) — reprodução prática: um GIF renomeado para `.jpg` foi aceito por um bucket restrito a `image/jpeg`.
- Análise da função `validateMimeType` (`src/storage/uploader.ts`, via [DeepWiki](https://deepwiki.com/supabase/storage/4.8-image-transformation)) — confirma que a validação usa o **Content-Type declarado pelo cliente** (header ou campo do multipart), nunca o conteúdo real.
- A [documentação oficial de buckets](https://supabase.com/docs/guides/storage/buckets/fundamentals) não faz nenhuma promessa de validação de conteúdo — silêncio consistente com o comportamento real encontrado no código-fonte.

**Conclusão**: a "dupla camada" de validação documentada originalmente no §4.1 (bucket + `StorageService`) era, na prática, **a mesma checagem (Content-Type/extensão declarados) feita duas vezes** — nem o Supabase Storage nem o `StorageService` original inspecionavam os bytes reais.

**Correção implementada** (aprovada pelo usuário após apresentação das evidências): `lib/core/storage/storage_magic_bytes.dart` — `matchesImageSignature(bytes, extension)`, função pura sem dependência nova, checando a assinatura binária de JPEG (`FF D8 FF`), PNG (`89 50 4E 47 0D 0A 1A 0A`) e WebP (`RIFF....WEBP`). Chamada por `StorageService._validate()` como última etapa da validação, depois de tamanho/MIME/extensão. Cobertura nova: 10 testes dedicados (`storage_magic_bytes_test.dart`) + 4 testes de integração em `storage_service_test.dart` (rejeita arquivo com extensão trocada, rejeita bytes arbitrários, aceita JPEG/PNG reais).

**Limite honesto, documentado deliberadamente**: esta checagem fecha a lacuna para o caminho legítimo do app (o `image_picker` declara um Content-Type que não corresponde aos bytes reais) — **não** substitui nenhuma garantia de servidor. Um cliente que chame a API do Supabase diretamente, contornando o app Flutter inteiro, não passa por `StorageService`. Fechar essa lacuna do lado do servidor exigiria sniffing real no backend do Supabase (fora do controle deste projeto, e explicitamente não planejado pelos mantenedores) ou uma Edge Function intermediária (infraestrutura que o projeto não tem — mesma decisão já registrada no DV-08).

### 14.6 Testes

| Arquivo | Cobertura nova |
|---|---|
| `test/unit/core/storage/storage_service_test.dart` | Telemetria de `replace()` (disparada na falha, ausente no sucesso); 4 testes de assinatura binária; ajuste de todas as fixtures de bytes para conter assinaturas reais válidas onde o upload deve suceder |
| `test/unit/core/storage/storage_magic_bytes_test.dart` (novo) | `matchesImageSignature` — JPEG/PNG/WebP válidos, assinaturas incompletas/incorretas, extensão desconhecida |
| `test/unit/core/storage/app_storage_test.dart` | Fixtures de bytes ajustadas para assinatura JPEG real nos testes que esperam sucesso |

Suíte completa do projeto (`flutter test`): **459/459**, zero regressão (baseline RC-04B: 444/444 + 15 novos testes desta rodada de hardening).

### 14.7 Decisões arquiteturais registradas nesta rodada

1. **Migration original nunca editada** — a correção da RC-04B1 (item 3) virou uma migration nova, preservando o histórico, mesma disciplina de todo o projeto.
2. **`public` excluído da reconciliação automática de buckets** — qualquer mudança de público/privado exige uma migration nova e explícita, nunca um efeito colateral de reaplicar uma UPDATE genérica.
3. **Checagem de magic bytes implementada sem dependência nova** — assinaturas de JPEG/PNG/WebP são conhecimento público e estável da especificação de cada formato, dispensando um pacote como `mime`/`file_type` para uma allowlist de apenas 3 formatos.
4. **Suítes pgTAP permanecem não executadas** — bloqueio de ambiente (Docker), não simulado, documentado explicitamente conforme instruído.
