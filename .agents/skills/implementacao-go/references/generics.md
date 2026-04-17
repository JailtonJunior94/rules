# Generics

## Quando usar
- Quando houver algoritmo ou estrutura reutilizável para múltiplos tipos com a mesma semântica.
- Quando a alternativa seria duplicação relevante ou uso inseguro de `any`.

## Quando evitar
- Quando uma implementação concreta é mais clara.
- Quando a constraint fica mais complexa que o ganho obtido.
- Quando generics apenas escondem falta de modelagem de domínio.

## Diretrizes
- Preferir constraints mínimas e explícitas.
- Evitar APIs genéricas excessivamente abstratas.
- Validar se a versão de Go do contexto suporta a solução proposta.
