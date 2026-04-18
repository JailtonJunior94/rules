# ai-governance

Governança reutilizável para agentes de IA em repositórios reais, com uma base canônica de skills em `.agents/skills/`, adaptadores por ferramenta e geração contextual de instruções para o projeto-alvo.

O repositório existe para evitar duplicação de processo entre Claude Code, Codex, Gemini CLI e GitHub Copilot, mantendo uma única fonte de verdade para regras operacionais, referências e fluxos de trabalho.

> Last reviewed: 2026-04-18

## Para quem é

Este README é voltado para quem quer:

- instalar governança de IA em outro repositório;
- entender o que `install.sh` e `upgrade.sh` realmente fazem;
- evoluir as skills e os adaptadores deste projeto sem quebrar o fluxo existente.

## O que o projeto entrega

### Base canônica

Toda a lógica procedural fica em `.agents/skills/`. Hoje o repositório contém:

- skills de processo: `agent-governance`, `analyze-project`, `bugfix`, `create-prd`, `create-technical-specification`, `create-tasks`, `execute-task`, `refactor`, `review`;
- skills de linguagem: `go-implementation`, `node-implementation`, `python-implementation`;
- skill adicional de design incremental para Go: `object-calisthenics-go`.

### Adaptadores por ferramenta

Os scripts do projeto geram ou instalam integrações para:

| Ferramenta | Arquivos gerados ou instalados |
|------------|--------------------------------|
| Claude Code | `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/`, `.claude/hooks/` |
| Gemini CLI | `GEMINI.md`, `.gemini/commands/` |
| Codex | `.codex/config.toml` |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/skills/`, `.github/agents/` |

Os adaptadores não redefinem o processo. Eles apontam para `.agents/skills/`, que continua sendo a fonte de verdade.

### Geração contextual

Quando `GENERATE_CONTEXTUAL_GOVERNANCE=1`:

- `install.sh` chama `.agents/skills/analyze-project/scripts/generate-governance.sh`;
- o gerador tenta classificar a arquitetura do projeto-alvo;
- o gerador detecta stack principal, frameworks e sinais de toolchain;
- `AGENTS.md` e arquivos auxiliares passam a refletir o contexto do repositório instalado.

## Estrutura do repositório

| Caminho | Papel |
|--------|-------|
| `.agents/skills/` | skills canônicas, assets, references e scripts de suporte |
| `.claude/` | adaptadores e arquivos base para Claude Code |
| `.codex/` | configuração base do Codex para este repositório |
| `.gemini/` | comandos base para Gemini CLI |
| `.github/` | adaptadores e workflow de CI |
| `scripts/` | geração de adaptadores, utilitários e helpers compartilhados |
| `tests/` | testes end-to-end, validação de heurísticas e snapshots |
| `install.sh` | instalação da governança em projeto-alvo |
| `upgrade.sh` | verificação e atualização de skills instaladas em modo `copy` |
| `VERSION` | versão do pacote de governança |

## Instalação

### Pré-requisitos

Para instalar em outro projeto, o código exige:

- `bash`;
- diretório-alvo já existente;
- permissão de escrita no diretório-alvo.

Para rodar a suíte completa deste repositório, `python3` também é usado em scripts auxiliares e no CI.

### Fluxo básico

```bash
bash install.sh /caminho/do/projeto
```

No modo interativo, o script pergunta:

1. quais ferramentas instalar: `claude`, `gemini`, `codex`, `copilot` ou todas;
2. quais linguagens devem receber skills de implementação: `go`, `node`, `python` ou todas.

Se nenhuma linguagem for escolhida, apenas as skills processuais são instaladas.

### Modo não interativo

```bash
# Claude + Gemini com Go e Python
bash install.sh --tools claude,gemini --langs go,python /caminho/do/projeto

# todas as ferramentas e todas as linguagens
bash install.sh --tools all --langs all /caminho/do/projeto

# apenas Codex e Copilot, sem skills de linguagem
bash install.sh --tools codex,copilot /caminho/do/projeto
```

Valores aceitos:

- `--tools`: `claude`, `gemini`, `codex`, `copilot`, `all`
- `--langs`: `go`, `node`, `python`, `all`

### Dry run

```bash
bash install.sh --dry-run /caminho/do/projeto
```

Esse modo mostra o que seria criado sem alterar arquivos.

### Modos de instalação e variáveis

| Variável | Default | Efeito validado no código |
|----------|---------|---------------------------|
| `LINK_MODE` | `symlink` | usa symlinks para as skills canônicas; com `copy`, instala um snapshot local |
| `GENERATE_CONTEXTUAL_GOVERNANCE` | `1` | com `1`, gera governança contextual; com `0`, copia os arquivos base sem personalização |
| `CODEX_SKILL_PROFILE` | `minimal` | controla o conjunto de skills no `.codex/config.toml`; `full` inclui também skills de planejamento |
| `DETECT_TOOLCHAIN_MAX_DEPTH` | `4` | profundidade máxima usada na busca de manifests para detecção de toolchain |
| `DETECT_TOOLCHAIN_FOCUS_PATHS` | vazio | prioriza paths afetados ao detectar o workspace ou package mais relevante |

Exemplos:

```bash
# instalação padrão com symlink
bash install.sh /caminho/do/projeto

# instalação portável com cópia
LINK_MODE=copy bash install.sh /caminho/do/projeto

# sem geração contextual
GENERATE_CONTEXTUAL_GOVERNANCE=0 bash install.sh /caminho/do/projeto

# perfil completo para Codex
CODEX_SKILL_PROFILE=full bash install.sh --tools codex --langs all /caminho/do/projeto
```

## O que é instalado no projeto-alvo

Sempre:

- `AGENTS.md`
- `.agents/skills/` com as skills selecionadas

Quando a ferramenta correspondente é selecionada:

- Claude Code: `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/`, `.claude/hooks/`
- Gemini CLI: `GEMINI.md`, `.gemini/commands/`
- Codex: `.codex/config.toml`
- GitHub Copilot: `.github/copilot-instructions.md`, `.github/skills/`, `.github/agents/`

Quando `LINK_MODE=copy`, as skills são copiadas para o projeto-alvo. Quando `LINK_MODE=symlink`, o projeto-alvo aponta para este repositório.

## Como o projeto funciona

### 1. Fonte única de verdade

As skills canônicas vivem em `.agents/skills/`. Adaptadores de ferramenta são somente wrappers finos.

### 2. Perfil enxuto para Codex

O perfil padrão do Codex é `minimal`. Pelo código de `scripts/lib/codex-config.sh`, ele habilita:

- `agent-governance`
- `execute-task`
- `refactor`
- `review`
- `bugfix`

As skills de planejamento entram no perfil `full` ou quando o projeto-alvo decide carregá-las sob demanda.

### 3. Geração de adaptadores

Os scripts em `scripts/` geram adaptadores a partir das skills instaladas:

- `scripts/generate-adapters.sh` gera wrappers de Claude e GitHub e delega a geração do Gemini;
- `scripts/generate-gemini-commands.sh` cria `.gemini/commands/*.toml` a partir do frontmatter e dos assets de cada skill.

### 4. Geração contextual

O gerador contextual usa:

- `.agents/skills/agent-governance/scripts/detect-architecture.sh`
- `.agents/skills/agent-governance/scripts/detect-toolchain.sh`
- `scripts/lib/find-manifests.sh`

Hoje a detecção de arquitetura cobre:

- `monorepo`
- `monolito modular`
- `microservico`
- `monolito` como fallback conservador

Para stack principal, o gerador tenta inferir sinais de:

- Go
- Node.js
- Python
- Java/Kotlin
- Rust
- C#/.NET

Para frameworks, há detecção explícita para alguns casos em manifests encontrados:

- Go: `Gin`, `Echo`, `Fiber`, `gRPC`, `Connect`
- Node.js: `Express`, `NestJS`, `Fastify`, `Next.js`, `Hono`
- Python: `FastAPI`, `Django`, `Flask`

## Atualização de skills

Use `upgrade.sh` quando a instalação tiver sido feita em modo `copy`.

### Verificar sem alterar

```bash
bash upgrade.sh --check /caminho/do/projeto
```

### Atualizar

```bash
bash upgrade.sh /caminho/do/projeto
```

O script compara:

- `version` no frontmatter de cada `SKILL.md`;
- checksum do conteúdo do `SKILL.md`;
- checksum e diferenças do diretório `references/`, quando existir.

Se houver atualização real e o projeto não estiver usando symlink, o script também pode:

- re-gerar adaptadores de Claude, GitHub e Gemini;
- sincronizar `.claude/rules/` e `.claude/scripts/`;
- re-gerar `.codex/config.toml` com base nas skills instaladas;
- re-gerar a governança contextual quando `AGENTS.md` existir no projeto-alvo.

### Filtrar por linguagem

```bash
# verificar apenas skills de Go
bash upgrade.sh --check --langs go /caminho/do/projeto

# atualizar apenas skills de Node.js
bash upgrade.sh --langs node /caminho/do/projeto
```

Valores aceitos em `--langs`: `go`, `node`, `python`.

## Desenvolvimento

### Testes disponíveis

Os scripts de teste presentes no repositório hoje são:

```bash
bash tests/test-generate-governance.sh
bash tests/test-install.sh
bash tests/test-upgrade.sh
bash tests/test-scripts.sh
bash tests/test-context-metrics.sh
bash tests/test-adapter-parity.sh
bash tests/test-skill-references.sh
bash tests/test-detect-architecture.sh
bash tests/test-detect-toolchain.sh
bash tests/test-skill-frontmatter.sh
```

Para atualização intencional de snapshots do gerador contextual:

```bash
bash tests/test-generate-governance.sh --update
```

### CI

O workflow em `.github/workflows/test.yml` executa essas suítes em:

- `ubuntu-24.04`
- `macos-15`

### Fixtures e snapshots

Os testes usam fixtures em `tests/fixtures/` para validar diferentes cenários, incluindo:

- `go-microservice`
- `go-modular`
- `node-monorepo`
- `python-fastapi`
- `python-monorepo`
- `polyglot-monorepo`

Os snapshots esperados do gerador ficam em `tests/snapshots/`.

## Limitações e observações

- `install.sh` e `upgrade.sh` rejeitam o próprio repositório `ai-governance` como alvo;
- o diretório-alvo precisa existir antes da execução;
- a geração contextual depende exclusivamente dos sinais encontrados localmente;
- quando não há sinal forte suficiente, o gerador usa fallback conservador;
- não há arquivo `LICENSE` nem `CONTRIBUTING.md` neste repositório no estado atual.

## Fluxo recomendado

```bash
# 1. instalar a governança
bash install.sh /caminho/do/projeto

# 2. revisar o que foi gerado
ls -la /caminho/do/projeto

# 3. em instalações por cópia, monitorar desatualização
bash upgrade.sh --check /caminho/do/projeto
```

## Como usar para desenvolver uma feature

Esta seção descreve o fluxo completo de uso da governança para levar uma feature do pedido inicial até a entrega com evidências. O objetivo não é inventar um processo paralelo, e sim operar exatamente em cima das skills e artefatos canônicos deste repositório.

### Quando usar este fluxo

Use este pipeline quando a mudança ainda não estiver suficientemente definida e você quiser rastreabilidade entre:

- objetivo de produto;
- desenho técnico;
- decomposição em tarefas;
- implementação;
- validação;
- revisão;
- evidências de execução.

Se a mudança for um bug isolado já bem reproduzido, o fluxo pode começar direto em `bugfix` em vez de passar por PRD e tech spec.

### Pré-requisitos no projeto-alvo

1. Instale a governança no repositório alvo.
2. Entre no diretório do projeto.
3. Confirme que `AGENTS.md` e `.agents/skills/` existem.
4. Se for usar Claude, Gemini, Codex ou Copilot, confirme também os adaptadores da ferramenta escolhida.

Exemplo:

```bash
bash install.sh --tools all --langs all /caminho/do/projeto
cd /caminho/do/projeto

ls -la
ls -la .agents/skills
ls -la .claude/agents
ls -la .gemini/commands
ls -la .github/agents
sed -n '1,220p' AGENTS.md
```

Estrutura mínima esperada após a instalação:

- `AGENTS.md`
- `.agents/skills/`
- `tasks/` será criado conforme as features forem sendo planejadas

### Visão geral do pipeline

Para uma feature nova, a sequência recomendada é:

1. gerar o PRD;
2. gerar a especificação técnica e ADRs;
3. propor o plano de tarefas;
4. aprovar o plano;
5. gerar `tasks.md` e os arquivos detalhados de tarefa;
6. executar uma tarefa elegível;
7. validar;
8. revisar;
9. corrigir bugs encontrados na revisão, quando necessário;
10. registrar evidências e concluir.

### Artefatos gerados ao longo do fluxo

Todos os artefatos da feature vivem em:

```text
tasks/prd-<slug-da-feature>/
```

Arquivos esperados:

- `prd.md`
- `techspec.md`
- `adr-001-<slug>.md`, `adr-002-<slug>.md`, quando houver decisões materiais
- `tasks.md`
- um arquivo por tarefa, por exemplo `1.0-<titulo>.md` ou outro nome estável adotado no projeto-alvo
- `[num]_execution_report.md` para cada tarefa executada
- `bugfix_report.md` quando houver remediação por `bugfix`

### Etapa 1: gerar o PRD

Objetivo: transformar a ideia da feature em um documento de produto claro, com objetivos, escopo, fora de escopo, restrições e requisitos funcionais numerados.

Saída esperada:

```text
tasks/prd-<slug-da-feature>/prd.md
```

O que a skill `create-prd` exige:

- foco em produto, não em implementação;
- no máximo duas rodadas de esclarecimento;
- retorno `done` quando o PRD estiver completo;
- retorno `needs_input` quando faltarem dados objetivos.

Exemplo de solicitação ao agente:

```text
Use create-prd para a feature "checkout com cupons por segmento". Gere ou atualize o PRD em tasks/prd-checkout-com-cupons-por-segmento/prd.md. Se faltar contexto, faça no máximo duas rodadas de perguntas e retorne needs_input.
```

Se quiser verificar o resultado no shell:

```bash
ls -la tasks
ls -la tasks/prd-checkout-com-cupons-por-segmento
sed -n '1,260p' tasks/prd-checkout-com-cupons-por-segmento/prd.md
```

### Etapa 2: gerar a especificação técnica

Objetivo: converter o PRD aprovado em um plano técnico implementável, com arquitetura, interfaces, riscos, testes e ADRs.

Saídas esperadas:

- `tasks/prd-<slug-da-feature>/techspec.md`
- `tasks/prd-<slug-da-feature>/adr-*.md`, quando houver decisões materiais

O que a skill `create-technical-specification` exige:

- PRD existente;
- exploração do codebase relevante antes de decidir;
- perguntas técnicas apenas quando houver bloqueio real;
- mapeamento de requisito para decisão e teste;
- documentação explícita de trade-offs e riscos.

Exemplo de solicitação ao agente:

```text
Use create-technical-specification para tasks/prd-checkout-com-cupons-por-segmento/prd.md. Explore apenas os caminhos de código relevantes, gere tasks/prd-checkout-com-cupons-por-segmento/techspec.md e crie ADRs separadas para decisões materiais.
```

Comandos úteis para inspeção:

```bash
sed -n '1,260p' tasks/prd-checkout-com-cupons-por-segmento/techspec.md
rg -n "^#|^##|^###" tasks/prd-checkout-com-cupons-por-segmento
ls -la tasks/prd-checkout-com-cupons-por-segmento
```

### Etapa 3: propor e aprovar o plano de tarefas

Objetivo: decompor a implementação em fatias verificáveis e ordenadas.

A skill `create-tasks` tem duas fases:

1. primeiro propõe um plano de alto nível com no máximo 10 tarefas;
2. só depois da aprovação gera `tasks.md` e os arquivos detalhados.

Isso é importante porque a própria skill foi desenhada para parar com `needs_input` se a aprovação ainda não estiver disponível.

Exemplo de solicitação ao agente:

```text
Use create-tasks para tasks/prd-checkout-com-cupons-por-segmento/prd.md e tasks/prd-checkout-com-cupons-por-segmento/techspec.md. Primeiro proponha apenas o plano de alto nível para aprovação. Não gere os arquivos finais ainda.
```

Depois de aprovar o plano:

```text
Plano aprovado. Gere tasks/prd-checkout-com-cupons-por-segmento/tasks.md e os arquivos detalhados de tarefa, com critérios de aceitação, testes e dependências explícitas.
```

Comandos úteis:

```bash
sed -n '1,260p' tasks/prd-checkout-com-cupons-por-segmento/tasks.md
find tasks/prd-checkout-com-cupons-por-segmento -maxdepth 1 -type f | sort
```

Estados canônicos que devem aparecer em `tasks.md`:

- `pending`
- `in_progress`
- `needs_input`
- `blocked`
- `failed`
- `done`

### Etapa 4: executar uma tarefa elegível

Objetivo: implementar uma tarefa aprovada com testes, validação, revisão e evidência.

Pré-condições da skill `execute-task`:

- `prd.md`, `techspec.md` e `tasks.md` presentes;
- arquivo de tarefa presente;
- dependências marcadas como `done`;
- contexto técnico da linguagem carregado sob demanda.

Exemplo de solicitação ao agente:

```text
Use execute-task para a primeira tarefa elegível em tasks/prd-checkout-com-cupons-por-segmento/. Leia prd.md, techspec.md, tasks.md e o arquivo da tarefa. Execute a implementação, rode validação proporcional, faça a revisão e retorne o caminho do relatório de execução com o estado final.
```

Se quiser apontar uma tarefa específica:

```text
Use execute-task para a tarefa 2.0 de tasks/prd-checkout-com-cupons-por-segmento/. Não escolha outra tarefa. Siga os critérios de aceitação e gere o relatório final.
```

Durante a execução, a skill deve:

- implementar código e testes juntos;
- usar `task test`, `task lint`, `task fmt` quando existirem;
- caso contrário, usar `make test`, `make lint`, `make fmt` ou o equivalente documentado no projeto;
- registrar comandos executados;
- registrar arquivos alterados;
- parar com `needs_input`, `blocked` ou `failed` quando o contexto não permitir uma conclusão segura.

### Etapa 5: validar e revisar

A validação final não termina só quando os testes passam. O fluxo canônico de `execute-task` exige também revisão.

Vereditos canônicos da skill `review`:

- `APPROVED`
- `APPROVED_WITH_REMARKS`
- `REJECTED`

Se a revisão reprovar:

1. `execute-task` deve acionar `bugfix` para corrigir os achados no escopo da tarefa;
2. as validações necessárias devem ser executadas novamente;
3. uma nova revisão deve ser rodada;
4. o fluxo deve parar se atingir o limite de profundidade de invocação definido em `agent-governance`.

### Etapa 6: fechar evidências

Toda tarefa concluída deve gerar relatório de execução.

Saída esperada:

```text
tasks/prd-<slug-da-feature>/[num]_execution_report.md
```

O relatório deve incluir pelo menos:

- identificação da tarefa;
- estado final;
- PRD e TechSpec consultados;
- comandos executados;
- arquivos alterados;
- resultado de testes;
- resultado de lint;
- veredito do revisor;
- suposições;
- riscos residuais;
- conflitos de regra, quando existirem.

Validação automática da evidência:

```bash
.claude/scripts/validate-task-evidence.sh tasks/prd-checkout-com-cupons-por-segmento/2_execution_report.md
```

Se houver bugfix, o fluxo também pode gerar:

```text
tasks/prd-<slug-da-feature>/bugfix_report.md
```

### Comandos shell mais úteis durante o fluxo

Os comandos abaixo não substituem as skills; eles servem para inspecionar artefatos e validar o que foi produzido.

```bash
# instalar a governança no projeto alvo
bash install.sh --tools all --langs all /caminho/do/projeto

# revisar a governança instalada
cd /caminho/do/projeto
sed -n '1,220p' AGENTS.md
find .agents/skills -maxdepth 2 -type f | sort | sed -n '1,200p'

# inspecionar artefatos da feature
find tasks/prd-<slug-da-feature> -maxdepth 1 -type f | sort
sed -n '1,220p' tasks/prd-<slug-da-feature>/prd.md
sed -n '1,260p' tasks/prd-<slug-da-feature>/techspec.md
sed -n '1,260p' tasks/prd-<slug-da-feature>/tasks.md

# revisar status e dependências
rg -n "pending|in_progress|needs_input|blocked|failed|done" tasks/prd-<slug-da-feature>

# validar evidência da tarefa executada
.claude/scripts/validate-task-evidence.sh tasks/prd-<slug-da-feature>/[num]_execution_report.md

# quando a instalação for por cópia, verificar atualização das skills
bash upgrade.sh --check /caminho/do/projeto
```

### Como acionar o fluxo em cada ferramenta

As skills canônicas são as mesmas para todas as ferramentas. O que muda é apenas o adaptador disponível no projeto-alvo.

#### Claude Code

Os subagentes gerados ficam em `.claude/agents/`:

- `prd-writer`
- `technical-specification-writer`
- `task-planner`
- `task-executor`

Use cada um para o estágio correspondente do pipeline e mantenha o pedido estreito ao escopo da etapa.

#### Gemini CLI

Os comandos gerados ficam em `.gemini/commands/`:

- `create-prd`
- `create-technical-specification`
- `create-tasks`
- `execute-task`

Cada comando encaminha a solicitação para a skill canônica correspondente.

#### GitHub Copilot

Os agentes gerados ficam em `.github/agents/`:

- `prd-writer.agent.md`
- `technical-specification-writer.agent.md`
- `task-planner.agent.md`
- `task-executor.agent.md`

O papel deles é orientar a execução do mesmo pipeline dentro do contexto do Copilot.

#### Codex

O perfil padrão deste repositório em `.codex/config.toml` é `minimal`, então:

- `agent-governance`
- `execute-task`
- `refactor`
- `review`
- `bugfix`

ficam habilitadas por default.

As skills de planejamento entram quando você instalar o projeto-alvo com:

```bash
CODEX_SKILL_PROFILE=full bash install.sh --tools codex --langs all /caminho/do/projeto
```

ou quando o projeto-alvo optar por carregá-las sob demanda.

### Exemplo de fluxo completo

Exemplo resumido para a feature `checkout-com-cupons-por-segmento`:

1. instalar a governança:

```bash
bash install.sh --tools all --langs all /caminho/do/projeto
cd /caminho/do/projeto
```

2. pedir o PRD ao agente:

```text
Use create-prd para a feature "checkout com cupons por segmento" e salve em tasks/prd-checkout-com-cupons-por-segmento/prd.md.
```

3. pedir a tech spec:

```text
Use create-technical-specification para tasks/prd-checkout-com-cupons-por-segmento/prd.md e gere a spec e as ADRs.
```

4. pedir o plano de tarefas:

```text
Use create-tasks para o PRD e a tech spec da feature checkout-com-cupons-por-segmento. Primeiro me mostre apenas o plano de alto nível para aprovação.
```

5. aprovar e gerar tarefas:

```text
Plano aprovado. Gere tasks.md e os arquivos detalhados de tarefa.
```

6. executar uma tarefa:

```text
Use execute-task para a primeira tarefa elegível da feature checkout-com-cupons-por-segmento e retorne o caminho do relatório de execução com o estado final.
```

7. validar a evidência:

```bash
find tasks/prd-checkout-com-cupons-por-segmento -maxdepth 1 -type f | sort
.claude/scripts/validate-task-evidence.sh tasks/prd-checkout-com-cupons-por-segmento/1_execution_report.md
```

8. repetir a execução até todas as tarefas críticas estarem em `done`.

### Sinais de que o fluxo está saudável

- o PRD está em `tasks/prd-<slug>/prd.md`;
- a tech spec está em `tasks/prd-<slug>/techspec.md`;
- ADRs existem para decisões materiais;
- `tasks.md` usa apenas estados canônicos;
- nenhuma tarefa é executada antes de suas dependências estarem em `done`;
- cada tarefa executada gera relatório;
- o relatório passa em `.claude/scripts/validate-task-evidence.sh`;
- a revisão final fecha em `APPROVED` ou `APPROVED_WITH_REMARKS`.

## Contribuindo

Se você for evoluir o projeto:

1. altere primeiro a skill canônica em `.agents/skills/`;
2. evite mover lógica para adaptadores quando a fonte correta for a skill;
3. atualize testes, snapshots ou fixtures quando a saída esperada mudar;
4. revise o `README.md` quando o comportamento operacional mudar.

## Resumo

`ai-governance` centraliza skills canônicas para agentes de IA, gera adaptadores leves para múltiplas ferramentas e contextualiza a governança no projeto-alvo. O foco do repositório é manter consistência operacional com a menor duplicação possível.
