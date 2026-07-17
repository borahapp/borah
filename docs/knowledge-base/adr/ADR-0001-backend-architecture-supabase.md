# ADR-0001 — Adoção do Supabase como Arquitetura Oficial de Backend do BORAH

**ID:** ADR-0001
**Título:** Adoção do Supabase (BaaS) como arquitetura oficial de backend
**Status:** Aprovado
**Data:** 2026-07-17
**Autor da decisão:** Product Owner do BORAH (aprovação registrada em sessão de auditoria documental)

---

## 1. Contexto

Durante uma auditoria completa da documentação do projeto BORAH (pasta `docs/` e `prompts/EX-07_MASTER_PROMPT.md`), foram identificadas **três descrições de arquitetura de backend mutuamente incompatíveis**, cada uma apresentada como "oficial" em conjuntos de documentos diferentes, sem que nenhum ADR prévio reconciliasse as divergências:

| Fonte | Status/Versão | Backend descrito |
|---|---|---|
| `prompts/EX-07_MASTER_PROMPT.md` (§4) e `docs/FASE 9 - Execution/EX-01_PROJECT_BOOTSTRAP.md` (§3) | Approved, v1.0 | Go + Clean Architecture + REST API + PostgreSQL + Redis + Docker |
| `docs/FASE 2 - Documentação/ET-01_SYSTEM_ARCHITECTURE.md`, `ET-03_AUTHENTICATION.md`, `ET-10_NOTIFICATIONS.md`, `ET-12_SECURITY.md` | Draft, v1.0 | NestJS + Prisma (Node/TypeScript) + PostgreSQL + Firebase (Auth/FCM) |
| `docs/FASE 4 - FOUNDATION/AR-01` a `AR-18` (18 arquivos), `docs/FASE 5 - Desenvolvimento/DV-01` a `DV-12` (12 módulos), `docs/FASE 6 - Qualidade/QA-01` a `QA-08` (8 documentos) | Recommended/Approved, v2.0 | Supabase (BaaS): Auth, PostgreSQL + Row Level Security, Storage, Realtime, Edge Functions (Deno/TypeScript) |

Nenhum dos três conjuntos de documentos faz referência cruzada aos demais, e nenhum reconhece a existência dos outros dois modelos. O `ET-00_PROJECT_CONVENTIONS.md` (Convenções do Projeto) define uma estrutura de pastas `apps/backend` com camadas `controller/service/usecases/repository/entity/dto/mapper/validators`, que pressupõe um serviço de aplicação próprio — compatível com os modelos Go ou NestJS, mas estruturalmente incompatível com um modelo "somente Supabase" (BaaS gerenciado, sem processo de servidor de aplicação customizado).

## 2. Problema

Nenhuma implementação de código pôde ser iniciada com segurança enquanto essa contradição não fosse resolvida, pois a decisão de stack determina: linguagem do backend, estrutura de pastas do monorepo, modelo de autorização (RLS vs. middleware de API), estratégia de deploy/infra, e a forma como praticamente todos os módulos funcionais (DV-01 a DV-12) e de qualidade (QA-01 a QA-08) devem ser lidos e implementados.

## 3. Alternativas avaliadas

**A. Go + REST API custom** (EX-07 / EX-01)
- Prós: alinhado ao Master Prompt que rege o comportamento operacional da IA; performance e controle total do backend.
- Contras: é a stack menos documentada em profundidade (apenas 2 documentos a mencionam de forma central); exigiria reescrever integralmente toda a FASE 4, FASE 5 e FASE 6 (38 documentos) que já descrevem Supabase em detalhe.

**B. NestJS + Prisma custom** (ET-01, ET-03, ET-10, ET-12)
- Prós: documentado como "Arquitetura Oficial do Sistema" na FASE 2; TypeScript oferece afinidade com Edge Functions (Deno/TS) já usadas em outras partes da documentação.
- Contras: os quatro documentos que a descrevem estão em status **Draft** (não aprovados); igualmente exigiria reescrever FASE 4/5/6.

**C. Supabase (BaaS)** (FASE 4, FASE 5, FASE 6)
- Prós: é a arquitetura descrita com maior profundidade e consistência — 18 documentos de arquitetura (AR-01 a AR-18), 12 módulos funcionais completos (DV-01 a DV-12) e toda a estratégia de qualidade (QA-01 a QA-08) já assumem Supabase como backend, com Status majoritariamente "Recommended/Approved v2.0" (revisão mais recente). Reduz drasticamente o escopo de infraestrutura própria (sem servidor de API a manter, sem gestão de containers de aplicação backend).
- Contras: exige reconciliar/superar os documentos Go (EX-07, EX-01) e NestJS (ET-01, ET-03, ET-10, ET-12); a estrutura `apps/backend` com camadas controller/service/usecases do ET-00 precisará ser reinterpretada como organização interna das Edge Functions, não como um serviço de aplicação separado.

## 4. Decisão

**O BORAH adotará o Supabase como Backend-as-a-Service (BaaS) oficial**, conforme descrito em `docs/FASE 4 - FOUNDATION/AR-06_SUPABASE_SETUP.md`, `AR-07_DATABASE_ARCHITECTURE.md`, `AR-09_EDGE_FUNCTIONS.md`, `AR-13_ROW_LEVEL_SECURITY.md` e demais documentos AR-*, com os módulos funcionais `docs/FASE 5 - Desenvolvimento/DV-01` a `DV-12` e a estratégia de qualidade `docs/FASE 6 - Qualidade/QA-01` a `QA-08` como referência de implementação.

A partir desta decisão:
1. **Toda a documentação das FASE 4 (Foundation), FASE 5 (Desenvolvimento) e FASE 6 (Qualidade) passa a ser a referência oficial da arquitetura de backend do projeto.**
2. As referências a **Go + REST API** (`EX-07_MASTER_PROMPT.md`, `EX-01_PROJECT_BOOTSTRAP.md`) e a **NestJS + Prisma** (`ET-01_SYSTEM_ARCHITECTURE.md`, `ET-03_AUTHENTICATION.md`, `ET-10_NOTIFICATIONS.md`, `ET-12_SECURITY.md`) representam **decisões arquiteturais superadas** e serão preservadas apenas como histórico do projeto — não devem ser usadas como referência para novas implementações.
3. Nenhum documento legado será apagado ou reescrito neste momento; a atualização gradual desses documentos será conduzida por um plano específico (ver seção 7) e depende de aprovação prévia.

## 5. Justificativa

A decisão se apoia em três critérios objetivos, verificados durante a auditoria:
- **Volume e profundidade:** ~38 documentos técnicos (FASE 4 + FASE 5 + FASE 6) descrevem Supabase de forma consistente e detalhada, contra 2 documentos que mencionam Go e 4 que mencionam NestJS.
- **Recência:** os documentos AR-* estão em v2.0 ("Recommended"), uma revisão posterior aos documentos ET-* e EX-* relevantes (v1.0), sugerindo que a arquitetura evoluiu para Supabase depois da redação inicial da FASE 2 e da FASE 9.
- **Coerência interna:** os diagramas de arquitetura, o modelo de autorização (RLS), a estratégia de testes (QA-03 cita explicitamente `Supabase Test Project`) e o pipeline de CI/CD (AR-05) formam um conjunto internamente consistente em torno de Supabase, sem lacunas de mecanismo (diferente das outras duas alternativas, que carecem de detalhamento equivalente).
- Esta justificativa técnica foi apresentada ao Product Owner do projeto, que confirmou explicitamente a escolha do Supabase como arquitetura oficial.

## 6. Consequências

- **Estrutura de repositório:** o bootstrap do projeto (atualmente descrito no `EX-01_PROJECT_BOOTSTRAP.md` com pastas `backend/{api,domain,application,infrastructure,tests}`) precisará ser reinterpretado/atualizado para `backend/supabase/{migrations,seed,functions,storage,policies,config}`, conforme já detalhado em `AR-01_PROJECT_STRUCTURE.md` e `AR-03_ENVIRONMENT_CONFIGURATION.md`.
- **`ET-00_PROJECT_CONVENTIONS.md`** define uma estrutura de camadas de backend (`controller/service/usecases/repository/entity/dto/mapper/validators`) que pressupõe um servidor de aplicação próprio. Esse documento **não foi listado explicitamente para superação nesta decisão**, mas apresenta a mesma incompatibilidade estrutural identificada nos documentos Go/NestJS. Fica registrado aqui como um ponto em aberto que deverá ser tratado explicitamente (reconciliado ou formalmente superado) em decisão futura, antes do bootstrap técnico.
- **Segurança/autorização:** o modelo de autorização passa a ser primariamente via Row Level Security (RLS) no PostgreSQL gerenciado pelo Supabase, e não por uma camada de middleware/autorização em um serviço de aplicação customizado.
- **Testes:** a estratégia de testes de integração/performance/segurança (QA-03, QA-05, QA-06) já assume Supabase Test Project/Dashboard — nenhuma adaptação adicional é necessária nesses documentos.
- **Nenhuma alteração de código é implicada por este ADR** — é uma decisão de arquitetura documental, a ser executada em passos futuros aprovados individualmente.

## 7. Impactos e próximos passos

Este ADR não modifica nenhum documento legado. Ele apenas formaliza a decisão e referencia os documentos impactados, que serão atualizados por meio de um **plano de atualização gradual** (a ser apresentado separadamente ao Product Owner para aprovação), preservando o conteúdo original de cada documento como histórico do projeto.

## 8. Referências

**Decisão vigente (referência oficial):**
- `docs/FASE 4 - FOUNDATION/AR-01_PROJECT_STRUCTURE(1).md` a `AR-18_MONITORING.md`
- `docs/FASE 5 - Desenvolvimento/DV-01_AUTHENTICATION_MODULE.md` a `DV-12_RELEASE_AND_PUBLISHING.md`
- `docs/FASE 6 - Qualidade/QA-01_QUALITY_STRATEGY.md` a `QA-08_ACCEPTANCE_AND_GO_LIVE.md`

**Decisões superadas (preservadas como histórico):**
- `prompts/EX-07_MASTER_PROMPT.md`
- `docs/FASE 9 - Execution/EX-01_PROJECT_BOOTSTRAP.md`
- `docs/FASE 2 - Documentação/ET-01_SYSTEM_ARCHITECTURE.md`
- `docs/FASE 2 - Documentação/ET-03_AUTHENTICATION.md`
- `docs/FASE 2 - Documentação/ET-10_NOTIFICATIONS.md`
- `docs/FASE 2 - Documentação/ET-12_SECURITY.md`

**Ponto em aberto (não resolvido por este ADR):**
- `docs/FASE 2 - Documentação/ET-00 — Convenções do Projeto.docx`
