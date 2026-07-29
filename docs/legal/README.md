# Documentação Jurídica do BORAH

**Contexto:** BETA-09A (auditoria de conformidade) / BETA-09B/BETA-09B1 (redação e revisão). Esta pasta reúne a primeira versão oficial da documentação jurídica do BORAH, produzida a partir da auditoria completa da arquitetura do aplicativo (autenticação, banco de dados, uploads, analytics, observabilidade, permissões e integrações externas) e das informações de negócio fornecidas pelo responsável pelo aplicativo.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `privacy_policy.md` | Política de Privacidade — quais dados o BORAH coleta, finalidade de cada um, onde são armazenados, quais terceiros os processam (Supabase, Sentry, PostHog), transferência internacional, retenção, exclusão de conta e direitos do titular (LGPD) |
| `terms_of_use.md` | Termos de Uso — objeto do serviço, regras de cadastro e utilização, conteúdo publicado pelos usuários, moderação, suspensão/encerramento de contas, propriedade intelectual e foro |
| `support.md` | Página de Suporte — apresentação, contato, perguntas frequentes, solicitação de exclusão de conta e contato para assuntos de privacidade |

## Fidelidade à arquitetura real

Todo o conteúdo destes documentos reflete exatamente o que o BORAH faz hoje, conforme auditado na BETA-09A — nenhuma funcionalidade inexistente foi descrita, e nenhum tratamento de dado que o aplicativo não realiza foi mencionado. Sempre que o app não tem um mecanismo técnico correspondente a uma cláusula (ex.: a idade mínima do Beta Fechado não é verificada tecnicamente no cadastro), isso está registrado como uma limitação conhecida nos relatórios de auditoria (`docs/FASE 9 - Execution/BETA-09A_*` e o histórico de revisão da BETA-09B/BETA-09B1), não escondido do texto público.

## Idade mínima (Beta Fechado)

A idade mínima vigente é **18 anos**, uma decisão específica para o período de Beta Fechado (registrada na BETA-09B1) — reduz a exposição jurídica enquanto o aplicativo não possui nenhum mecanismo técnico de verificação de idade. Essa restrição pode ser revista em fases futuras do produto.

## Publicação

Estes documentos ainda **não estão hospedados publicamente**. Quando a infraestrutura de hospedagem do domínio oficial estiver disponível, devem ser publicados em:

- `privacy_policy.md` → https://www.appborah.com.br/privacidade
- `terms_of_use.md` → https://www.appborah.com.br/termos
- `support.md` → https://www.appborah.com.br/suporte

Nenhuma infraestrutura de site/hospedagem existe neste repositório hoje — a publicação nessas URLs depende de um projeto de hospedagem à parte, ainda não iniciado.

## Revisão jurídica pendente

Conforme registrado no relatório da BETA-09B, os seguintes pontos ainda devem ser revisados por um advogado antes da publicação definitiva:

1. Cláusula de idade mínima sem verificação técnica correspondente.
2. Linguagem de transferência internacional de dados (Sentry/PostHog) e a necessidade de formalizar os DPAs desses fornecedores.
3. Cláusula de suspensão de conta, redigida como direito contratual geral na ausência de um mecanismo técnico de "suspensão" no aplicativo.
4. Prazo de retenção de logs técnicos (180 dias).
5. Ausência de um mecanismo automatizado de portabilidade de dados (hoje, só por solicitação manual via e-mail).
