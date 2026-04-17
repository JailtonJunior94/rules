# Arquitetura

## Objetivo
Preservar composição simples, dependências explícitas e fronteiras nítidas.

## Diretrizes
- Preferir packages coesos e dependências direcionadas.
- Manter regras de domínio fora de adapters, handlers e infraestrutura.
- Concentrar orquestração em camadas de aplicação ou serviços explícitos.
- Evitar cross-package helpers que misturem domínio, IO e formatação.
- Nomear tipos e funções pelo papel de negócio ou infraestrutura real.

## Sinais de excesso
- Pacote novo criado para uma única função sem necessidade estrutural.
- Interface sem consumidor alternativo.
- Pattern introduzido apenas para "preparar o futuro".
