# Modelagem de Domínio

- Rule ID: R-DDD-001
- Severidade: hard
- Escopo: `internal/*/domain/` e `internal/*/application/`.

## Objetivo
Garantir um domínio explícito para workflows, runs, steps, providers e artefatos, evitando structs anêmicas e regras espalhadas.

## Requisitos

### Entidades
- `Run`, `Workflow`, `StepExecution` e tipos equivalentes devem proteger invariantes no construtor e nos métodos.
- Entidades devem expor comportamento de domínio: `ApproveStep`, `RetryStep`, `Pause`, `Resume`, `MarkFailed`.
- Campos sensíveis do domínio devem permanecer não exportados.

### Value Objects
- Modelar como VO os conceitos com regra própria: `WorkflowName`, `StepName`, `ProviderName`, `RunStatus`, `StepStatus`, `ArtifactPath`.
- VOs devem se autovalidar.
- VOs devem ser imutáveis por design.

### Aggregate Roots
- `Run` deve ser o aggregate root natural da execução.
- Alterações em steps devem ocorrer por métodos do `Run` quando influenciarem o estado global.
- Transições de estado devem ser centralizadas no aggregate root ou em um state object explícito.

### Application Layer
- Use cases devem orquestrar leitura de workflow, resolução de input, chamada do runtime e persistência.
- Parsing de YAML, JSON e input de terminal não pertence ao domínio.
- Application não deve conter regra de transição de estado que pertence ao domínio.

### Domain Services
- Usar domain services para regras que combinam múltiplas entidades ou VOs.
- Domain services devem ser stateless.

### Fail Fast
- Workflow inválido deve falhar na validação antes de iniciar execução.
- Referência a step inexistente, provider inválido e template inconsistente devem ser rejeitados cedo.
- Um `Run` não deve existir em estado inválido.

### State Pattern
- Estados do run e do step devem ter transições permitidas de forma explícita.
- Não usar strings soltas espalhadas pelo código para comparar estado.

## Proibido
- Struct literal de entidade fora de testes e factories.
- Regras de transição espalhadas em handlers, comandos ou adapters.
- Domínio conhecendo detalhes de `orquestration/`, JSON schema, subprocesso ou editor.
