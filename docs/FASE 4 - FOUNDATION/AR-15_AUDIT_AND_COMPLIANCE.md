
# AR-15 — Audit & Compliance

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-15_AUDIT_AND_COMPLIANCE.md

---

# 1. Objetivo

Definir a estratégia de auditoria e conformidade do BORAH para garantir rastreabilidade das ações, governança dos dados, atendimento aos requisitos legais e suporte à investigação de incidentes.

---

# 2. Objetivos

- Garantir rastreabilidade
- Apoiar investigações
- Atender requisitos regulatórios
- Fortalecer a segurança
- Promover governança

---

# 3. Escopo

Abrange:

- Banco de dados
- Edge Functions
- APIs
- Autenticação
- Storage
- Painéis administrativos
- Infraestrutura crítica

---

# 4. Princípios

- Auditoria por padrão
- Integridade dos registros
- Menor privilégio
- Imutabilidade quando aplicável
- Transparência
- Retenção controlada

---

# 5. Eventos Auditáveis

Registrar, no mínimo:

- Login e logout
- Criação, atualização e exclusão de dados
- Alterações de permissões
- Alterações de políticas RLS
- Execução de Edge Functions administrativas
- Falhas de autenticação
- Operações críticas

---

# 6. Conteúdo dos Registros

Cada evento deve conter:

- Timestamp
- Usuário
- Papel (Role)
- Recurso afetado
- Operação
- Resultado
- Trace ID
- Endereço IP (quando disponível)

Nunca registrar senhas, tokens ou informações sensíveis em texto puro.

---

# 7. Retenção

Recomendação inicial:

| Tipo | Retenção |
|------|----------:|
| Auditoria operacional | 12 meses |
| Segurança | 24 meses |
| Incidentes | Conforme exigência legal e política interna |

---

# 8. Controle de Acesso

Os registros de auditoria deverão:

- Possuir acesso restrito
- Ser protegidos contra alterações indevidas
- Permitir consulta apenas por perfis autorizados

---

# 9. Conformidade (LGPD)

A solução deve considerar:

- Minimização de dados
- Finalidade do tratamento
- Controle de acesso
- Exclusão quando aplicável
- Registro de operações relevantes

---

# 10. Gestão de Incidentes

Em caso de incidente:

1. Identificar o evento.
2. Preservar evidências.
3. Registrar ações executadas.
4. Avaliar impacto.
5. Aplicar correções.
6. Produzir relatório pós-incidente.

---

# 11. Revisões Periódicas

Realizar revisões para:

- Permissões administrativas
- Políticas de segurança
- Logs de auditoria
- Controles de acesso
- Conformidade documental

---

# 12. Monitoramento

Monitorar:

- Tentativas de acesso indevido
- Alterações administrativas
- Falhas recorrentes
- Atividades suspeitas
- Eventos críticos

---

# 13. Evidências

Manter evidências de:

- Revisões
- Testes
- Incidentes
- Recuperações
- Alterações relevantes

---

# 14. Boas Práticas

- Padronizar eventos
- Utilizar logs estruturados
- Revisar permissões periodicamente
- Automatizar auditorias quando possível
- Documentar exceções

---

# 15. Anti-patterns

Evitar:

- Logs incompletos
- Exclusão não autorizada de registros
- Dados sensíveis em auditorias
- Acesso amplo aos logs
- Ausência de revisão periódica

---

# 16. Critérios de Aceite

- Eventos auditáveis definidos
- Política de retenção documentada
- Controles de acesso estabelecidos
- Conformidade considerada
- Processo de incidentes documentado

---

# 17. Checklist

- Escopo definido
- Eventos documentados
- Retenção definida
- LGPD considerada
- Gestão de incidentes documentada
- Evidências previstas
- Revisões periódicas planejadas
- Boas práticas registradas
