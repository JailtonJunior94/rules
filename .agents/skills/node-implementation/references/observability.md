# Observabilidade (Node/TypeScript)

## Objetivo
Garantir rastreabilidade, diagnóstico e visibilidade operacional em produção.

## Diretrizes

### Logging Estruturado
- Usar logging estruturado (JSON) com campos consistentes: `level`, `msg`, `error`, `traceId`, `spanId`.
- Preferir `pino` como default. Usar `winston` apenas quando já adotado no projeto.
- Logar em fronteiras de IO, erros e decisões de negócio relevantes — não em cada linha.
- Não logar dados sensíveis: tokens, senhas, PII, corpos de request com dados pessoais.
- Usar níveis com intenção: `debug` para desenvolvimento, `info` para eventos operacionais, `warn` para degradação tolerada, `error` para falha que exige atenção.

### Tracing Distribuído
- Preferir OpenTelemetry SDK (`@opentelemetry/sdk-node`) como instrumentação padrão.
- Criar spans em operações com latência relevante: chamadas HTTP, queries, filas, cache.
- Nomear spans pelo papel da operação, não pelo nome da função interna.
- Propagar context automaticamente via instrumentação de HTTP client e ORM.

### Métricas
- Expor métricas básicas: request count, latência (histograma), error rate, saturação de recursos.
- Usar labels com cardinalidade controlada — nunca user ID ou valores unbounded como label.
- Preferir histogramas a summaries para latência.

### Health Checks
- Expor endpoint de liveness (processo vivo) e readiness (dependências prontas).
- Liveness não deve verificar dependências externas.
- Readiness deve verificar conexões críticas: banco, cache, filas.

## Riscos Comuns
- Log excessivo em hot path degradando throughput do event loop.
- Labels de métrica com alta cardinalidade causando explosão de séries temporais.
- Health check de readiness sem timeout causando cascata de falha.

## Proibido
- `console.log` em código de produção como substituto de logger estruturado.
- Logar tokens, segredos ou PII.
- Ignorar propagação de context em chamadas entre serviços.
