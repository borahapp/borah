# UX-02 — Wireframes

**Versão:** 1.0  
**Status:** Draft  
**Documento:** UX-02_WIREFRAMES.md

---

# 1. Objetivo

Documentar a estrutura de baixa fidelidade (wireframes) de todas as telas do BORAH. Este documento define a organização dos elementos da interface, os componentes utilizados, as ações do usuário e os estados de cada tela, servindo como base para o Design System e para o protótipo de alta fidelidade.

---

# 2. Padrão de Documentação

Cada tela deve conter:

- Objetivo
- Wireframe (baixa fidelidade)
- Componentes
- Ações do usuário
- Estados da interface
- Navegação
- Eventos de analytics
- Critérios de aceite

---

# 3. Splash

**Objetivo:** carregar o aplicativo e validar a sessão.

```text
+----------------------+
|                      |
|        LOGO          |
|                      |
|     Carregando...    |
|                      |
+----------------------+
```

Componentes:
- Logo
- Indicador de carregamento

---

# 4. Onboarding

Objetivo: apresentar a proposta do BORAH.

```text
+----------------------+
|      Ilustração      |
|                      |
|  Título              |
|  Descrição           |
|                      |
| ● ○ ○                |
| [Próximo]            |
+----------------------+
```

---

# 5. Login

```text
+----------------------+
| Logo                 |
| E-mail               |
| Senha                |
| [Entrar]             |
| Google | Apple       |
| Criar conta          |
+----------------------+
```

Componentes:
- Campos
- Botões
- Login social

---

# 6. Cadastro

Campos:

- Nome
- Usuário
- E-mail
- Senha
- Confirmar senha

Ações:
- Criar conta
- Voltar

---

# 7. Home

```text
+----------------------+
| Buscar...            |
| Próximos eventos     |
| Meus grupos          |
| Ranking              |
| Feed                 |
|                      |
| Home Pesq Rank Perfil|
+----------------------+
```

Componentes:
- Barra de pesquisa
- Cards
- Bottom Navigation

---

# 8. Pesquisa

Componentes:
- Campo de busca
- Filtros
- Lista de restaurantes
- Mapa (futuro)

Estados:
- Resultado encontrado
- Nenhum resultado

---

# 9. Restaurante

Conteúdo:

- Fotos
- Nome
- Categoria
- Endereço
- Nota
- Avaliações
- Favoritar
- Adicionar ao evento

---

# 10. Grupo

Componentes:

- Cabeçalho
- Integrantes
- Próximo evento
- Ranking do grupo
- Histórico

Ações:
- Criar evento
- Convidar amigos

---

# 11. Evento

Componentes:

- Restaurante
- Data
- Hora
- Participantes
- Check-in
- Avaliação

Estados:
- Agendado
- Em andamento
- Finalizado
- Cancelado

---

# 12. Ranking

Visualizações:

- Geral
- Grupo
- Temporada

Componentes:
- Lista ordenada
- XP
- Badges
- Evolução

---

# 13. Feed

Conteúdo:

- Publicações
- Fotos
- Curtidas
- Comentários
- Compartilhar

---

# 14. Perfil

Componentes:

- Avatar
- Nome
- Nível
- XP
- Badges
- Estatísticas
- Histórico

---

# 15. Configurações

Itens:

- Editar perfil
- Notificações
- Privacidade
- Segurança
- Idioma (futuro)
- Sair

---

# 16. Notificações

Tipos:

- Convites
- Eventos
- Ranking
- Badges
- Sistema

Estados:
- Lida
- Não lida

---

# 17. Estados Globais

Todas as telas devem prever:

- Loading
- Empty State
- Erro
- Offline
- Sucesso

---

# 18. Navegação

Bottom Navigation:

- Home
- Pesquisa
- Ranking
- Perfil

Acesso contextual para:

- Grupos
- Eventos
- Restaurante
- Feed
- Configurações

---

# 19. Analytics

Registrar eventos como:

- Login realizado
- Cadastro concluído
- Evento criado
- Restaurante visualizado
- Check-in
- Avaliação enviada
- Badge conquistada

---

# 20. Critérios de Aceite

- Todas as telas documentadas
- Componentes identificados
- Navegação definida
- Estados previstos
- Compatibilidade com UX-00 e UX-01

---

# 21. Checklist

- Estrutura das telas validada
- Fluxos compatíveis
- Componentes mapeados
- Estados documentados
- Analytics definidos
