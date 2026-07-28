# Plano de Lançamento — BORAH

**Contexto:** BETA-11A. Plano de execução em 4 fases, a partir do estado atual (toda a documentação de preparação concluída, nenhuma execução operacional ainda realizada).

---

## Fase 1 — Preparação Final

### Objetivos
Eliminar toda incerteza técnica restante e criar as contas/projetos externos necessários.

### Pré-requisitos
- Decisão do proprietário: contas Individual ou Organização (Google Play e Apple).
- Acesso a um Mac/Xcode (para a validação iOS).

### Entregáveis
- Keystore Android real gerada e em cofre seguro.
- Contas Google Play Console e Apple Developer Program criadas e verificadas.
- Projetos Sentry e PostHog de Produção criados.
- 9 secrets de Produção cadastrados no GitHub (Environment `production` criado).
- Build iOS validada com sucesso pela primeira vez (Archive gerado no Xcode).
- Privacy Manifest validado no Xcode e promovido de `docs/apple/` de volta a `app/ios/Runner/`.
- Domínio `appborah.com.br` com DNS configurado e site institucional publicado (Política de Privacidade/Termos/Suporte acessíveis publicamente).

### Critérios de saída
Todos os itens das categorias "Aplicativo", "Backend", "Infraestrutura", "Segurança", "Site" e "Jurídico" do `go_no_go_review.md` marcados ✅.

### Riscos
- Build iOS pode revelar problemas nunca antes vistos (nenhuma tentativa real ocorreu até hoje).
- Tempo de verificação de identidade das contas (Google Play até 2 dias; Apple 24h a semanas) pode ser o fator limitante do cronograma desta fase.
- Revisão jurídica por advogado pode exigir ajustes no conteúdo já redigido.

---

## Fase 2 — Publicação nas Lojas

### Objetivos
Submeter o BORAH às faixas de teste de ambas as lojas.

### Pré-requisitos
- Fase 1 100% concluída.
- Assets visuais reais produzidos (screenshots, Feature Graphic, App Preview — BETA-11B).

### Entregáveis
- Ficha da loja completa em ambos os consoles (descrições, categoria, Data Safety/App Privacy, classificação indicativa).
- AAB assinado com a keystore real, enviado ao Google Play Internal Testing.
- Build iOS enviada ao TestFlight.

### Critérios de saída
- Build disponível para instalação via Internal Testing (Google Play) e TestFlight (Apple), confirmado por instalação real em pelo menos um dispositivo de cada plataforma.

### Riscos
- Rejeição na revisão da Apple (TestFlight External Testing exige revisão da primeira build, ~24h, às vezes mais).
- Inconsistência entre Data Safety/App Privacy e a Política de Privacidade pode gerar solicitação de correção por qualquer uma das lojas.

---

## Fase 3 — Closed Beta

### Objetivos
Validar o BORAH com usuários reais, fora da equipe de desenvolvimento.

### Pré-requisitos
- Fase 2 concluída — builds instaláveis via Internal Testing/TestFlight.
- Lista de testadores convidados definida (conforme `docs/FASE 9 - Execution/` — plano operacional do Beta já existente de rodadas anteriores).

### Entregáveis
- Convites enviados aos testadores.
- Canal de coleta de feedback ativo (já existe infraestrutura de feedback in-app, RC-03E).
- Monitoramento ativo do Sentry/PostHog durante o período de teste.

### Critérios de saída
- Ao menos um ciclo completo de uso real (cadastro → avaliação → interação social) confirmado por um testador externo, sem erro crítico reportado.

### Riscos
- Erros só visíveis com dados/uso reais (mesmo com toda a auditoria estática já feita).
- Volume de feedback pode exigir priorização rápida de correções.

---

## Fase 4 — Pós-lançamento

### Objetivos
Consolidar aprendizados do Beta Fechado e decidir os próximos passos (expansão do Beta, lançamento público, ou nova rodada de correções).

### Pré-requisitos
- Fase 3 concluída, feedback coletado e analisado.

### Entregáveis
- Relatório de resultados do Beta Fechado (métricas de uso via PostHog, taxa de erro via Sentry, feedback qualitativo).
- Backlog priorizado de correções/melhorias identificadas.
- Decisão formal sobre os próximos passos (expandir o Beta, abrir ao público, ou pausar para ajustes).

### Critérios de saída
Decisão documentada e aprovada pelo proprietário sobre a próxima macroetapa do projeto.

### Riscos
- Sem um critério objetivo definido previamente para "sucesso do Beta", a decisão pode ficar subjetiva — recomenda-se definir essas métricas antes do início da Fase 3, não depois.
