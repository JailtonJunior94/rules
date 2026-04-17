---
name: criar-especificacao-tecnica
description: Cria especificações técnicas prontas para implementação a partir de um PRD aprovado e do contexto do repositório. Use quando arquitetura, interfaces, riscos, ADRs e estratégia de testes precisarem ser definidos antes da codificação. Não use para descoberta de produto, execução de tarefa ou revisão de código.
---

# Criar Especificação Técnica

## Procedimentos

**Etapa 1: Validar o artefato de entrada**
1. Confirmar que o PRD alvo existe em `tasks/prd-<slug-da-feature>/prd.md`.
2. Extrair requisitos, restrições, métricas e itens fora de escopo do PRD antes de explorar o codebase.
3. Parar com `needs_input` se o PRD estiver ausente ou incompleto demais para sustentar decisões de arquitetura.

**Etapa 2: Mapear o repositório e as restrições técnicas**
1. Read `AGENTS.md` and explore the repository structure relevant to the PRD.
2. Explore only the code paths, modules, integrations, and interfaces relevant to the PRD.
3. Map impacts across architecture, data flow, observability, error handling, and tests.
4. If external dependencies or current vendor behavior matter, verify them with primary documentation or official docs.

**Etapa 3: Resolver bloqueios de arquitetura**
1. Ask technical clarification questions that cover:
   - domain boundaries
   - data flow
   - interface contracts
   - expected failures and idempotency
   - test strategy
2. Limit clarification to two rounds.
3. If architecture remains blocked after two rounds, return `needs_input` with the missing decisions.

**Etapa 4: Verificar conformidade com as regras do repositório**
1. Read `.agents/skills/governanca-agentes/SKILL.md` and load references on demand:
   - `.agents/skills/governanca-agentes/references/ddd.md`
   - `.agents/skills/governanca-agentes/references/error-handling.md`
   - `.agents/skills/governanca-agentes/references/security.md`
   - `.agents/skills/governanca-agentes/references/tests.md`
3. For every intentional deviation, record the justification and the rejected compliant alternative.

**Etapa 5: Redigir a especificação técnica**
1. Read `assets/techspec-template.md` before drafting.
2. Focus on how to implement the feature, not on re-explaining the PRD.
3. Include a requirement-to-decision-to-test mapping.
4. Document chosen approaches, trade-offs, rejected alternatives, risks, and observability implications.
5. Keep interfaces and data models concrete enough to drive implementation.

**Etapa 6: Criar ADRs para decisões materiais**
1. Ler `assets/adr-template.md`.
2. Para cada decisão material introduzida na especificação técnica, criar uma ADR separada em `tasks/prd-<slug-da-feature>/`.
3. Usar nomes estáveis de arquivo como `adr-001-<slug-da-decisao>.md`.
4. Vincular as ADRs a partir da especificação técnica.

**Etapa 7: Persistir e reportar**
1. Salvar a especificação técnica como `tasks/prd-<slug-da-feature>/techspec.md`.
2. Informar o caminho final, os caminhos das ADRs e os itens ainda em aberto.
3. Retornar estado final `done` ou `needs_input`.

## Tratamento de Erros

* Se o PRD misturar produto com detalhe de implementação, preservar a intenção de produto e mover apenas as decisões de implementação para a especificação técnica.
* Se a exploração do repositório mostrar que o desenho solicitado viola regras existentes de arquitetura ou segurança, documentar o conflito explicitamente em vez de normalizá-lo em silêncio.
* Se a documentação externa de uma dependência estiver indisponível, marcar a decisão afetada como suposição e reduzir o raio de impacto dessa suposição na implementação proposta.
