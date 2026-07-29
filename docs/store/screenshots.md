# Store Assets e Screenshots — Guia de Produção

**Contexto:** BETA-10E. Guia de produção para os assets visuais das duas lojas — **nenhuma imagem foi gerada nesta rodada**, só as especificações exatas e o roteiro de conteúdo. Dimensões verificadas contra as especificações vigentes de cada loja (não assumidas de memória).

---

## 1. Especificações exatas — Google Play

| Asset | Dimensão | Formato | Status |
|---|---|---|---|
| Ícone | 512×512px | PNG 32-bit com alpha | ✅ Já pronto (IV-09, `app/assets/borah/platform/android/google_play/BORAH_google_play_512.png`) |
| Feature Graphic | **1024×500px exatos** | JPEG ou PNG 24-bit, **sem** canal alpha | 🔴 Não produzido |
| Phone Screenshots | Proporção entre 16:9 e 9:16, mínimo 320px e máximo 3840px por lado (recomendado 1080×1920) | JPEG ou PNG 24-bit, sem alpha | 🔴 Não produzidos — mínimo 2, máximo 8 |
| Tablet Screenshots (7" e 10") | Mesmas regras de proporção/resolução do phone, por form factor | JPEG ou PNG 24-bit, sem alpha | 🔴 Opcional — não produzidos |

## 2. Especificações exatas — Apple App Store

| Asset | Dimensão | Formato | Status |
|---|---|---|---|
| App Icon | 1024×1024px, sem alpha, sem cantos arredondados (a loja aplica a máscara) | PNG | ✅ Já pronto (IV-02) |
| iPhone Screenshots (6.9") | **1320×2868px** — obrigatório, cobre a maior tela da geração atual | PNG ou JPEG, RGB, sem alpha | 🔴 Não produzidos |
| iPhone Screenshots (6.7", opcional) | 1290×2796px | Idem | 🔴 Opcional |
| iPhone Screenshots (6.5", opcional) | 1242×2688px | Idem | 🔴 Opcional |
| iPad Screenshots (13", já que o app suporta iPad — `UISupportedInterfaceOrientations~ipad` está declarado no `Info.plist`) | **2064×2752px** | Idem | 🔴 Não produzidos |
| Quantidade | Mínimo 1, máximo 10 por device class | — | — |

**Nota**: como o Apple exige apenas a maior tela de cada família (6.9" iPhone / 13" iPad) e escala automaticamente para os dispositivos menores, produzir esses dois tamanhos já cobre o requisito mínimo de publicação.

---

## 3. Roteiro de screenshots (conteúdo, não produção)

6 telas, na ordem que conta a história do produto — da promessa central (ranking) até o reforço social/gamificação:

### 1. Ranking de Restaurantes (tela de abertura/hero)
- **Objetivo**: comunicar a promessa central em menos de 1 segundo de leitura.
- **Mensagem principal**: "O ranking do seu grupo, sempre atualizado."
- **Texto de overlay**: *"Todo grupo tem seus rolês. Agora eles têm um ranking."*
- **Dispositivo recomendado**: iPhone 6.9" / Android phone — sempre a primeira screenshot (a mais vista em qualquer loja).

### 2. Feed
- **Objetivo**: mostrar o app em uso real, com atividade do grupo.
- **Mensagem principal**: "Veja o que seu grupo está avaliando."
- **Texto de overlay**: *"Acompanhe cada rolê do seu grupo em tempo real."*
- **Dispositivo recomendado**: iPhone 6.9" / Android phone.

### 3. Descoberta/detalhe de um restaurante
- **Objetivo**: mostrar a riqueza de informação (nota, fotos, comentários) de um lugar já avaliado.
- **Mensagem principal**: "Cada lugar, com a nota de quem importa: seu grupo."
- **Texto de overlay**: *"Nada de nota genérica de desconhecido."*
- **Dispositivo recomendado**: iPhone 6.9".

### 4. Criação de avaliação
- **Objetivo**: mostrar como é simples registrar um rolê (nota, comentário, foto).
- **Mensagem principal**: "Avalie em segundos — nota, comentário e fotos."
- **Texto de overlay**: *"Registre o rolê antes que vocês esqueçam."*
- **Dispositivo recomendado**: iPhone 6.9".

### 5. Perfil / Gamificação (XP, nível, conquistas)
- **Objetivo**: reforçar o elemento de jogo, diferencial competitivo do BORAH.
- **Mensagem principal**: "Suba de nível a cada avaliação."
- **Texto de overlay**: *"Quem mais avalia, mais sobe no ranking."*
- **Dispositivo recomendado**: iPhone 6.9".

### 6. Ranking de Usuários
- **Objetivo**: fechar com o segundo ranking (pessoas, não só lugares) — reforça a dimensão social/competitiva.
- **Mensagem principal**: "Quem é o especialista em bons rolês do seu grupo?"
- **Texto de overlay**: *"Curta, comente, suba no ranking."*
- **Dispositivo recomendado**: iPhone 6.9".

**Para iPad**: reaproveitar as mesmas 6 composições, recapturadas na resolução do iPad (2064×2752px), sem alterar a mensagem/overlay.

---

## Pendências

- Nenhum ícone/screenshot/feature graphic foi gerado nesta rodada — só especificação.
- Produção real depende de: (1) uma build de Produção funcional instalada em dispositivo/emulador real (Android já validado na BETA-10B; iOS ainda depende de macOS, BETA-10C), e (2) design do overlay de texto sobre cada captura.
- Recomendo a BETA-10E1 (já sugerida) para produzir esses assets, só depois que este roteiro estiver aprovado.
