# Padrões de Código

- Rule ID: R-CODE-001
- Severidade: guideline
- Escopo: Todos os arquivos `.go`.

## Objetivo
Manter o código simples, legível, idiomático em Go e consistente com Clean Code, SOLID e KISS.

## Referência Mandatória
- O guia base de estilo é o Uber Go Style Guide PT-BR:
  `https://github.com/alcir-junior-caju/uber-go-style-guide-pt-br/blob/main/style.md`
- Na ausência de regra mais específica do projeto, seguir o guia da Uber.

## Requisitos

### Idioma
- Código, comentários de código, nomes de testes e símbolos devem estar em inglês.
- Texto de produto, help e mensagens ao usuário podem estar em português se a CLI adotar esse idioma.

### Nomenclatura
- `camelCase` para variáveis locais e campos não exportados.
- `PascalCase` para tipos, funções exportadas e constantes exportadas.
- `snake_case` para arquivos e diretórios.
- Interfaces devem descrever comportamento: `Runner`, `Store`, `Renderer`, `Provider`.
- Evitar siglas obscuras; abreviações aceitas: `ctx`, `err`, `id`, `cfg`, `cmd`.

### Estrutura de Funções
- Funções devem ter uma responsabilidade.
- Preferir fluxo linear e blocos curtos.
- Reduzir aninhamento e `else` desnecessário, em linha com o guia da Uber.
- Evitar early return em cascata quando isso fragmentar demais a leitura; preferir organizar o fluxo em etapas claras, com branches explícitos, quando isso melhorar leitura.
- Evitar `else` desnecessário após bloco terminal apenas quando a legibilidade não piorar.
- Parâmetros booleanos que alternam comportamento devem ser substituídos por tipo, enum ou estratégia.

### Complexidade
- Preferir até 3 parâmetros posicionais; acima disso, avaliar params struct.
- Funções devem mirar em até 50 linhas.
- Arquivos devem mirar em até 300 linhas.
- Condicionais e loops devem ser simples o suficiente para leitura sem rolagem mental.

### Comentários
- Comentários devem explicar intenção, invariantes e trade-offs.
- Comentários não devem narrar o óbvio.
- Símbolos exportados devem ter godoc.

### Go Idiomático
- Erros são valores; tratar explicitamente.
- `context.Context` deve ser o primeiro parâmetro em métodos públicos que lidam com IO, subprocesso, render ou persistência.
- Não criar interfaces sem necessidade concreta de substituição.
- Receivers devem ser consistentes por tipo.
- Para logging estruturado, preferir `log/slog` e atributos explícitos quando a chamada estiver em caminho quente ou exigir mais robustez.
- Verificar conformidade de interfaces em compile time quando apropriado.
- Evitar ponteiro para interface.
- Evitar `init()`, globais mutáveis e goroutines sem ciclo de vida explícito.
- Copiar slices e maps nos limites quando houver risco de vazar estado interno.
- Preferir `strconv` a `fmt` em caminhos simples de conversão.

## Proibido
- Símbolos em português no código.
- Nomes genéricos como `data`, `manager`, `helper`, `util` sem contexto.
- Flags booleanas para controlar múltiplos fluxos.
- Comentários redundantes.
