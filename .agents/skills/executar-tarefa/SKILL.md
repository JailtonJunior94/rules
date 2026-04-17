---
name: executar-tarefa
description: Executa uma tarefa de implementação aprovada por meio de codificação, validação, revisão e captura de evidências. Use quando um arquivo de tarefa estiver pronto para implementação e fechamento com testes, lint e evidência de revisão. Não use para planejamento, refatorações amplas sem tarefa ou exploração especulativa de código.
---

# Executar Tarefa

## Procedimentos

**Etapa 1: Validar a elegibilidade da tarefa**
1. Confirm `tasks/prd-<feature-slug>/tasks.md`, the target task file, `prd.md`, and `techspec.md` are present.
2. Select the first eligible task only when the user has not explicitly chosen one.
3. Confirm all task dependencies are `done`.
4. Stop with `needs_input` or `blocked` if the task is not eligible to execute.

**Etapa 2: Carregar o contexto de implementação**
1. Read the selected task file, `prd.md`, and `techspec.md` completely.
2. Read `.agents/skills/governanca-agentes/SKILL.md` before changing code.
3. If the task touches Go code, also read `.agents/skills/implementacao-go/SKILL.md` and load only the references required by the change.
4. Map the task objective, acceptance criteria, subtasks, and target files before editing.

**Etapa 3: Executar a etapa de implementação**
1. Follow the order of subtasks from the task file.
2. Implement tests together with production changes.
3. Prefer the repository's documented validation entrypoints:
   - `task test`, `task lint`, `task fmt` when available
   - otherwise use `make test`, `make lint`, `make fmt` or the documented equivalent
4. Run targeted validation after meaningful subtasks, not only at the end.
5. Registrar comandos executados e arquivos alterados para o relatório.
6. Stop with `needs_input` if a required decision or missing input blocks safe completion.

**Etapa 4: Executar a etapa de validação e aprovação**
1. Run formatter on changed files.
2. Run targeted tests first, then broader validation proportional to the risk.
3. Run the project-wide test and lint commands when the task scope justifies it.
4. Verify every acceptance criterion with explicit evidence.
5. Invocar a habilidade `revisar` para o diff produzido e incluir `prd.md` e `techspec.md` como contexto de revisão.
6. Accept only `APPROVED` or `APPROVED_WITH_REMARKS` as a passing reviewer verdict.

**Etapa 5: Persistir as evidências**
1. Read `assets/task-execution-report-template.md`.
2. Update the task status in `tasks.md` to `done` only after implementation, validation, and review have all succeeded.
3. Save the report as `tasks/prd-<feature-slug>/[num]_execution_report.md`.
4. Run `.claude/scripts/validate-task-evidence.sh` against the saved report.
5. If the evidence validator fails, return `blocked` and describe the missing evidence.

**Etapa 6: Encerrar explicitamente**
1. Informar o status da tarefa, os resultados de validação, o veredito do revisor e o caminho do relatório.
2. Retornar `done`, `blocked`, `failed` ou `needs_input` usando apenas nomes de estado canônicos.

## Tratamento de Erros

* Se o arquivo de tarefa estiver desatualizado em relação ao codebase ou à especificação técnica, parar e expor o descompasso antes de editar código.
* Se a automação do repositório não tiver entrypoints `task` ou `make`, descobrir e usar os comandos locais documentados em vez de adivinhar.
* Se as validações falharem, tentar apenas uma remediação limitada. Se a falha apontar para um problema de desenho mais profundo, parar e retornar `failed` com o comando bloqueante exato e um diagnóstico curto.
