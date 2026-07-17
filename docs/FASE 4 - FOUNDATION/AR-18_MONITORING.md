# AR-18 --- Monitoring

**Versão:** 2.0\
**Status:** Recommended\
**Documento:** `AR-18_MONITORING.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a estratégia de monitoramento operacional do BORAH para garantir
alta disponibilidade, desempenho, confiabilidade e resposta rápida a
incidentes em produção.

------------------------------------------------------------------------

# 2. Objetivos

-   Monitorar continuamente os serviços
-   Detectar falhas precocemente
-   Reduzir indisponibilidade
-   Apoiar decisões operacionais
-   Garantir cumprimento dos níveis de serviço

------------------------------------------------------------------------

# 3. Escopo

Abrange:

-   Aplicativo Flutter
-   APIs
-   Edge Functions
-   PostgreSQL
-   Supabase Storage
-   Autenticação
-   Infraestrutura
-   CI/CD

------------------------------------------------------------------------

# 4. Arquitetura de Monitoramento

``` text
Flutter
   │
   ▼
APIs / Edge Functions
   │
   ▼
Banco / Storage
   │
   ▼
Logs • Métricas • Traces
   │
   ▼
Dashboards
   │
   ▼
Alertas
   │
   ▼
Equipe de Operação
```

------------------------------------------------------------------------

# 5. Indicadores (SLIs)

Monitorar, no mínimo:

-   Disponibilidade
-   Latência
-   Taxa de erro
-   Throughput
-   Uso de CPU
-   Uso de memória
-   Espaço em Storage
-   Tempo de resposta do banco

------------------------------------------------------------------------

# 6. Objetivos (SLOs)

Metas iniciais:

  Indicador             Meta
  --------------------- ----------
  Disponibilidade       ≥ 99,9%
  Latência API (P95)    ≤ 300 ms
  Taxa de erro          ≤ 1%
  Sucesso dos Deploys   ≥ 95%

------------------------------------------------------------------------

# 7. SLA

Referência operacional:

-   Alta disponibilidade
-   Recuperação conforme RTO definido
-   Comunicação de incidentes críticos

------------------------------------------------------------------------

# 8. Dashboards

Criar painéis para:

-   Aplicação
-   APIs
-   Banco de dados
-   Storage
-   Edge Functions
-   Autenticação
-   CI/CD

------------------------------------------------------------------------

# 9. Alertas

Classificação:

-   Informativo
-   Aviso
-   Crítico

Exemplos:

-   API indisponível
-   Erro elevado
-   Falha em Edge Function
-   Banco indisponível
-   Uso excessivo de recursos

------------------------------------------------------------------------

# 10. Gestão de Incidentes

Fluxo:

1.  Detectar
2.  Classificar
3.  Notificar
4.  Mitigar
5.  Recuperar
6.  Registrar lições aprendidas

------------------------------------------------------------------------

# 11. On-call

Definir escala para:

-   Incidentes críticos
-   Falhas de produção
-   Recuperação emergencial

Registrar todas as intervenções.

------------------------------------------------------------------------

# 12. Runbooks

Cada serviço crítico deverá possuir um runbook contendo:

-   Sintomas
-   Diagnóstico
-   Ações imediatas
-   Procedimento de recuperação
-   Critérios de encerramento

------------------------------------------------------------------------

# 13. Capacity Planning

Acompanhar:

-   Crescimento do banco
-   Crescimento do Storage
-   Consumo de APIs
-   Usuários ativos
-   Custos da infraestrutura

------------------------------------------------------------------------

# 14. Status Page

Disponibilizar página de status contendo:

-   Estado dos serviços
-   Histórico de incidentes
-   Manutenções programadas

------------------------------------------------------------------------

# 15. Ferramentas

Sugestões:

-   Supabase Dashboard
-   Grafana
-   Sentry
-   Firebase Crashlytics
-   GitHub Actions

------------------------------------------------------------------------

# 16. Segurança

-   Controle de acesso aos dashboards
-   Logs mascarados
-   Auditoria das alterações
-   Retenção conforme política

------------------------------------------------------------------------

# 17. Boas Práticas

-   Alertas acionáveis
-   Dashboards objetivos
-   Revisão periódica dos SLOs
-   Testes de alertas
-   Monitoramento contínuo

------------------------------------------------------------------------

# 18. Anti-patterns

Evitar:

-   Alertas em excesso
-   Monitorar métricas sem uso
-   Ausência de runbooks
-   Falta de revisão dos indicadores
-   Dependência exclusiva de monitoramento manual

------------------------------------------------------------------------

# 19. Critérios de Aceite

-   Indicadores definidos
-   Dashboards planejados
-   Alertas configuráveis
-   Processo de incidentes documentado
-   Runbooks previstos

------------------------------------------------------------------------

# 20. Checklist

-   SLIs definidos
-   SLOs definidos
-   SLA documentado
-   Dashboards previstos
-   Alertas classificados
-   On-call definido
-   Runbooks previstos
-   Capacity Planning documentado

------------------------------------------------------------------------

# Evolução prevista (Versão 3.0)

Adicionar:

-   Diagramas Mermaid do fluxo de monitoramento.
-   Catálogo completo de métricas por serviço.
-   Estratégia de monitoramento sintético.
-   Métricas DORA.
-   Integração com Status Page automatizada.
-   Processo formal de Postmortem (RCA).
-   Dashboards executivos e operacionais separados.
-   Automação para abertura de incidentes e escalonamento.
