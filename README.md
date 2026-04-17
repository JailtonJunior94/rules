# rules

Base minima de regras compartilhadas para uso com agentes de IA em diferentes CLIs.

## Estrutura

```
.agents/skills/                          <- fonte canonica de toda habilidade
  criar-prd/                             <- PRD de produto
  criar-especificacao-tecnica/           <- techspec e ADRs
  criar-tarefas/                         <- decomposicao em tarefas
  executar-tarefa/                       <- implementacao com evidencias
  refatorar/                             <- refatoracao segura
  revisar/                               <- revisao de codigo
  governanca-agentes/                    <- regras transversais (DDD, seguranca, erros, testes)
  implementacao-go/                      <- regras e referencias para Go

AGENTS.md                                <- regra canonica compartilhada
CLAUDE.md                                <- adaptador para Claude Code
GEMINI.md                                <- adaptador para Gemini CLI
.github/copilot-instructions.md          <- adaptador para GitHub Copilot CLI
.codex/config.toml                       <- ativacao de skills no Codex

.claude/skills/                          <- symlinks -> .agents/skills/
.claude/agents/                          <- thin wrappers (subagentes)
.claude/rules/                           <- governance cross-cutting

.gemini/commands/                        <- thin wrappers para Gemini CLI
.github/agents/                          <- thin wrappers para Copilot CLI
```

## Contrato de Portabilidade

- **Fonte de verdade procedural**: `.agents/skills/`
- **Regras canonicas**: `AGENTS.md`
- **Adaptadores por plataforma**: thin wrappers que referenciam a habilidade canonica
  - Claude Code: `.claude/skills/` (symlinks), `.claude/agents/`
  - Codex: `.codex/config.toml`
  - Copilot CLI: `.github/copilot-instructions.md`, `.github/agents/`
  - Gemini CLI: `GEMINI.md`, `.gemini/commands/`

## Principio

O processo detalhado mora na habilidade canonica em `.agents/skills/`. Comandos, agentes e adaptadores por plataforma apenas roteiam para a habilidade adequada — nunca duplicam o conteudo.

---

## Exemplos de Prompts

Abaixo estao exemplos de como invocar cada habilidade nas diferentes plataformas. O fluxo completo de desenvolvimento segue a ordem: **PRD > Especificacao Tecnica > Tarefas > Execucao > Revisao**.

---

### Criar PRD

Gera um documento de requisitos de produto a partir de uma descricao de funcionalidade.

**Claude Code**

```
/criar-prd Implementar sistema de notificacoes push para o app mobile
```

ou via subagente:

```
@redator-prd Criar PRD para sistema de notificacoes push com suporte a iOS e Android
```

**GitHub Copilot CLI**

```
@redator-prd Criar PRD para sistema de notificacoes push com suporte a iOS e Android
```

**Gemini CLI**

```
/criar-prd Implementar sistema de notificacoes push para o app mobile
```

**Codex CLI**

```
Leia .agents/skills/criar-prd/SKILL.md e gere um PRD para sistema de notificacoes push
```

---

### Criar Especificacao Tecnica

Gera especificacao tecnica e ADRs a partir de um PRD aprovado.

**Claude Code**

```
/criar-especificacao-tecnica Gerar techspec baseado no PRD docs/prd-notificacoes.md
```

ou via subagente:

```
@redator-especificacao-tecnica Criar techspec para o PRD docs/prd-notificacoes.md
```

**GitHub Copilot CLI**

```
@redator-especificacao-tecnica Criar techspec para o PRD docs/prd-notificacoes.md
```

**Gemini CLI**

```
/criar-especificacao-tecnica Gerar techspec baseado no PRD docs/prd-notificacoes.md
```

**Codex CLI**

```
Leia .agents/skills/criar-especificacao-tecnica/SKILL.md e gere a techspec para docs/prd-notificacoes.md
```

---

### Criar Tarefas

Decompoe PRD e techspec aprovados em tarefas ordenadas de implementacao.

**Claude Code**

```
/criar-tarefas Gerar tarefas a partir de docs/prd-notificacoes.md e docs/techspec-notificacoes.md
```

ou via subagente:

```
@planejador-tarefas Decompor em tarefas o PRD docs/prd-notificacoes.md com techspec docs/techspec-notificacoes.md
```

**GitHub Copilot CLI**

```
@planejador-tarefas Decompor em tarefas o PRD docs/prd-notificacoes.md com techspec docs/techspec-notificacoes.md
```

**Gemini CLI**

```
/criar-tarefas Gerar tarefas a partir de docs/prd-notificacoes.md e docs/techspec-notificacoes.md
```

**Codex CLI**

```
Leia .agents/skills/criar-tarefas/SKILL.md e gere tarefas para docs/prd-notificacoes.md e docs/techspec-notificacoes.md
```

---

### Executar Tarefa

Implementa uma tarefa aprovada com codificacao, testes e captura de evidencias.

**Claude Code**

```
/executar-tarefa Implementar a tarefa docs/tasks/task-001.md
```

ou via subagente:

```
@executor-tarefa Executar docs/tasks/task-001.md
```

**GitHub Copilot CLI**

```
@executor-tarefa Executar docs/tasks/task-001.md
```

**Gemini CLI**

```
/executar-tarefa Implementar a tarefa docs/tasks/task-001.md
```

**Codex CLI**

```
Leia .agents/skills/executar-tarefa/SKILL.md e implemente docs/tasks/task-001.md
```

---

### Refatorar

Planeja ou executa refatoracoes seguras preservando comportamento.

**Claude Code**

```
/refatorar Extrair duplicacao do handler de pagamentos em internal/payment/handler.go
```

ou via subagente:

```
@refatorador Refatorar internal/payment/handler.go extraindo duplicacao
```

**GitHub Copilot CLI**

```
@refatorador Refatorar internal/payment/handler.go extraindo duplicacao
```

**Gemini CLI**

```
/refatorar Extrair duplicacao do handler de pagamentos em internal/payment/handler.go
```

**Codex CLI**

```
Leia .agents/skills/refatorar/SKILL.md e refatore internal/payment/handler.go extraindo duplicacao
```

---

### Revisar

Revisa um diff quanto a correcao, seguranca, regressoes e testes faltantes.

**Claude Code**

```
/revisar Revisar as mudancas da branch feat/notificacoes
```

ou via subagente:

```
@revisor Revisar diff da branch feat/notificacoes contra main
```

**GitHub Copilot CLI**

```
@revisor Revisar diff da branch feat/notificacoes contra main
```

**Gemini CLI**

```
/revisar Revisar as mudancas da branch feat/notificacoes
```

**Codex CLI**

```
Leia .agents/skills/revisar/SKILL.md e revise o diff da branch feat/notificacoes contra main
```

---

### Fluxo Completo de Desenvolvimento

Exemplo end-to-end usando Claude Code:

```bash
# 1. Criar o PRD
/criar-prd Implementar cache distribuido com Redis para o servico de catalogo

# 2. Gerar a especificacao tecnica
/criar-especificacao-tecnica Gerar techspec baseado no PRD docs/prd-cache-catalogo.md

# 3. Decompor em tarefas
/criar-tarefas Gerar tarefas a partir de docs/prd-cache-catalogo.md e docs/techspec-cache-catalogo.md

# 4. Executar cada tarefa
/executar-tarefa Implementar docs/tasks/task-001.md
/executar-tarefa Implementar docs/tasks/task-002.md

# 5. Revisar antes do merge
/revisar Revisar as mudancas da branch feat/cache-catalogo
```

O mesmo fluxo no Gemini CLI segue a mesma sequencia com os comandos `/criar-prd`, `/criar-especificacao-tecnica`, `/criar-tarefas`, `/executar-tarefa` e `/revisar`.

No Copilot CLI, use os agentes `@redator-prd`, `@redator-especificacao-tecnica`, `@planejador-tarefas`, `@executor-tarefa` e `@revisor`.

No Codex CLI, prefixe cada passo com a leitura da SKILL.md correspondente em `.agents/skills/`.
