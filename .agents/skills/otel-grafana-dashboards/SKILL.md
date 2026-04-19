---
name: otel-grafana-dashboards
version: 1.0.0
description: Gera e atualiza dashboards Grafana para servicos instrumentados com OpenTelemetry. Use quando precisar criar paineis de metricas, logs e traces para servicos Go, Node ou Python. Nao use para configurar a instrumentacao OTel no codigo — use as skills de linguagem para isso.
---

# OTel Grafana Dashboards

## Procedimentos

**Etapa 1: Identificar servico e sinais**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Identificar o nome do servico, linguagem e sinais disponíveis (metricas, logs, traces).
2. Listar as metricas-chave do servico: RED (Rate, Errors, Duration) como baseline.
3. Verificar o datasource Grafana configurado (Prometheus, Loki, Tempo).

**Etapa 2: Definir paineis do dashboard**
1. Painel de Rate: requisicoes por segundo por rota/endpoint.
2. Painel de Error Rate: porcentagem de erros (5xx, timeouts).
3. Painel de Latencia: p50, p95, p99 de duracao.
4. Painel de Logs: stream de logs com nivel de severidade.
5. Paineis customizados conforme metricas de negocio do servico.

**Etapa 3: Gerar o JSON do dashboard**
1. Gerar JSON compativel com Grafana 9+ usando o schema de dashboard.
2. Usar variaveis de template (`$datasource`, `$job`, `$instance`) para reutilizacao.
3. Incluir anotacoes para deploys e incidentes quando disponíveis.
4. Salvar em `dashboards/<service-name>.json`.

**Etapa 4: Validar e documentar**
1. Verificar que as queries PromQL/LogQL/TraceQL sao sintaticamente corretas.
2. Documentar metricas OTel usadas e seus namespaces.

## Tratamento de Erros

* Se o datasource nao estiver definido, usar `${datasource}` como variavel e documentar.
* Se metricas nao existirem no servico, listar o que precisa ser instrumentado.
* Nao hardcodar URLs ou credenciais de Grafana no JSON gerado.
