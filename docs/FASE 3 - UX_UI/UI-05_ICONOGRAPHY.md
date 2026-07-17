# UI-05 — Iconography

**Versão:** 1.0  
**Status:** Draft  
**Documento:** UI-05_ICONOGRAPHY.md

---

# 1. Objetivo

Definir o sistema de iconografia do BORAH, estabelecendo padrões para seleção, criação e utilização de ícones em toda a interface, garantindo consistência visual, legibilidade e acessibilidade.

---

# 2. Princípios

A iconografia deve ser:

- Simples
- Reconhecível
- Consistente
- Escalável
- Acessível

Os ícones devem complementar o texto e nunca substituí-lo quando a compreensão depender exclusivamente da imagem.

---

# 3. Biblioteca de Ícones

Biblioteca recomendada:

- Material Symbols
- Material Icons Outlined

Futuramente, o BORAH poderá possuir um conjunto de ícones proprietários para reforçar a identidade visual.

---

# 4. Estilo Visual

Todos os ícones devem seguir o mesmo estilo:

- Contorno (Outlined) como padrão
- Cantos arredondados
- Traço consistente
- Proporções uniformes
- Aparência moderna

Misturar estilos (filled, outlined, sharp, rounded) na mesma tela deve ser evitado.

---

# 5. Categorias

## Navegação
- Home
- Pesquisa
- Ranking
- Perfil
- Configurações

## Social
- Grupo
- Amigos
- Convite
- Feed
- Comentários
- Curtidas
- Compartilhar

## Restaurantes
- Restaurante
- Localização
- Favorito
- Avaliação
- Menu
- Horário

## Eventos
- Calendário
- Check-in
- Participantes
- Confirmação

## Gamificação
- XP
- Badge
- Troféu
- Medalha
- Estrela
- Conquista

## Sistema
- Notificação
- Segurança
- Ajuda
- Erro
- Sucesso
- Informação
- Alerta

---

# 6. Tamanhos

Escala recomendada:

- XS: 16 px
- SM: 20 px
- MD: 24 px (padrão)
- LG: 32 px
- XL: 48 px

---

# 7. Cores

Os ícones devem utilizar tokens de cor do Design System.

Categorias:

- Primary
- Secondary
- Disabled
- Success
- Warning
- Error
- Inverse

Não utilizar cores fixas diretamente.

---

# 8. Estados

Todos os ícones interativos devem prever:

- Default
- Hover
- Focus
- Pressed
- Disabled
- Selected

---

# 9. Acessibilidade

- Ícones clicáveis devem possuir área mínima de 48 x 48 px.
- Fornecer descrição acessível (semantics/aria-label).
- Não depender apenas da cor para indicar estado.

---

# 10. Implementação

## Flutter

- Centralizar os ícones em um arquivo de constantes.
- Evitar códigos duplicados.
- Utilizar `IconTheme` sempre que possível.

Estrutura sugerida:

lib/
  design_system/
    icons/
      app_icons.dart

---

# 11. Organização no Figma

Criar páginas para:

- Navigation
- Social
- Restaurants
- Events
- Gamification
- System

Todos os ícones devem utilizar Components e Variants.

---

# 12. Uso Correto

Boas práticas:

- Utilizar texto junto aos ícones em ações importantes.
- Manter espaçamento consistente.
- Utilizar o mesmo ícone para a mesma ação em todo o aplicativo.

Evitar:

- Ícones decorativos sem função.
- Mistura de estilos.
- Ícones excessivamente complexos.

---

# 13. Governança

Novos ícones deverão:

- Seguir o estilo oficial.
- Ser documentados.
- Ser adicionados ao Figma.
- Ser adicionados ao Flutter.
- Passar por revisão de UX/UI.

---

# 14. Critérios de Aceite

- Biblioteca definida.
- Estilo padronizado.
- Categorias organizadas.
- Tamanhos documentados.
- Acessibilidade considerada.
- Compatibilidade com o Design System.

---

# 15. Checklist

- Biblioteca escolhida.
- Categorias documentadas.
- Tamanhos definidos.
- Estados previstos.
- Regras de acessibilidade registradas.
- Organização no Flutter definida.
- Organização no Figma definida.
