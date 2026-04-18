# Testes Python

## Objetivo
Garantir correcao, prevenir regressao e documentar comportamento com custo proporcional ao risco.

## Unit Tests (obrigatorio)
- Usar o framework ja adotado pelo projeto (pytest, unittest).
- Preferir pytest quando nao houver convencao existente.
- Nomear testes pelo cenario: `test_confirm_order_already_shipped`.
- Manter testes deterministicos — sem sleep, sem dependencia de ordem, sem estado global.
- Usar fixtures do pytest para setup/teardown compartilhado.
- Usar mocks apenas para fronteiras externas (IO, rede, filesystem).

## Integration Tests (quando adotados)
- Separar de unit tests via marcador (`@pytest.mark.integration`) ou diretorio.
- Usar testcontainers-python para dependencias reais.
- Nao depender de servicos externos reais (banco de dev, API de staging).

## Proibido
- `time.sleep` para sincronizacao em teste.
- Teste que passa sozinho mas falha em suite completa.
- Mock que nao reflete o contrato real da dependencia.
- Fixture com logica complexa que precisa de seus proprios testes.
