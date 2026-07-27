# BETA-04 — Plano Operacional de Provisionamento

**Data:** 2026-07-27
**Branch:** nenhuma (documentação pura, sem alteração de código — commit direto em `develop`, conforme protocolo desta rodada)
**Status:** Concluído — auditoria e plano operacional entregues. Nenhuma build gerada, nenhuma publicação realizada, nenhum código/workflow/secret alterado.
**Escopo:** auditoria completa dos 22+ itens externos necessários para publicação e um plano operacional (ordem, tempo, custo, dependências, responsável) para o proprietário executar antes da Etapa 3B (primeira build para TestFlight/Google Play Internal Testing).

---

## 1. Objetivo

Dar ao proprietário um roteiro único e executável para provisionar tudo o que está fora do alcance de código (contas, certificados, conteúdo de loja) — sem que o BORAH gere ou publique nenhuma build antes que esse provisionamento esteja completo.

---

## 2. Metodologia

Esta auditoria combina duas fontes:

1. **O que já foi levantado no projeto** — `BETA-03_PRODUCTION_STORE_PREPARATION.md` (auditoria de código/infraestrutura, gap analysis e inventário de dados coletados) permanece válido e não foi refeito aqui, só referenciado.
2. **Verificação de políticas atuais das lojas** (Apple/Google mudam regras de publicação com frequência — as taxas e regras de teste abaixo foram confirmadas nesta data, não assumidas de memória). Fontes ao final do documento (§10).

---

## 3. Fase 1 — Auditoria dos itens externos

| # | Item | Situação atual | Classificação |
|---|---|---|---|
| 1 | Google Play Console | Conta não criada | 🔴 requer conta (proprietário) |
| 2 | Apple Developer Program | Inscrição não realizada | 🔴 requer conta (proprietário) |
| 3 | App Store Connect | App ainda não cadastrado — depende do item 2 | 🔴 depende do item 2 |
| 4 | TestFlight | Não configurado — depende do item 3 | 🔴 depende do item 3 |
| 5 | Projeto Supabase Produção | Não provisionado (só `borah-development`/`borah-qa` existem) | 🔴 requer conta Supabase |
| 6 | Projeto PostHog Produção | Não provisionado | 🔴 requer conta PostHog |
| 7 | Projeto Sentry Produção | Não provisionado | 🔴 requer conta Sentry |
| 8 | GitHub Secrets | Nomes e formato já documentados (BETA-03, `CI_CD_SECRETS.md` §2/§2.1); nenhum valor real cadastrado | 🟡 depende apenas de configuração, uma vez os itens 2/5/6/7/9 existirem |
| 9 | Android Keystore | Não gerada | 🔴 requer ação do proprietário (custódia exclusiva) |
| 10 | Apple Certificates | Não existem — depende do item 2 | 🔴 depende do item 2 |
| 11 | Provisioning Profiles | Não existem — normalmente automáticos via Xcode "Automatic Signing", depende do item 2 | 🔴 depende do item 2 |
| 12 | Bundle IDs | Já definidos no código (`com.borah.app`, consistente em Android/iOS) — só falta **registrar** nos consoles | 🟡 config apenas |
| 13 | Redirect URLs | Já implementado no app (`borah://password-recovery`, Android+iOS desde a RC-04E) — falta cadastrar no Dashboard do Supabase de Produção | 🟡 depende do item 5 |
| 14 | OAuth | **Não aplicável hoje** — o BORAH só implementa e-mail/senha via Supabase Auth; nenhum provedor OAuth de terceiros (Google/Apple/Facebook Sign-In) existe no código. Nada a provisionar; a exigência da Apple de oferecer "Sign in with Apple" quando há outros logins sociais (guideline 4.8) não se aplica, pois não há login social nenhum | ✅ não aplicável |
| 15 | Política de Privacidade | **Não existe** — bloqueador de submissão nas duas lojas | 🔴 depende exclusivamente do proprietário (conteúdo jurídico) |
| 16 | Termos de Uso | **Não existe** | 🔴 depende exclusivamente do proprietário |
| 17 | Página de suporte | Não existe (nenhum site/página institucional do BORAH) | 🔴 depende do proprietário (decisão + hospedagem) |
| 18 | E-mail de suporte | Não definido | 🔴 depende do proprietário |
| 19 | Ícones de loja | ✅ Prontos — ícone 512px do Google Play copiado na IV-09; ícone 1024px (matriz) e demais tamanhos já gerados desde a IV-02 | ✅ pronto |
| 20 | Feature Graphic (Google Play, 1024×500) | Não existe — sem arte oficial pronta no pacote de identidade visual | 🔴 requer criação (design) |
| 21 | Screenshots | Não existem — precisam de uma build de Produção funcional rodando em dispositivo/emulador real | 🔴 depende dos itens 5/8/9 (build funcional) |
| 22 | Classificação indicativa (Google Play) | Não preenchida — questionário de auto-declaração (IARC) | 🟡 preenchimento rápido, sem dependência técnica |
| 23 | Data Safety (Google Play) | Não preenchido — **inventário de dados já pronto** (`BETA-03_PRODUCTION_STORE_PREPARATION.md` §5.3) | 🟡 preenchimento usando material já pronto |
| 24 | App Privacy (App Store Connect) | Não preenchido — mesmo inventário do item 23 serve para ambos | 🟡 preenchimento usando material já pronto, depende do item 3 |

---

## 4. Fase 2 — Gap Analysis: ordem, dependências e responsáveis

### 4.1 Grafo de dependências (visão executiva)

```text
Fase A — Decisões estratégicas (bloqueiam o resto, resolver primeiro)
  ├─ Individual vs Organização (Apple E Google Play — ver §6, decisão real, não trivial)
  ├─ Conteúdo de Política de Privacidade / Termos de Uso
  └─ Domínio/e-mail de suporte a usar

Fase B — Contas e projetos (paralelizáveis entre si, após a Fase A)
  ├─ Apple Developer Program (enrollment)
  ├─ Google Play Console (registro + verificação de identidade)
  ├─ Supabase — projeto de Produção
  ├─ Sentry — projeto de Produção
  ├─ PostHog — projeto de Produção
  └─ Hospedagem da Política de Privacidade/Termos (assim que o texto existir)

Fase C — Configuração técnica (depende da Fase B correspondente)
  ├─ Keystore Android → gerar e guardar em cofre
  ├─ GitHub Secrets (Environment `production`) → 4 de keystore + 4 de ambiente
  ├─ `supabase db push` no projeto de Produção → schema/RLS/Storage (automático, 31 migrations)
  ├─ Redirect URL no Supabase Dashboard de Produção
  ├─ App record no Google Play Console (`com.borah.app`)
  ├─ App record no App Store Connect (`com.borah.app`)
  └─ `DEVELOPMENT_TEAM` no Xcode + certificado/provisioning profile (Automatic Signing)

Fase D — Conteúdo de loja (paralelizável com a Fase C, após a Fase A)
  ├─ Classificação indicativa
  ├─ Data Safety / App Privacy (inventário já pronto)
  ├─ Feature Graphic (design)
  └─ Screenshots (depende de uma build de Produção funcional — só após a Fase C completa)

Fase E — Primeira build (FORA DO ESCOPO DESTA RODADA — Etapa 3B, aguardando autorização)
  ├─ Gerar build assinada (release.yml já preparado, ver BETA-03)
  ├─ Upload TestFlight (External Testing — 1ª build exige revisão da Apple, ~24h)
  └─ Upload Google Play Internal Testing (imediato)
```

### 4.2 Tabela de responsáveis

| Item | Depende de | Responsável |
|---|---|---|
| Decisão Individual/Organização (ambas as lojas) | — | Proprietário (decisão estratégica, ver §6) |
| Apple Developer Program | Decisão acima | Proprietário |
| Google Play Console | Decisão acima | Proprietário |
| Supabase/Sentry/PostHog Produção | — | Proprietário (contas próprias) |
| Android Keystore | — | Proprietário (custódia exclusiva, nunca em texto puro) |
| GitHub Secrets | Contas acima existirem | Proprietário (acesso admin ao repositório) |
| `DEVELOPMENT_TEAM`/certificados/profiles | Apple Developer Program ativo | Proprietário, via Xcode |
| Política de Privacidade/Termos | — | Proprietário (conteúdo jurídico) — posso ajudar a redigir o texto numa rodada futura, mediante as informações de negócio (razão social, contato de DPO, jurisdição) |
| Página/e-mail de suporte | — | Proprietário |
| Feature Graphic | Decisão de direção visual | Proprietário/Design — o pacote oficial de identidade (`identidade visual-borah/`) não inclui essa peça pronta |
| Screenshots | Build de Produção funcional (Fase C completa) | Proprietário/QA, com dispositivo ou emulador real |
| Classificação indicativa/Data Safety/App Privacy | Contas das lojas existirem | Proprietário, preenchendo os formulários com o inventário já pronto |

---

## 5. Tempo estimado por atividade

| Atividade | Tempo estimado | Observação |
|---|---|---|
| Apple Developer Program — conta **Individual** | 24–48h (confirmação), mas atrasos de semanas têm sido reportados em 2026 | Sem D-U-N-S |
| Apple Developer Program — conta **Organização** | 1–2 semanas (mais até 5 dias úteis extras se ainda não houver D-U-N-S) | Ver §6 |
| Google Play Console — registro + verificação de identidade | Até 2 dias úteis (contas pessoais) | Exige documento de identidade oficial |
| App Store Connect — criar registro do app | ~15 min | Após Apple Developer Program ativo |
| Google Play Console — criar registro do app | ~15 min | Após conta verificada |
| Supabase — criar projeto de Produção | 15–30 min | Gratuito no plano free (ver §7) |
| Supabase — `supabase db push` (31 migrations) | 10–20 min | Automático — schema/RLS/Storage já versionados |
| Supabase — cadastrar Redirect URL | 5 min | Dashboard → Authentication → URL Configuration |
| Sentry — criar projeto de Produção | ~10 min | |
| PostHog — criar projeto de Produção | ~10 min | |
| Gerar Android Keystore (`keytool`) | 15 min | + tempo para guardar em cofre seguro |
| Cadastrar os 8 GitHub Secrets + Environment `production` | 20–30 min | Nomes já documentados em `CI_CD_SECRETS.md` |
| `DEVELOPMENT_TEAM` + certificado + provisioning profile (Xcode Automatic Signing) | 30–60 min | Após Apple Developer Program ativo |
| Redigir Política de Privacidade/Termos de Uso | **Variável — o maior gargalo** | Depende do proprietário/jurídico; pode levar de horas a semanas |
| Hospedar Política de Privacidade/Termos (página pública) | 30 min – 2h | Uma vez o texto pronto |
| Definir/configurar página e e-mail de suporte | 30 min – 2h | |
| Feature Graphic (design, 1024×500) | 1–4h | Precisa ser criado — sem asset oficial pronto |
| Screenshots (captura em dispositivo/emulador real) | 2–4h | Só após build de Produção funcional |
| Classificação indicativa (questionário) | 15–20 min | |
| Data Safety (Google) | 30–45 min | Usando o inventário já pronto |
| App Privacy (Apple) | 30–45 min | Mesmo inventário |
| Upload TestFlight — 1ª build (External Testing) | ~24h de revisão da Apple (às vezes 4–48h) | Builds seguintes da mesma versão, geralmente minutos |
| Upload Google Play Internal Testing | Minutos | Sem revisão manual do Google |

---

## 6. Decisão pendente: conta Individual ou Organização (ambas as lojas)

**Este é o item de maior impacto no cronograma e não foi decidido — precisa da sua escolha antes da Fase B.**

| | Individual | Organização |
|---|---|---|
| **Apple** | Enrollment mais rápido (24–48h típico) | Requer D-U-N-S Number (1–5 dias úteis extras se a empresa ainda não tiver um) + verificação de 1–2 semanas |
| **Google Play** | Sujeita à regra de teste fechado (12 testadores opt-in por 14 dias consecutivos) **antes de solicitar acesso à Produção**, para contas criadas após 13/11/2023 | **Isenta** dessa regra de teste fechado — pode publicar direto em Produção após a verificação |
| Requisito extra | Nenhum documento empresarial | CNPJ/documento de registro da empresa, D-U-N-S (Apple) |

**Nota importante sobre o Google Play**: a regra de 12 testadores/14 dias **não bloqueia** o Internal Testing (que continua imediato) — ela blooqueia apenas a transição de Closed Testing para **Produção**. Como a Etapa 3B do roadmap já é "TestFlight e Google Play Internal Testing" (não Produção), essa regra não atrasa a próxima etapa — mas **atrasa em pelo menos 14 dias corridos** qualquer plano de ir para Produção depois, caso a conta seja Pessoal.

Não vou decidir isso por conta própria — é uma escolha de negócio (documentação exigida, urgência, se o BORAH já tem CNPJ). Posso detalhar melhor cada caminho se você quiser decidir agora ou preferir revisitar isso na Etapa 3B.

---

## 7. O que pode ser feito gratuitamente vs. o que exige pagamento

| Gratuito | Pago |
|---|---|
| Supabase (plano free, suficiente para o volume do Beta Fechado) | **Apple Developer Program**: US$ 99/ano |
| Sentry (plano free, com limite de eventos) | **Google Play Console**: US$ 25 (taxa única, sem renovação) |
| PostHog (plano free, com limite de eventos) | Domínio próprio para página de suporte/política (se optar por um, em vez de uma página gratuita como GitHub Pages) |
| GitHub Secrets/Environments | Eventualmente, upgrade de Supabase/Sentry/PostHog para planos pagos, se o volume de uso em Produção ultrapassar os limites do free tier (não é o caso no lançamento do Beta) |
| Geração da Android Keystore (`keytool`, ferramenta livre) | Serviço de design para o Feature Graphic, se não for feito internamente |
| Bundle IDs, Redirect URLs, configuração de OAuth (não aplicável) | — |

---

## 8. O que exige validação manual (não é instantâneo)

- Verificação de identidade do Google Play Console (até 2 dias úteis).
- Aprovação do Apple Developer Program (24h a semanas, dependendo de Individual/Organização e da fila da Apple).
- Primeira build no TestFlight via External Testing (revisão da Apple, tipicamente ~24h).
- Revisão final de publicação em cada loja, quando a submissão para Produção acontecer (fora do escopo desta rodada) — App Store costuma revisar em 1–3 dias; Google Play pode variar de horas a alguns dias para contas novas.
- Closed Testing do Google Play (12 testadores/14 dias corridos), se a conta for Pessoal — não é uma "revisão", mas é um requisito de tempo mínimo que não pode ser acelerado.

---

## 9. Checklist final — autorização para gerar a primeira build

Todos os itens abaixo devem estar concluídos antes de iniciar a Etapa 3B:

- [ ] Decisão tomada: conta Individual ou Organização (Apple e Google Play).
- [ ] Apple Developer Program ativo, `DEVELOPMENT_TEAM` configurado no Xcode.
- [ ] Certificado de distribuição + Provisioning Profile gerados (Automatic Signing).
- [ ] App registrado em App Store Connect (`com.borah.app`).
- [ ] Google Play Console: conta criada, identidade verificada, app registrado (`com.borah.app`).
- [ ] Projeto Supabase de Produção criado; `supabase db push` executado; Redirect URL cadastrada.
- [ ] Projeto Sentry de Produção criado, DSN obtido.
- [ ] Projeto PostHog de Produção criado, token obtido.
- [ ] Android Keystore gerada e guardada em cofre seguro.
- [ ] 8 GitHub Secrets cadastrados no Environment `production` (4 de keystore + 4 de ambiente, ver `CI_CD_SECRETS.md` §2/§2.1).
- [ ] Política de Privacidade redigida e hospedada em URL pública ativa.
- [ ] Termos de Uso redigidos e hospedados (se aplicável ao modelo do BORAH).
- [ ] E-mail de suporte definido e funcional.
- [ ] Página/URL de suporte definida e acessível.
- [ ] Classificação indicativa preenchida (Google Play).
- [ ] Data Safety preenchido (Google Play), usando o inventário já pronto.
- [ ] App Privacy preenchido (App Store Connect), usando o mesmo inventário.
- [ ] Feature Graphic criado (1024×500).
- [ ] Screenshots capturados (quantidade mínima exigida por cada loja).

Só depois de marcar todos os itens acima faz sentido autorizar a geração da primeira build (Etapa 3B).

---

## 10. Estimativa total para concluir todo o provisionamento

| Cenário | Estimativa |
|---|---|
| **Melhor caso** — contas Individual, texto jurídico já pronto, sem atrasos de revisão | ~5–7 dias úteis |
| **Caso realista** — pequenos atrasos de verificação, texto jurídico levando alguns dias | ~10–15 dias úteis |
| **Caso com conta Organização e/ou atrasos de revisão da Apple** | ~3–5 semanas |

O maior fator de incerteza não é técnico: é o tempo para redigir e aprovar a Política de Privacidade/Termos de Uso, e a velocidade de verificação das duas lojas (fora do nosso controle).

---

## 11. Riscos e bloqueadores

1. **Política de Privacidade/Termos de Uso inexistentes** — bloqueador direto de submissão nas duas lojas (não apenas do Data Safety/App Privacy). Já registrado na BETA-03; reafirmado aqui como o item de maior risco ao cronograma.
2. **Decisão Individual vs. Organização não tomada** — afeta diretamente o tempo de enrollment da Apple e se o Google Play exigirá o ciclo de Closed Testing de 14 dias antes da Produção (§6).
3. **Nenhuma página/e-mail de suporte definidos** — bloqueador de submissão em ambas as lojas, mas rápido de resolver uma vez decidido.
4. **Feature Graphic e Screenshots** — dependem de uma cadeia de pré-requisitos (contas + Supabase de Produção + secrets) antes de poderem ser produzidos; não é possível adiantar esse item isoladamente.
5. **Filas de revisão da Apple** — pesquisas desta data confirmam relatos de atrasos além dos prazos históricos em 2026, tanto para enrollment quanto para TestFlight External Testing; o cronograma da Fase B/E deve reservar folga.

---

## 12. O que **não** foi feito nesta rodada (conforme instruído)

- Nenhum código, workflow de CI/CD ou secret foi alterado.
- Nenhum certificado, keystore ou credencial foi gerado ou simulado.
- Nenhum texto de Política de Privacidade/Termos de Uso foi redigido (decisão jurídica do proprietário — posso ajudar a redigir numa rodada futura, mediante as informações necessárias).
- Nenhuma build foi gerada; nenhuma publicação foi realizada.

---

## 13. Validação

Nenhuma alteração de código foi necessária nesta rodada — apenas este documento foi criado. `flutter analyze`/`dart format`/`flutter test` não foram executados por não haver nenhuma mudança em `app/` a validar.

## 14. Arquivo criado

- `docs/FASE 9 - Execution/BETA-04_PROVISIONING_OPERATIONAL_PLAN.md` (este documento)

---

## 15. Fontes consultadas (verificação de políticas atuais das lojas)

- [Apple Developer Fee 2026 — Cost, Renewal, VAT & Refund FAQ](https://magora-systems.com/apple-developer-fee/)
- [Apple Developer Program](https://developer.apple.com/programs/)
- [Google Play Developer Fee 2026: $25 + 12-Tester Rule](https://www.iconikai.com/blog/google-play-developer-account-fee-2026)
- [App testing requirements for new personal developer accounts — Play Console Help](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- [Internal vs Closed vs Open Testing on Google Play (2026)](https://primetestlab.com/blog/google-play-internal-vs-closed-vs-open-testing)
- [Verify your developer identity information — Play Console Help](https://support.google.com/googleplay/android-developer/answer/10841920?hl=en)
- [D-U-N-S® Number — Membership — Apple Developer Help](https://developer.apple.com/help/account/membership/D-U-N-S)
- [TestFlight Distribution Guide: Internal Testers, External Groups, and Review](https://techconcepts.org/blog/testflight-guide)
