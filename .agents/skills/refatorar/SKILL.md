---
name: refatorar
description: Planeja ou executa refatorações incrementais seguras preservando comportamento e coletando evidências de não regressão. Use quando uma refatoração delimitada precisar de orientação consultiva ou execução com validação e revisão. Não use para entrega de nova feature, definição de escopo de produto ou reescritas cosméticas sem alvo verificado.
---

# Refatorar

## Procedimentos

**Etapa 1: Validar escopo e modo**
1. Confirm the refactor scope is explicit enough to bound risk.
2. Resolve the mode as `advisory` unless `execution` is requested explicitly.
3. If scope is ambiguous or too broad, return `needs_input` with the missing boundaries.

**Etapa 2: Carregar o contexto técnico relevante**
1. Read `.agents/skills/governanca-agentes/SKILL.md` before code changes.
2. If the refactor touches Go code, also read `.agents/skills/implementacao-go/SKILL.md` and only the references required by the change.
3. Read `.agents/skills/governanca-agentes/references/` on demand when DDD, error handling, security, or tests affect the proposed change.
4. Map public contracts, integration points, and the most likely regression paths before editing.

**Etapa 3: Produzir a saída consultiva ou executar a refatoração**
1. In `advisory` mode:
   - describe the current pain points
   - propose the smallest safe refactor plan
   - highlight invariants, risks, and validation required
   - avoid editing files unless the user explicitly switches to execution
2. In `execution` mode:
   - apply the smallest safe change set
   - preserve observable behavior and public contracts
   - add or update tests when behavior could regress

**Etapa 4: Validar não regressão**
1. Run formatter on changed files.
2. Run targeted tests first.
3. Run broader test and lint commands proportional to the blast radius, preferring `task test` and `task lint` when available, then documented equivalents.
4. If validation fails, attempt bounded remediation only.

**Etapa 5: Revisar e persistir evidências**
1. No modo `execution`, invocar a skill `revisar` sobre o diff produzido.
2. Accept only `APPROVED` or `APPROVED_WITH_REMARKS` as a passing verdict.
3. Read `assets/refactor-report-template.md`.
4. Save the report to `tasks/prd-<feature-slug>/refactor_report.md` when inside a task context, otherwise `./refactor_report.md`.

**Etapa 6: Retornar o estado final**
1. Report mode, validations, reviewer verdict when applicable, and report path.
2. Return `done`, `blocked`, `failed`, or `needs_input`.

## Tratamento de Erros

* Se a refatoração solicitada alterar comportamento público, explicitar isso e parar, a menos que a mudança de comportamento tenha sido pedida.
* Se o codebase não tiver testes adequados para proteger uma refatoração arriscada, reduzir o escopo da refatoração ou adicionar cobertura faltante antes de prosseguir.
* Se uma baseline quebrada impedir provar não regressão, documentar a falha da baseline separadamente das falhas induzidas pela refatoração.
