# Especificação do Ícone — BORAH

**Contexto:** BETA-10E1. O ícone **já existe e já está em produção** (IV-02/IV-09) — este documento não pede um ícone novo, apenas especifica formalmente o que já foi aplicado, para uso consistente em qualquer material derivado (site, redes sociais, marketing).

---

## 1. Conceito

O símbolo BORAH: uma forma circular com uma "mordida" característica (referência direta a "rolê"/experiência gastronômica), sobre o gradiente roxo oficial. Já implementado, não deve ser reinterpretado ou redesenhado para nenhum material de loja/marketing.

## 2. Composição

- Fundo: gradiente roxo oficial de 3 tons (`#6C47FF → #5B2EFF → #3D19C7`), já embutido na própria arte do ícone (`app_icon`), não um gradiente aplicado por fora.
- Símbolo: a "mordida" característica, centralizada, ocupando a maior parte segura do quadro.
- Fonte da arte: `app/assets/borah/app_icon/borah_app_icon_1024.png` (matriz 1024×1024, já usada por `flutter_launcher_icons` para gerar todos os tamanhos de Android/iOS).

## 3. Área segura

Seguir a mesma regra já aplicada ao símbolo/logo em qualquer contexto: **espaço livre equivalente a metade da altura do próprio símbolo** ao redor dele, quando o ícone for reutilizado dentro de uma composição maior (ex.: como elemento visual dentro da Feature Graphic ou de um post de rede social) — nunca cortado rente à borda.

## 4. Versões clara e escura

O ícone do app **não tem variação clara/escura própria** — é uma única arte, com o gradiente já embutido, pensada para funcionar sobre qualquer fundo de sistema operacional (Android/iOS aplicam suas próprias máscaras, sem alterar a arte interna). Para usos **fora** do ícone do app (ex.: marca d'água em vídeo, favicon do site institucional), usar:
- **Sobre fundo claro**: o símbolo isolado (`app/assets/borah/symbol/borah_symbol.svg`), que já é a peça oficial indicada para uso em interações/interface — nunca o ícone completo (que já tem fundo colorido embutido) sobre outro fundo colorido.
- **Sobre fundo escuro**: mesmo símbolo isolado funciona, já que ele é desenhado para contraste — não recolorir.

## 5. Restrições (regras do Manual da Marca, invioláveis)

- **Não recriar, distorcer, recolorir ou recortar** o ícone/símbolo.
- **Não aplicar cantos arredondados manualmente** — iOS e Android aplicam suas próprias máscaras automaticamente; a arte-fonte é fornecida como quadrado 1024×1024 de propósito.
- **Não rotacionar, não aplicar sombra externa/contorno/glow** fora do sistema de animação oficial já existente.
- **Não esticar** — sempre proporção 1:1 preservada.

## 6. Tamanhos exigidos pelas lojas (já gerados, nenhum novo necessário)

| Contexto | Tamanho | Status |
|---|---|---|
| Matriz-fonte | 1024×1024px | ✅ Pronta |
| Android (`mipmap-*`, todas as densidades) | Gerado automaticamente via `flutter_launcher_icons` | ✅ Pronto (IV-02) |
| iOS (`AppIcon.appiconset`, todos os tamanhos incluindo legados) | Gerado automaticamente via `flutter_launcher_icons` | ✅ Pronto (IV-02) |
| Google Play Console | 512×512px, PNG 32-bit com alpha | ✅ Pronto (IV-09, `app/assets/borah/platform/android/google_play/BORAH_google_play_512.png`) |

**Nenhuma ação de produção é necessária para o ícone — já está completo e em conformidade.** Este documento existe para que nenhuma rodada futura tente "melhorar" ou substituir o ícone sem necessidade.
