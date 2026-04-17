# Interfaces

## Quando usar
- Quando existir mais de uma implementação real ou um ponto claro de substituição.
- Quando um consumidor depender apenas de um comportamento pequeno e estável.
- Quando a interface reduzir acoplamento em uma fronteira real.

## Quando evitar
- Para "facilitar testes" sem necessidade real.
- Antes de existir consumidor ou segunda implementação.
- Quando um tipo concreto simples resolve o problema.

## Diretrizes
- Definir a interface no lado consumidor quando isso clarificar a fronteira.
- Manter interfaces pequenas e focadas.
- Evitar interfaces infladas com métodos não usados.
