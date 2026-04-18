# Testes Node/TypeScript

## Objetivo
Garantir correcao, prevenir regressao e documentar comportamento com custo proporcional ao risco.

## Unit Tests (obrigatorio)
- Usar o framework de teste ja adotado pelo projeto (Jest, Vitest, Mocha, Node test runner).
- Nomear testes pelo cenario, nao pelo metodo.
- Manter testes deterministicos — sem timers reais, sem dependencia de ordem.
- Usar mocks apenas para fronteiras externas (IO, rede, filesystem).
- Colocar arquivo de teste ao lado do arquivo testado ou em pasta `__tests__/` conforme convencao do projeto.

## Integration Tests (quando adotados)
- Separar de unit tests via script dedicado (ex: `npm run test:integration`).
- Usar testcontainers ou docker-compose para dependencias reais.
- Nao depender de servicos externos reais (banco de dev, API de staging).

## Proibido
- `setTimeout` para sincronizacao em teste.
- Teste que passa sozinho mas falha em suite completa.
- Mock que nao reflete o contrato real da dependencia.
