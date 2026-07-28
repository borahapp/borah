# Go / No-Go Review — Checklist Operacional

**Contexto:** BETA-11A. Checklist final antes de convidar qualquer usuário externo ao Beta Fechado. Cada item tem um critério objetivo de aprovação, a evidência esperada, o responsável e o status atual.

---

## Aplicativo

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| Fluxo de cadastro completo | Novo usuário consegue criar conta e chegar à Home | Teste manual em dispositivo real | QA/Proprietário | 🔴 Pendente (nunca testado em build de Produção real) |
| Login | Usuário existente consegue autenticar | Teste manual | QA/Proprietário | 🔴 Pendente |
| Recuperação de senha | E-mail de recuperação chega e o deep link funciona | Teste manual ponta a ponta | QA/Proprietário | 🔴 Pendente — depende do Redirect URL cadastrado no Supabase Dashboard de Produção |
| Exclusão de conta | Conta e dados removidos conforme a Política de Privacidade | Teste manual + verificação no banco | QA/Proprietário | 🟡 Implementado e testado em QA (RC-04C); não testado contra Produção |
| Build Android instalável | AAB/APK assinado instala e abre em dispositivo físico | Instalação real | Proprietário | 🔴 Pendente (build gerada com sucesso, mas com chave de debug — BETA-10B) |
| Build iOS instalável | IPA instala via TestFlight | Instalação real | Proprietário (Mac) | 🔴 Pendente — nunca validada em nenhum ambiente |

## Backend

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| Supabase de Produção operacional | Schema/RLS/Storage idênticos ao QA | Comparação de migrations aplicadas | Engenharia | ✅ Concluído (BETA-05) |
| Redirect URL cadastrado | `borah://password-recovery` registrado no Dashboard de Produção | Confirmação visual no Dashboard | Proprietário | 🔴 Pendente |
| Buckets de Storage funcionais | Upload de avatar/foto de review funciona contra Produção | Teste manual | QA/Proprietário | 🔴 Pendente |

## Infraestrutura

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| GitHub Environment `production` criado | Existe em Settings → Environments | Captura de tela/confirmação | Proprietário | 🔴 Pendente |
| 9 secrets de Produção cadastrados | Todos presentes no Environment `production` | Lista conferida (sem expor valores) | Proprietário | 🔴 Pendente |
| `release.yml` disparado com sucesso ao menos uma vez | Job conclui sem erro, artefato gerado | Log do GitHub Actions | Proprietário | 🔴 Pendente — nunca disparado com os secrets reais |

## Segurança

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| RLS ativa em 100% das tabelas | Confirmado por introspecção do banco | Já verificado (BETA-05) | Engenharia | ✅ Concluído |
| Keystore Android gerada e em cofre seguro | Arquivo `.jks` + senhas guardados fora do repositório | Confirmação verbal do proprietário | Proprietário | 🔴 Pendente |
| `android:allowBackup` decidido | Valor explícito definido (hoje usa o default `true`, achado da BETA-10A) | Revisão de `AndroidManifest.xml` | Engenharia | 🔴 Pendente |
| Suítes pgTAP de RLS executadas | Rodadas com sucesso contra um ambiente real | Log de execução | Engenharia (requer Docker) | 🔴 Pendente (bloqueado desde a RC-04A) |

## Analytics

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| Projeto PostHog de Produção criado | Projeto existe, região decidida | Confirmação do proprietário | Proprietário | 🔴 Pendente |
| Eventos chegando ao dashboard | Evento de teste visível em Live Events | Captura de tela do dashboard | Proprietário | 🔴 Pendente |
| `POSTHOG_HOST_PRODUCTION` cadastrado corretamente | Valor não-vazio, condizente com a região | Confirmação (sem expor o valor) | Proprietário | 🔴 Pendente — **item crítico**, ver achado da BETA-08C1 |

## Observabilidade

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| Projeto Sentry de Produção criado | Projeto existe | Confirmação do proprietário | Proprietário | 🔴 Pendente |
| Evento de teste capturado | Exceção de teste (estratégia segura da BETA-08B) aparece no dashboard, com `environment: production` | Captura de tela do Sentry | Proprietário | 🔴 Pendente |
| PII redigida corretamente | Evento de teste não contém e-mail/senha/token em texto puro | Inspeção manual do evento capturado | Proprietário | 🔴 Pendente (mecanismo já testado unitariamente, mas não contra o Sentry real) |

## Google Play

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| Conta criada e verificada | Status "verificado" no Console | Confirmação do proprietário | Proprietário | 🔴 Pendente |
| Ficha da loja preenchida | Todos os campos obrigatórios completos | Revisão visual no Console | Proprietário | 🔴 Pendente |
| Data Safety/Content Rating preenchidos | Formulários submetidos | Confirmação no Console | Proprietário | 🔴 Pendente |
| Internal Testing ativa | Faixa criada, testadores adicionados, AAB enviado | Confirmação no Console | Proprietário | 🔴 Pendente |

## Apple

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| Conta Apple Developer ativa | Membership confirmado | Confirmação do proprietário | Proprietário | 🔴 Pendente |
| Build iOS compilada com sucesso | Archive gerado sem erro no Xcode | Log do Xcode | Proprietário (Mac) | 🔴 Pendente — **maior incerteza técnica restante** |
| Privacy Manifest validado | Sem warnings no Xcode | Captura de tela do editor de Privacy Manifest | Proprietário (Mac) | 🔴 Pendente |
| TestFlight configurado | Build disponível para o grupo de teste | Confirmação no App Store Connect | Proprietário | 🔴 Pendente |

## Site

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| Domínio configurado (DNS) | `appborah.com.br` resolve para o GitHub Pages | `dig`/verificação de DNS | Proprietário | 🔴 Pendente |
| Política de Privacidade acessível publicamente | URL real carrega o conteúdo | Acesso via navegador | Proprietário | 🔴 Pendente |
| Termos de Uso acessível publicamente | Idem | Idem | Proprietário | 🔴 Pendente |
| Página de Suporte acessível publicamente | Idem | Idem | Proprietário | 🔴 Pendente |

## Jurídico

| Item | Critério de aprovação | Evidência esperada | Responsável | Status |
|---|---|---|---|---|
| Conteúdo jurídico redigido | Política/Termos/Suporte completos | Já existe (`docs/legal/`) | Engenharia | ✅ Concluído |
| Revisão por advogado | Confirmação de que os 5 pontos levantados (`docs/legal/README.md`) foram avaliados | Parecer jurídico (dentro ou fora do repositório) | Proprietário | 🔴 Pendente |
| Idade mínima do Beta comunicada de forma consistente | 18 anos em todos os textos (app, loja, site) | Revisão cruzada dos textos | Engenharia | ✅ Concluído (BETA-09B1) |

---

## Regra de decisão

**Nenhum item "Aplicativo"/"Backend"/"Segurança" pode ficar 🔴 no momento de convidar o primeiro usuário externo.** Itens de "Google Play"/"Apple"/"Site" podem estar em andamento simultâneo, desde que o app em si já tenha sido validado ponta a ponta (build real instalada, login/cadastro/exclusão testados).
