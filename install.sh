#!/usr/bin/env bash
# Instala a governança IA-First em um projeto alvo.
# Uso: bash install.sh [diretório-destino]
# Se omitido, usa o diretório atual.
# O script pergunta quais ferramentas instalar.

set -euo pipefail

RULES_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [[ "$RULES_DIR" == "$PROJECT_DIR" ]]; then
  echo "ERRO: o diretório destino não pode ser o próprio repositório de regras."
  exit 1
fi

SKILLS=(criar-prd criar-especificacao-tecnica criar-tarefas executar-tarefa refatorar revisar analisar-projeto)

# ── Seleção de ferramentas ──────────────────────────────────────────
INSTALL_CLAUDE=0
INSTALL_GEMINI=0
INSTALL_CODEX=0
INSTALL_COPILOT=0

echo "Selecione as ferramentas que deseja instalar:"
echo ""
echo "  1) claude"
echo "  2) gemini"
echo "  3) codex"
echo "  4) copilot"
echo "  A) Todas"
echo ""
read -rp "Digite os números separados por espaço (ex: 1 3) ou A para todas: " selection

case "$selection" in
  [aA]|"")
    INSTALL_CLAUDE=1; INSTALL_GEMINI=1; INSTALL_CODEX=1; INSTALL_COPILOT=1
    ;;
  *)
    for num in $selection; do
      case "$num" in
        1) INSTALL_CLAUDE=1 ;;
        2) INSTALL_GEMINI=1 ;;
        3) INSTALL_CODEX=1 ;;
        4) INSTALL_COPILOT=1 ;;
        *) echo "AVISO: opção '$num' ignorada (inválida)." ;;
      esac
    done
    ;;
esac

if [[ $((INSTALL_CLAUDE + INSTALL_GEMINI + INSTALL_CODEX + INSTALL_COPILOT)) -eq 0 ]]; then
  echo "Nenhuma ferramenta selecionada. Saindo."
  exit 0
fi

selected=""
[[ $INSTALL_CLAUDE -eq 1 ]] && selected="$selected claude"
[[ $INSTALL_GEMINI -eq 1 ]] && selected="$selected gemini"
[[ $INSTALL_CODEX -eq 1 ]]  && selected="$selected codex"
[[ $INSTALL_COPILOT -eq 1 ]] && selected="$selected copilot"
echo ""
echo "Ferramentas selecionadas:$selected"
echo ""

# ── Base comum (AGENTS.md + skills canônicas) ───────────────────────
cp "$RULES_DIR/AGENTS.md" "$PROJECT_DIR/AGENTS.md"
mkdir -p "$PROJECT_DIR/.agents"
ln -sfn "$RULES_DIR/.agents/skills" "$PROJECT_DIR/.agents/skills"

# ── Claude Code ─────────────────────────────────────────────────────
if [[ $INSTALL_CLAUDE -eq 1 ]]; then
  echo "→ Instalando Claude Code..."
  mkdir -p "$PROJECT_DIR/.claude/skills" "$PROJECT_DIR/.claude/agents" "$PROJECT_DIR/.claude/rules" "$PROJECT_DIR/.claude/scripts"
  for skill in "${SKILLS[@]}"; do
    ln -sfn "../../.agents/skills/$skill" "$PROJECT_DIR/.claude/skills/$skill"
  done
  cp "$RULES_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
  cp "$RULES_DIR/.claude/rules/governance.md" "$PROJECT_DIR/.claude/rules/governance.md"
  cp "$RULES_DIR/.claude/agents/"*.md "$PROJECT_DIR/.claude/agents/"
  cp "$RULES_DIR/.claude/scripts/validate-task-evidence.sh" "$PROJECT_DIR/.claude/scripts/"
fi

# ── Gemini CLI ──────────────────────────────────────────────────────
if [[ $INSTALL_GEMINI -eq 1 ]]; then
  echo "→ Instalando Gemini CLI..."
  mkdir -p "$PROJECT_DIR/.gemini/commands"
  cp "$RULES_DIR/GEMINI.md" "$PROJECT_DIR/GEMINI.md"
  cp "$RULES_DIR/.gemini/commands/"*.toml "$PROJECT_DIR/.gemini/commands/"
fi

# ── Codex ───────────────────────────────────────────────────────────
if [[ $INSTALL_CODEX -eq 1 ]]; then
  echo "→ Instalando Codex..."
  mkdir -p "$PROJECT_DIR/.codex"
  cp "$RULES_DIR/.codex/config.toml" "$PROJECT_DIR/.codex/config.toml"
fi

# ── Copilot ─────────────────────────────────────────────────────────
if [[ $INSTALL_COPILOT -eq 1 ]]; then
  echo "→ Instalando Copilot..."
  mkdir -p "$PROJECT_DIR/.github/skills" "$PROJECT_DIR/.github/agents"
  for skill in "${SKILLS[@]}"; do
    ln -sfn "../../.agents/skills/$skill" "$PROJECT_DIR/.github/skills/$skill"
  done
  cp "$RULES_DIR/.github/copilot-instructions.md" "$PROJECT_DIR/.github/copilot-instructions.md"
  cp "$RULES_DIR/.github/agents/"*.md "$PROJECT_DIR/.github/agents/" 2>/dev/null || \
  cp "$RULES_DIR/.github/agents/"*.agent.md "$PROJECT_DIR/.github/agents/"
fi

echo ""
echo "Governança IA-First instalada em: $PROJECT_DIR"
