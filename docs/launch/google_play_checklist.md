# Google Play Console — Checklist Completo

**Contexto:** BETA-11A. Consolida BETA-04/06/08C/09/10D/10E numa sequência executável única. Para cada item: o que já existe no projeto vs. o que precisa ser fornecido/executado manualmente.

---

| # | Item | Já existe no projeto? | Ação manual necessária |
|---|---|---|---|
| 1 | Conta de desenvolvedor | 🔴 Não | Criar em [play.google.com/console](https://play.google.com/console) — taxa única de US$ 25; decidir Individual (sujeito à regra de 12 testadores/14 dias antes de Produção) ou Organização (isenta, exige documentação de CNPJ/D-U-N-S) |
| 2 | Package name | ✅ `com.borah.app` (definido em `android/app/build.gradle.kts`) | Só confirmar ao criar o app no Console |
| 3 | Assinatura (keystore) | 🟡 Plumbing completo (`build.gradle.kts`, corrigido BETA-07A) | Gerar a keystore real (`keytool`), guardar em cofre — comandos documentados em `docs/release/github_secrets.md` |
| 4 | Play App Signing | 🔴 Não configurado | No upload do primeiro AAB, optar por deixar o Google gerenciar a chave de assinatura final (recomendado) — a keystore própria vira só a "chave de upload" |
| 5 | Upload do primeiro AAB | 🟡 AAB já gerado com sucesso (BETA-10B), mas assinado com a chave de debug | Gerar um novo AAB com a keystore real antes do upload definitivo |
| 6 | Data Safety | 🟡 Inventário e texto prontos (BETA-08C/09B) | Preencher o formulário no Console usando `docs/store/google_play_listing.md` como base |
| 7 | Content Rating (IARC) | 🟡 Estimativa preliminar registrada (`docs/store/google_play_listing.md`) | Responder o questionário oficial no Console |
| 8 | Testers (listas de e-mail) | 🔴 Não definido | Definir a lista de e-mails dos testadores do Beta Fechado (ação do proprietário — quem convidar) |
| 9 | Internal Testing | 🔴 Não configurado | Criar a faixa, adicionar testadores, fazer upload do AAB — disponível imediatamente após a conta existir |
| 10 | Closed Testing | 🔴 Não configurado | Necessário **antes** de Produção se a conta for Pessoal (regra dos 12 testadores/14 dias, BETA-04) |
| 11 | Produção | 🔴 Não aplicável ainda | Última etapa — fora do escopo do Beta Fechado |
| 12 | Ficha da loja (nome, descrições, categoria) | ✅ Pronto (`docs/store/google_play_listing.md`) | Copiar para o Console |
| 13 | Ícone/Feature Graphic/Screenshots | 🟡 Ícone pronto; Feature Graphic e Screenshots só especificados (`docs/design/`), não produzidos | Produzir os assets reais (BETA-11B, conforme reorganização aprovada) |
| 14 | Política de Privacidade (URL) | 🟡 Conteúdo pronto, não publicado | Publicar em `appborah.com.br/privacidade` (ver `docs/release/hosting.md`) antes de preencher este campo |

## Ordem recomendada de execução

1. Decidir Individual vs. Organização (impacta os itens 1, 9-11).
2. Criar a conta (item 1) — iniciar a verificação de identidade o quanto antes (pode levar até 2 dias úteis).
3. Gerar a keystore real (item 3) e cadastrar os secrets correspondentes (`docs/release/github_secrets.md`).
4. Publicar a Política de Privacidade/Termos/Suporte no domínio (item 14, depende de `docs/release/hosting.md`).
5. Criar o app no Console, preencher ficha da loja (itens 2, 12).
6. Gerar um novo AAB assinado com a keystore real, habilitar Play App Signing (itens 4-5).
7. Preencher Data Safety e Content Rating (itens 6-7).
8. Definir lista de testadores, criar Internal Testing (itens 8-9).
9. Produzir os assets visuais reais antes de submeter para revisão (item 13, BETA-11B).
