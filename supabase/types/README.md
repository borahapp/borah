# supabase/types

Destino dos tipos gerados a partir do schema do banco (AR-06 §14), a serem
populados quando o schema de dados existir (ET-02/DV-01 em diante).

**Limitação conhecida:** o Supabase CLI gera tipos oficialmente apenas para
**TypeScript** (`supabase gen types typescript`). Não há geração automática
de tipos **Dart** suportada oficialmente. Essa lacuna deverá ser tratada
quando a estratégia de geração de modelos para o Flutter for definida
(ex.: gerar TypeScript e converter, ou mapear manualmente via
`freezed`/`json_serializable` a partir do schema).
