# BORAH — Branding Oficial para as Lojas

**Contexto:** BETA-10E. Base para todo o conteúdo de `google_play_listing.md`, `app_store_listing.md`, `screenshots.md`, `app_preview.md` e `faq.md`. Grounded exclusivamente no que o BORAH já faz hoje (avaliações, rankings, gamificação, feed social) — nenhuma funcionalidade inexistente foi mencionada.

---

## Nome exibido do aplicativo

**BORAH**

## Nome curto

**BORAH** (o nome já é curto — nenhuma abreviação adicional necessária)

## Tagline

**"Todo grupo tem seus rolês. Agora eles têm um ranking."**

(Já oficial — definida no pacote de identidade visual, `identidade visual-borah/.../CLAUDE.md`, seção "Produto". Reutilizada aqui, não recriada.)

## Proposta de valor

O BORAH resolve a eterna discussão "pra onde a gente vai hoje?": crie um grupo fechado com seus amigos, organizem rolês juntos, confirmem presença e avaliem cada lugar coletivamente — uma nota só, construída pelo grupo, não uma bagunça de opiniões soltas. Cada avaliação alimenta o Ranking do Grupo, as Estatísticas e as Memórias — um histórico vivo de tudo que vocês já viveram juntos.

## Elevator Pitch (~30 segundos)

> "Todo grupo de amigos já teve aquela discussão sem fim sobre onde ir. O BORAH resolve isso: cria um grupo fechado com seus amigos (por convite, só quem você chamar entra), organiza o rolê, todo mundo confirma presença, e depois vocês avaliam o lugar juntos — uma nota do grupo, não uma bagunça de notas soltas. Isso alimenta o Ranking do Grupo, as Estatísticas e as Memórias do que vocês já viveram. Chega de esquecer qual foi aquele lugar bom — o BORAH lembra por vocês, e transforma isso em ranking."

---

## Funcionalidades reais usadas como base de todo o conteúdo de loja

Reconfirmadas contra `app/lib/core/router/app_router.dart` nesta rodada (RC-02C) — nada abaixo é aspiracional. **Grupos/Rolês são o núcleo do app hoje** (tela inicial, desde a substituição do Feed na barra principal); Feed/avaliação individual/seguir continuam existindo, mas como camada secundária:

- Grupos fechados, criados e administrados pelo próprio usuário (promover, remover, sair, editar)
- Entrar em um grupo por código de convite
- Criar um rolê dentro do grupo (local, data), editar, cancelar, ver histórico
- Confirmar presença em um rolê
- Avaliação Coletiva — o grupo constrói **uma** nota e resenha do rolê, junto, não avaliações individuais soltas
- Ranking do Grupo — quem mais participa, melhores lugares do grupo
- Estatísticas (do grupo, do usuário, de restaurantes, de rolês)
- Memórias — linha do tempo, fotos, "campeões", resumo anual do grupo
- Notificações essenciais (convite, novo rolê, confirmação, avaliação liberada)
- Cadastro e perfil (nome, bio, cidade, foto)
- Cadastro colaborativo de restaurantes/lugares
- Avaliações individuais com nota (1 a 5), comentário e até 5 fotos, fora do contexto de grupo
- Comentários e curtidas em avaliações, seguir outros usuários, feed de atividade
- Favoritos
- Ranking de restaurantes e de usuários (gamificação — XP, pontos, nível, conquistas/badges)
- Denúncia e moderação de conteúdo impróprio
- Exclusão de conta pelo próprio usuário (LGPD)

## O que **não** existe hoje (não mencionar em nenhum texto de loja)

- Login social (Google/Facebook/Apple) — só e-mail/senha
- Notificações push — só notificações dentro do app
- Chat/mensagens diretas entre usuários
- Reservas ou integração com delivery
- Suporte a múltiplos idiomas além do português
