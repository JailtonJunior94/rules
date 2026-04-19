# Observabilidade (Python)

## Objetivo
Garantir rastreabilidade, diagnóstico e visibilidade operacional em produção.

## Diretrizes

### Logging Estruturado
- Usar logging estruturado (JSON) com campos consistentes: `level`, `msg`, `error`, `trace_id`, `span_id`.
- Preferir `structlog` como default. Usar `logging` stdlib com `python-json-logger` quando já adotado.
- Logar em fronteiras de IO, erros e decisões de negócio relevantes — não em cada linha.
- Não logar dados sensíveis: tokens, senhas, PII, corpos de request com dados pessoais.
- Usar níveis com intenção: `DEBUG` para desenvolvimento, `INFO` para eventos operacionais, `WARNING` para degradação tolerada, `ERROR` para falha que exige atenção.

### Tracing Distribuído
- Preferir OpenTelemetry SDK (`opentelemetry-sdk`) como instrumentação padrão.
- Criar spans em operações com latência relevante: chamadas HTTP, queries, filas, cache.
- Usar auto-instrumentação (`opentelemetry-instrumentation-*`) para frameworks comuns (FastAPI, Django, SQLAlchemy).
- Propagar context automaticamente via instrumentação de HTTP client.

### Métricas
- Expor métricas básicas: request count, latência (histograma), error rate, saturação de recursos.
- Usar labels com cardinalidade controlada — nunca user ID ou valores unbounded como label.
- Usar `prometheus_client` ou OpenTelemetry metrics conforme stack do projeto.

### Health Checks
- Expor endpoint de liveness (processo vivo) e readiness (dependências prontas).
- Liveness não deve verificar dependências externas.
- Readiness deve verificar conexões críticas: banco, cache, filas.

## Riscos Comuns
- Log excessivo em hot path degradando throughput.
- Labels de métrica com alta cardinalidade causando explosão de séries temporais.
- Health check de readiness sem timeout causando cascata de falha.

## Proibido
- `print()` em código de produção como substituto de logger estruturado.
- Logar tokens, segredos ou PII.
- Ignorar propagação de context em chamadas entre serviços.
