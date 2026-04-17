# Go Standards

## Objetivo
Manter o código idiomático, legível e compatível com a toolchain Go.

## Diretrizes
- Preferir nomes curtos e precisos no escopo certo.
- Retornar erros como último valor e usar wrapping com `%w` quando necessário.
- Manter funções pequenas quando isso melhorar leitura e teste, sem fragmentação artificial.
- Preferir zero values úteis e construtores apenas quando houver invariantes ou dependências obrigatórias.
- Usar `context.Context` em fronteiras de IO, rede, subprocesso ou operações canceláveis.

## Validação
- Formatar com `gofmt`.
- Usar `go test ./...` como gate mínimo quando o contexto suportar esse passo.
