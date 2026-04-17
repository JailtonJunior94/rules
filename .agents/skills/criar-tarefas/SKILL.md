---
name: criar-tarefas
description: Cria tarefas incrementais de implementação a partir de um PRD e de uma especificação técnica. Use quando documentos de produto e técnicos aprovados precisarem ser decompostos em itens de trabalho ordenados e testáveis. Não use para mudanças diretas de código, descoberta de feature ou revisão de branch.
---

# Criar Tarefas

## Procedimentos

**Etapa 1: Validar os documentos de origem**
1. Confirm both `tasks/prd-<feature-slug>/prd.md` and `tasks/prd-<feature-slug>/techspec.md` exist.
2. Read both files completely before proposing work items.
3. Stop with `needs_input` if either document is missing or contradictory enough to block planning.

**Etapa 2: Extrair fatias de entrega**
1. Identify requirements, technical decisions, integration points, dependencies, and areas of risk.
2. Group work into slices that deliver verifiable value.
3. Preferir a sequência `domain -> interfaces/ports -> use cases -> adapters/repositories -> handlers -> integration`, salvo quando a especificação técnica justificar outra ordem.

**Etapa 3: Propor primeiro o plano de tarefas em alto nível**
1. Read `assets/tasks-template.md` and `assets/task-template.md` before drafting.
2. Produce a high-level list with at most 10 tasks.
3. For each task, include objective, deliverable, and dependencies.
4. Stop and wait for approval before generating final files.
5. If approval is not available in the current session, return `needs_input` and do not write the task files.

**Etapa 4: Gerar os artefatos detalhados de tarefa**
1. After approval, create `tasks/prd-<feature-slug>/tasks.md` from `assets/tasks-template.md`.
2. Criar um arquivo por tarefa usando `assets/task-template.md`.
3. Give each task explicit acceptance criteria, relevant files, and test expectations.
4. Ensure each task is independently executable and objectively reviewable.

**Etapa 5: Marcar dependências e paralelismo com clareza**
1. Usar apenas estados canônicos: `pending`, `in_progress`, `needs_input`, `blocked`, `failed`, `done`.
2. Mark critical dependencies explicitly.
3. Identify safe parallelism only when it does not hide integration risk.

**Etapa 6: Reportar o resultado**
1. List generated files.
2. Highlight critical dependencies and parallelizable tasks.
3. Retornar estado final `done` quando os arquivos forem gerados ou `needs_input` quando a aprovação ainda for necessária.

## Tratamento de Erros

* Se o PRD e a especificação técnica divergirem sobre o escopo, pausar e expor o conflito em vez de codificar os dois nas tarefas.
* Se uma tarefa proposta misturar preocupações não relacionadas, dividi-la antes de escrever os arquivos.
* Se o plano exceder 10 itens principais, consolidar ou reagrupar o trabalho até que cada tarefa represente uma fatia coerente de entrega, e não um micro-passo.
