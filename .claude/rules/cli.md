# Camada de CLI

- Rule ID: R-CLI-001
- Severidade: hard para comportamento, guideline para estilo de UX
- Escopo: `cmd/`, `internal/cli/` e adapters de terminal.

## Objetivo
Garantir uma experiência de terminal previsível, robusta e alinhada ao modelo de comando da orquestration.

## Requisitos

### Comandos Base
- A CLI deve expor `orquestration run <workflow>`, `orquestration continue` e `orquestration list`.
- `run` deve aceitar `--input` e `-f, --file`.
- `continue` deve localizar estado persistido compatível e retomar do último ponto seguro.
- `list` deve mostrar workflows disponíveis de forma simples e legível.

### UX de Terminal
- A saída deve indicar step atual, provider em uso, duração e status.
- A saída deve ser legível em macOS, Linux e Windows.
- O prompt HITL deve aparecer imediatamente após o output estar disponível.
- A renderização deve separar progresso, conteúdo do artefato e prompt de ação.

### Flags e Configuração
- Flags devem ter nomes previsíveis e sem ambiguidade.
- Defaults devem ser explícitos na ajuda do comando.
- Configuração global, quando existir, deve ser carregada de forma determinística e sem efeitos colaterais ocultos.

### Integração com Editor
- A ação `edit` deve usar adapter próprio para editor externo.
- Falha ao abrir editor deve gerar mensagem acionável e manter o run íntegro.

### Cross-Platform
- Paths devem ser construídos com `filepath`.
- Chamadas de subprocesso devem evitar dependência implícita de shell quando não necessária.
- Comportamentos dependentes do SO devem ficar isolados em `internal/platform`.

## Proibido
- Parse manual de `os.Args` fora do Cobra.
- Uso de ANSI obrigatório sem fallback.
- Misturar rendering de terminal com transição de estado de domínio.
