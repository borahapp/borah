# UX-01 — Fluxo do Aplicativo

**Versão:** 1.0  
**Status:** Draft  
**Documento:** UX-01_APP_FLOW.md

---

# 1. Objetivo

Documentar todos os fluxos de navegação do BORAH, descrevendo a jornada do usuário desde o primeiro acesso até as principais funcionalidades do aplicativo. Este documento serve como referência para UX, UI, desenvolvimento e testes.

---

# 2. Princípios

Os fluxos devem seguir os princípios definidos em **UX-00**:

- Máximo de simplicidade
- Poucos passos para concluir tarefas
- Navegação previsível
- Feedback imediato
- Recuperação fácil de erros

---

# 3. Mapa Geral do Aplicativo

```text
Splash
  │
  ▼
Onboarding (1º acesso)
  │
  ▼
Login / Cadastro
  │
  ▼
Completar Perfil
  │
  ▼
Home
 ├── Pesquisa
 ├── Grupos
 │     └── Evento
 │            └── Restaurante
 │                   └── Check-in
 │                          └── Avaliação
 ├── Ranking
 ├── Feed
 ├── Notificações
 ├── Perfil
 └── Configurações
```

---

# 4. Fluxo de Autenticação

1. Splash
2. Verificação de sessão
3. Login ou Cadastro
4. Validação
5. Completar perfil (primeiro acesso)
6. Home

### Fluxos alternativos

- Recuperar senha
- Login com Google
- Login com Apple
- Sessão expirada

---

# 5. Fluxo Home

A Home é o ponto central do aplicativo.

A partir dela o usuário poderá:

- Ver próximos eventos
- Acessar grupos
- Buscar restaurantes
- Consultar ranking
- Abrir notificações
- Acessar o perfil

---

# 6. Fluxo de Grupos

Criar grupo:

Home → Grupos → Criar Grupo → Convidar Amigos → Grupo Criado

Entrar em grupo:

Convite → Aceitar → Grupo

Gerenciar grupo:

Grupo → Configurações → Alterações

---

# 7. Fluxo de Eventos

Grupo → Criar Evento → Selecionar Restaurante → Definir Data/Hora → Convidar Participantes → Evento Criado

No dia do evento:

Evento → Check-in → Avaliação → Ranking Atualizado

---

# 8. Fluxo de Pesquisa

Home → Pesquisa

O usuário poderá:

- Buscar restaurantes
- Filtrar resultados
- Visualizar detalhes
- Favoritar
- Compartilhar
- Criar evento

---

# 9. Fluxo do Restaurante

Pesquisa → Restaurante

Ações disponíveis:

- Fotos
- Informações
- Localização
- Avaliações
- Favoritar
- Adicionar ao evento

---

# 10. Fluxo de Avaliação

Evento Finalizado → Avaliar Restaurante

Critérios:

- Comida
- Atendimento
- Ambiente
- Custo-benefício
- Limpeza
- Música
- Retornaria

Após concluir:

- XP atualizado
- Badge (quando aplicável)
- Ranking recalculado

---

# 11. Fluxo do Ranking

Home → Ranking

Visualizações:

- Grupo
- Temporada
- Geral

Detalhes:

- XP
- Posição
- Badges
- Evolução

---

# 12. Fluxo do Perfil

Perfil

- Estatísticas
- Histórico
- Badges
- Favoritos
- Configurações

---

# 13. Fluxo de Configurações

Perfil → Configurações

Permite:

- Editar perfil
- Alterar foto
- Preferências
- Notificações
- Privacidade
- Segurança
- Sair da conta

---

# 14. Fluxos de Exceção

Prever tratamento para:

- Sem internet
- Erro de autenticação
- Restaurante não encontrado
- Convite expirado
- Evento cancelado
- Sessão expirada
- Erro interno

Todos os fluxos devem apresentar mensagem clara e opção de recuperação.

---

# 15. Deep Links

Links suportados futuramente:

- Convite para grupo
- Convite para evento
- Perfil público
- Restaurante
- Ranking compartilhado

---

# 16. Métricas de Navegação

Monitorar:

- Tempo para criar evento
- Tempo até o primeiro check-in
- Conversão do onboarding
- Abandono de cadastro
- Uso da pesquisa
- Frequência de retorno

---

# 17. Critérios de Aceite

- Todos os fluxos documentados
- Fluxos alternativos definidos
- Fluxos de erro previstos
- Navegação consistente
- Integração com UX-00

---

# 18. Checklist

- Fluxo principal validado
- Fluxos alternativos documentados
- Estados de erro definidos
- Deep links previstos
- Métricas identificadas
