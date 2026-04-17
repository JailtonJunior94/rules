# Design Patterns

## Objetivo
Aplicar patterns apenas quando reduzirem complexidade real.

## Diretrizes
- Preferir composição a hierarquias profundas.
- Preferir função, método ou tipo concreto antes de factory, strategy ou decorator.
- Usar pattern quando houver variação recorrente de comportamento ou dependência externa que exija adaptação clara.
- Escolher no máximo um pattern principal por problema.

## Sinais de uso indevido
- Mais tipos e indireção sem melhora de teste ou legibilidade.
- Pattern introduzido para "seguir boas práticas" sem pressão concreta do contexto.
