# rules

Base mínima de regras compartilhadas para uso com agentes de IA em diferentes CLIs.

## Estrutura

- `AGENTS.md`: regra canônica compartilhada entre ferramentas
- `CLAUDE.md`: adaptador para Claude Code
- `.github/copilot-instructions.md`: adaptador para GitHub Copilot CLI
- `.codex/config.toml`: ativação de skills no Codex
- `.agents/skills/governanca-agentes`: skill portátil para governança e validação sob demanda
- `.agents/skills/implementacao-go`: skill portátil para implementação e validação em Go

## Como funciona

Use as regras para reduzir regressões, preservar arquitetura e padronizar como a IA lê, altera e valida código em diferentes contextos.

## Estratégia

Em vez de repetir o mesmo prompt em cada sessão, o ideal é:

1. manter uma regra canônica curta e estável em `AGENTS.md`
2. criar adaptadores mínimos por ferramenta
3. deixar governança transversal em skill base e especializações em skills por linguagem
4. deixar detalhes especializados em referências específicas

em '/Users/jailtonjunior/Git/rules/.claude', verifique os commands, templates, subagents que temos criado, e tranforme eles skills, para que os subagentes conversa o que é a parte de processo em    
  skill e mantenha o subagenda enxuto apenas sendo indicado que ele deve usar a skill relacionada criada, use a skill-best-practices para isso. utilize as melhores e mais recomendas práticas em 2026   
  e adapte para uso no claude code, codex e copilot-cli 