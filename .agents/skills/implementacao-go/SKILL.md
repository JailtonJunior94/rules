---
name: implementacao-go
description: Implementa alteracoes em codigo Go usando governanca base, arquitetura, estilo, testes e padroes recorrentes. Use quando a tarefa exigir adicionar, corrigir, refatorar ou validar codigo Go, incluindo interfaces, generics, concorrencia e validacao da stack. Nao use para tarefas sem codigo Go, documentacao geral ou triagem sem alteracao.
---

# Implementacao Go

## Procedimentos

**Step 1: Carregar base obrigatoria**
1. Ler `AGENTS.md`.
2. Ler `.agents/skills/governanca-agentes/SKILL.md`.
3. Ler `references/governanca.md`.
4. Ler `references/arquitetura.md`.
5. Ler `references/go-standards.md`.
6. Executar `bash scripts/verificar-go-mod.sh`.
7. Ler `go.mod` quando ele existir no contexto analisado.

**Step 2: Selecionar apenas o contexto necessario**
1. Ler `references/interfaces.md` quando a tarefa introduzir, remover ou remodelar interfaces, construtores ou fronteiras de dependencia.
2. Ler `references/generics.md` quando a tarefa introduzir ou alterar parametros de tipo, constraints ou componentes reutilizaveis com generics.
3. Ler `references/concorrencia.md` quando a tarefa usar goroutines, channels, cancelamento, worker pools ou sincronizacao.
4. Ler `references/design-patterns.md` quando a tarefa expor um problema recorrente de desenho que nao seja resolvido com tipos concretos, composicao simples ou extracao de metodo.
5. Ler `references/exemplos-implementacao.md` apenas quando um esqueleto concreto destravar a implementacao ou os testes.

**Step 3: Modelar a alteracao**
1. Identificar o menor conjunto seguro de mudancas que satisfaz a solicitacao.
2. Mapear o comportamento afetado, as dependencias envolvidas e o risco de regressao.
3. Preferir tipos concretos por padrao.
4. Introduzir interface apenas quando existir fronteira consumidora real, necessidade de substituicao ou ponto claro de teste.
5. Aplicar pattern apenas quando ele reduzir acoplamento, branching recorrente ou ambiguidade arquitetural.

**Step 4: Implementar**
1. Editar o codigo seguindo a versao Go declarada em `go.mod` e as convencoes do contexto analisado.
2. Manter comentarios curtos e apenas quando agregarem contexto real.
3. Atualizar ou adicionar testes para toda mudanca de comportamento.
4. Adaptar exemplos ao contexto real em vez de replica-los literalmente.

**Step 5: Validar**
1. Executar `gofmt` ou o formatter adotado pelo contexto nos arquivos Go alterados.
2. Executar primeiro testes direcionados e depois testes mais amplos quando o custo for proporcional.
3. Executar lint quando esse passo existir.
4. Registrar falhas com o comando exato e um diagnostico curto.

## Error Handling
* Se `go.mod` estiver ausente, parar antes de assumir versao de Go ou dependencias.
* Se o contexto nao fornecer comando de teste, lint ou formatter, registrar a ausencia explicitamente em vez de inventar substitutos.
* Se mais de uma abordagem parecer plausivel, preferir a alternativa com menos tipos, menos indirecao e menor custo de teste.
* Se houver conflito entre esta skill e a governanca base, seguir a restricao mais segura e registrar a suposicao.
