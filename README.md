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

## Contribuindo

Se você for evoluir o projeto:

1. altere primeiro a skill canônica em `.agents/skills/`;
2. evite mover lógica para adaptadores quando a fonte correta for a skill;
3. atualize testes, snapshots ou fixtures quando a saída esperada mudar;
4. revise o `README.md` quando o comportamento operacional mudar.

## Resumo

`ai-governance` centraliza skills canônicas para agentes de IA, gera adaptadores leves para múltiplas ferramentas e contextualiza a governança no projeto-alvo. O foco do repositório é manter consistência operacional com a menor duplicação possível.
