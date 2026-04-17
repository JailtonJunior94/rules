# Concorrência

## Objetivo
Usar concorrência apenas quando ela resolver um problema real de latência, throughput ou isolamento.

## Diretrizes
- Preferir execução sequencial por padrão.
- Usar `context.Context` para cancelamento.
- Fechar channels no produtor quando isso fizer parte do contrato.
- Proteger estado compartilhado explicitamente.
- Garantir que testes sejam determinísticos e não dependam de `sleep`.

## Riscos comuns
- Goroutine sem encerramento claro.
- Deadlock por contrato implícito.
- Data race por estado compartilhado sem sincronização.
