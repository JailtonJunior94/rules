# Arquitetura da CLI

- Rule ID: R-ARCH-001
- Severidade: hard
- Escopo: Todo código Go da CLI em `cmd/`, `internal/` e `pkg/`.

## Objetivo
Definir uma arquitetura de CLI robusta, extensível e idiomática em Go, orientada por Clean Architecture, SOLID, KISS e composição.

## Requisitos

### Direção Arquitetural
- A CLI deve ser organizada como aplicação de terminal, não como backend HTTP.
- O fluxo principal deve ser: `cmd/` -> `internal/bootstrap` -> `internal/<module>/application` -> `internal/<module>/domain`.
- Dependências devem apontar para dentro: adapters e infraestrutura dependem de application/domain.
- O domínio não deve importar Cobra, `os/exec`, filesystem, terminal UI ou detalhes de serialização.

### Estrutura Base
- `cmd/orquestration/`: entrypoint e bootstrap do Cobra.
- `internal/cli/`: comandos Cobra, flags, help, rendering e bind de dependências.
- `internal/workflows/`: parser, validator, template resolver e catálogo de workflows.
- `internal/runtime/`: engine de execução, controle de steps, retry, continue e coordenação HITL.
- `internal/providers/`: contratos e adapters de Claude CLI, Copilot CLI e futuros providers.
- `internal/state/`: persistência de runs, artefatos e logs operacionais em `orquestration/`.
- `internal/platform/`: wrappers de OS, subprocess, clock, editor, path, terminal e filesystem.
- `pkg/`: tipos e utilitários realmente compartilhados entre módulos.

### Cobra CLI
- O ponto de entrada da CLI deve usar `github.com/spf13/cobra`.
- Cada comando deve residir em arquivo dedicado com responsabilidade única.
- Comandos devem apenas validar input, montar request DTO e delegar para application services.
- Flags devem ser declaradas no comando dono e convertidas para tipos explícitos antes do use case.
- `PersistentPreRunE` e `PreRunE` devem ser usados apenas para preparação e validação transversal.

### Automação e Release
- A automação local deve usar `Taskfile.yml` como ponto central para build, test, lint, geração e fluxos repetitivos.
- Comandos documentados para contribuidores devem preferir `task <nome>` em vez de sequências longas de shell.
- Empacotamento e release cross-platform devem usar `GoReleaser`.
- A configuração de release deve gerar binários para macOS, Linux e Windows, coerente com o PRD.
- O desenho da CLI deve considerar desde o início versionamento, metadados de build e distribuição automatizada.

### Engine de Workflow
- O runtime deve controlar a execução do workflow do início ao fim.
- Steps devem ser executados de forma sequencial e determinística na V1.
- Resolução de templates deve ocorrer antes de chamar o provider.
- Cada step deve operar com contexto explícito e isolado.
- O estado do run deve ser persistido após cada transição relevante.
- O provider nunca decide sozinho o próximo step.

### Providers e Ports
- Providers devem ser abstraídos por interface focada no consumidor.
- Invocação de Claude CLI e Copilot CLI deve ocorrer via adapter de subprocesso.
- O adapter deve capturar `stdout`, `stderr`, timeout, exit code e metadados de execução.
- Validação do binário no `PATH` deve acontecer antes da execução do workflow ou no bootstrap do provider.
- Adição de novos providers não deve exigir mudança no engine.

### Persistência e Estado
- Estado da execução deve ser salvo em `orquestration/`.
- Cada run deve ter diretório próprio para evitar sobrescrita acidental.
- Artefatos Markdown, JSON, logs e `state.json` devem ser persistidos separadamente.
- O contrato de estado deve ser versionado para permitir evolução sem quebra.

### Terminal e HITL
- Rendering de progresso, output e prompt interativo deve ficar fora do domínio.
- A UX do terminal deve priorizar clareza, baixo ruído e tempo de resposta previsível.
- Aprovar, editar, refazer e sair devem ser tratados como comandos explícitos do runtime.
- Abertura de editor externo deve ser encapsulada em adapter próprio.

### Design Patterns
Referência canônica: https://refactoring.guru/design-patterns

- `Strategy`: seleção de provider, renderer, input source e política de retry.
- `Command`: comandos Cobra e ações de runtime devem encapsular uma intenção por struct.
- `Factory Method`: criação de providers, parsers, renderers e stores a partir de config.
- `Template Method` por composição: fluxo comum de execução de step com hooks de validação, persistência e HITL.
- `State`: modelagem dos estados do run e do step com transições explícitas.
- `Adapter`: integração com subprocesso, editor, filesystem e terminal.
- `Facade`: serviços de application que simplificam o uso do runtime para os comandos.

### KISS e Go-like
- Preferir composição a hierarquias profundas.
- Preferir structs pequenas e interfaces mínimas.
- Preferir código direto quando abstração não reduzir acoplamento real.
- Evitar frameworks desnecessários; Cobra e bibliotecas pequenas bastam.
- Aplicar as práticas idiomáticas do Uber Go Style Guide como baseline de implementação.

## Proibido
- Lógica de negócio em comandos Cobra.
- Estado global mutável para controlar execução.
- Acoplamento direto do domínio com detalhes de terminal ou subprocesso.
- Abstrações genéricas antes de haver dois casos reais.
- Providers com autonomia para alterar fluxo do workflow.
