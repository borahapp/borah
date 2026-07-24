# Assets oficiais BORAH — organização

Estrutura criada na UI-03B para receber os assets oficiais da marca (pacotes `BORAH_Sistema_Animacoes_Oficial.zip` e `BORAH_Biblioteca_Visual_Oficial.zip`), com separação por categoria. Nem todo arquivo dos pacotes originais entra aqui — a maior parte é material de marketing/redes sociais (bumpers de vídeo, encerramento de Reels, patterns e molduras para posts, selos/medalhas/stickers para Instagram) sem uso dentro do app e por isso deliberadamente **não foi incluída**.

## Estrutura

```
assets/
  branding/        reservado — nenhum asset de marca (logo/wordmark) aprovado para uso in-app ainda
  loading/
    borah_loading.webp   loop oficial de loading (512x512, transparente, animado) — em uso (LoadingScreen)
    borah_loading.gif    mesma animação, formato alternativo — organizado aqui, não incluído no bundle
  icons/
    borah_location.png   ícone oficial de localização (1024x1024) — em uso (telas de restaurante)
    borah_location.svg   fonte vetorial do mesmo ícone — organizado aqui, não incluído no bundle
  illustrations/   reservado — nenhuma ilustração aprovada para uso in-app ainda
  fonts/           já existente desde o UI-01 (Fredoka/Manrope)
```

`branding/` e `illustrations/` existem como categorias reservadas (nomenclatura definida nesta rodada) para quando algum asset dessas famílias for aprovado — não foram populadas nesta rodada porque nenhum item aprovado se encaixa nelas.

## O que está no `pubspec.yaml` e por quê

Só os arquivos efetivamente consumidos por um widget entram na lista `assets:` (o que é declarado ali é o que vai para o binário do app):

- `assets/loading/borah_loading.webp` — usado por `LoadingScreen` (`lib/design_system/components/feedback/loading_indicator.dart`).
- `assets/icons/borah_location.png` — usado nas telas de restaurante (busca, favoritos, detalhes).

`borah_loading.gif` e `borah_location.svg` ficam fisicamente organizados aqui (para manter os dois formatos oficiais juntos, documentados e rastreáveis no repositório), mas **não** estão declarados no `pubspec.yaml`:

- O GIF é o fallback documentado no `LEIA-ME.txt` original ("versão principal para implementação" é o WebP; o GIF é "alternativa de compatibilidade"). Só entra no bundle se algum problema de reprodução do WebP animado for observado em dispositivo real.
- O SVG é a fonte vetorial do ícone de localização; o projeto não tem a dependência `flutter_svg`, então hoje ele não é renderizável sem adicionar um pacote novo — mantido aqui como fonte oficial para o caso de essa decisão mudar no futuro.

## Fora do escopo (não trazido para `assets/`)

Vídeos de assinatura curta (abertura/fechamento de Reels/Stories/YouTube), encerramento de Reels, patterns/molduras/selos/medalhas/stickers de redes sociais — nenhum desses tem uso dentro do aplicativo Flutter; permanecem apenas nos pacotes originais de marketing, fora deste repositório.
