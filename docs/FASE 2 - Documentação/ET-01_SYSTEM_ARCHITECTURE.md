# ET-01 — Arquitetura do Sistema

**Versão:** 1.0  
**Status:** Draft

## Objetivo
Definir a arquitetura oficial do BORAH, estabelecendo padrões para frontend, backend, banco de dados, integrações, segurança, escalabilidade e evolução do sistema.

## Índice
1. Introdução
2. Visão Geral da Arquitetura
3. Arquitetura Geral
4. Estilo Arquitetural
5. Arquitetura Flutter
6. Arquitetura Backend
7. Fluxo de Dados
8. Comunicação entre Módulos
9. Segurança
10. Offline First
11. Observabilidade
12. Performance
13. Escalabilidade
14. DevOps
15. Estratégia de Deploy
16. ADRs
17. Riscos Arquiteturais
18. Roadmap Técnico
19. Checklist Arquitetural
20. Anexos

## Visão Geral

```text
Flutter Mobile
      │
   HTTPS/REST
      │
 NestJS API
      │
 PostgreSQL
      │
Firebase • Google Places • OpenAI (futuro)
```

## Frontend
- Flutter
- Riverpod
- GoRouter
- Material 3
- Clean Architecture
- Feature First

## Backend
- NestJS
- Prisma
- PostgreSQL
- JWT
- Docker

## Fluxo de Dados
Usuário → Flutter → Riverpod → UseCase → Repository → REST API → Controller → UseCase → Repository → Prisma → PostgreSQL

## Segurança
- HTTPS
- JWT + Refresh Token
- BCrypt
- Rate Limiting
- LGPD

## Roadmap
Foundation → Auth → Grupos → Eventos → Restaurantes → Avaliações → Ranking → Feed → Notificações → Premium

## Checklist
- Clean Architecture
- DDD
- Testes
- Segurança
- Documentação
