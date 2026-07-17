
# AR-03 — Environment Configuration

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-03_ENVIRONMENT_CONFIGURATION.md

---

# 1. Objetivo

Padronizar o ambiente de desenvolvimento do BORAH para que qualquer desenvolvedor consiga configurar o projeto de forma rápida, reproduzível e consistente.

---

# 2. Sistemas Operacionais Suportados

- Windows 11 (principal)
- macOS (Apple Silicon e Intel)
- Ubuntu LTS

---

# 3. Ferramentas Obrigatórias

| Ferramenta | Versão Recomendada | Finalidade |
|------------|--------------------|------------|
| Flutter | Estável (via FVM) | Desenvolvimento |
| Dart | Compatível com Flutter | Linguagem |
| Git | Última estável | Versionamento |
| VS Code ou Android Studio | Última estável | IDE |
| Supabase CLI | Última estável | Backend local |
| Node.js LTS | LTS | Ferramentas auxiliares |

---

# 4. Gerenciamento do Flutter

Utilizar **FVM (Flutter Version Management)** para garantir que toda a equipe utilize exatamente a mesma versão do Flutter.

Estrutura:

```text
.fvm/
fvm_config.json
```

Nunca instalar dependências em versões diferentes da definida pelo projeto.

---

# 5. Configuração Inicial

Fluxo recomendado:

1. Clonar o repositório.
2. Instalar a versão do Flutter via FVM.
3. Executar `flutter pub get`.
4. Configurar os arquivos `.env`.
5. Iniciar o Supabase local (quando aplicável).
6. Executar o projeto.

---

# 6. Variáveis de Ambiente

Arquivos previstos:

```text
.env.example
.env.local
.env.development
.env.production
```

Exemplo:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
API_TIMEOUT=30000
LOG_LEVEL=debug
```

Nunca versionar arquivos contendo segredos.

---

# 7. Estrutura de Ambientes

- Development
- Staging
- Production

Cada ambiente deverá possuir:

- URL própria
- Banco de dados próprio
- Storage próprio
- Chaves independentes

---

# 8. IDE

## VS Code

Extensões recomendadas:

- Dart
- Flutter
- Error Lens
- GitLens
- Better Comments
- Markdown All in One

## Android Studio

Plugins:

- Flutter
- Dart

---

# 9. Android

Requisitos:

- Android SDK
- Platform Tools
- Emulator
- JDK compatível com Flutter

---

# 10. iOS

Requisitos:

- Xcode
- CocoaPods
- Simulador iOS

(Apenas para macOS.)

---

# 11. Supabase

Estrutura:

```text
backend/
└── supabase/
    ├── config/
    ├── migrations/
    ├── functions/
    ├── seed/
    └── policies/
```

Comandos frequentes:

- iniciar ambiente local
- aplicar migrações
- gerar tipos
- publicar funções

---

# 12. Qualidade

Executar antes de qualquer Pull Request:

- análise estática
- testes
- formatação
- geração de código

---

# 13. Git

Configurar:

- Nome
- E-mail
- SSH (preferencial)
- Assinatura de commits (opcional)

---

# 14. Estrutura Local

```text
BORAH/
├── app/
├── backend/
├── docs/
├── scripts/
└── assets/
```

---

# 15. Checklist de Onboarding

- Git instalado
- FVM configurado
- Flutter instalado
- Dependências baixadas
- Arquivos .env criados
- Supabase configurado
- Projeto executando
- Testes executados

---

# 16. Boas Práticas

- Nunca editar arquivos gerados automaticamente.
- Nunca versionar segredos.
- Manter ferramentas atualizadas conforme a versão oficial do projeto.
- Executar análise estática antes de enviar código.

---

# 17. Anti-patterns

Evitar:

- Flutter fora do FVM.
- Dependências desatualizadas sem aprovação.
- Chaves de produção em ambiente local.
- Alterações manuais em arquivos gerados.

---

# 18. Critérios de Aceite

- Ambiente reproduzível.
- Configuração documentada.
- Ambientes separados.
- Ferramentas padronizadas.
- Processo de onboarding validado.

---

# 19. Checklist Final

- Ferramentas definidas
- FVM adotado
- Ambientes configurados
- Variáveis documentadas
- IDE padronizada
- Supabase preparado
- Boas práticas registradas
- Anti-patterns documentados
