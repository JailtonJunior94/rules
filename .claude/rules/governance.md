# Governança de Regras

- Rule ID: R-GOV-001
- Severidade: hard
- Escopo: `.claude/rules/`, `.claude/context/`, `.claude/commands/` e `.claude/skills/`.

## Objetivo
Definir precedência, resolução de conflitos e critérios de evidência para evolução da CLI ORQ.

## Escopo das Regras
- Toda automação deve obedecer implicitamente às regras em `.claude/rules/`.
- Todo comando, skill ou alteração deve considerar o contexto em `.claude/context/`.
- O PRD da feature em `tasks/prd-orq-cli/prd.md` é a referência principal de produto para esta CLI.
- O Uber Go Style Guide em PT-BR é a referência mandatória de estilo Go:
  `https://github.com/alcir-junior-caju/uber-go-style-guide-pt-br/blob/main/style.md`

## Metadados Obrigatórios
Cada regra deve declarar:
- `Rule ID`
- `Severidade`
- `Escopo`

## Precedência
1. `governance.md`
2. `security.md`
3. `architecture.md`
4. `cli.md`, `error-handling.md` e `o11y.md`
5. `ddd.md`, `tests.md` e `code-standards.md`
6. Uber Go Style Guide PT-BR como baseline transversal de estilo, nomenclatura, organização e práticas idiomáticas

Se duas regras do mesmo nível conflitarem:
- prevalece `hard` sobre `guideline`
- se a severidade empatar, prevalece a regra mais restritiva para correção, segurança e determinismo
- quando houver conflito entre o guia da Uber e uma convenção explícita deste projeto, prevalece a convenção explícita local se ela estiver documentada nestas regras

## Estados Canônicos
- Estados de run permitidos: `pending`, `running`, `paused`, `failed`, `completed`, `cancelled`.
- Estados de step permitidos: `pending`, `running`, `waiting_approval`, `approved`, `retrying`, `failed`, `skipped`.
- Ações HITL permitidas: `approve`, `edit`, `redo`, `exit`.

## Política de Evidência
- Toda alteração deve ser justificável pelo PRD, por regra explícita ou por necessidade técnica demonstrável.
- Relatórios devem incluir arquivos alterados, validações executadas, riscos residuais e suposições assumidas.
- Não aprovar solução com lacuna crítica conhecida.

## Segurança Operacional
- A CLI não deve executar ações de git destrutivas ou publicações remotas sem pedido explícito.
- O step de execução não pode incluir `git commit`, `git push` ou `gh pr create`.
- Se faltar input obrigatório e não houver inferência segura, a execução deve pausar ou falhar de forma explícita.

## Proibido
- Estados ad hoc fora dos enums definidos.
- Aprovação sem evidência.
- Loops infinitos de remediação.
