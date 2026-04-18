#!/usr/bin/env bash
# Remove artefatos de governanca de um projeto alvo.
# Uso:
#   bash uninstall.sh [--dry-run] [diretorio-alvo]
#
# Remove:
#   .agents/skills/           (symlinks ou copias instalados pelo install.sh)
#   .claude/skills/           (symlinks para .agents/skills/)
#   .claude/agents/           (wrappers gerados)
#   .claude/rules/governance.md
#   .claude/scripts/validate-task-evidence.sh
#   .claude/hooks/validate-governance.sh
#   .claude/settings.local.json  (apenas se contiver somente o hook de governanca)
#   .gemini/commands/         (comandos gerados)
#   .codex/config.toml
#   .github/agents/           (wrappers gerados)
#   .github/copilot-instructions.md
#   AGENTS.md, CLAUDE.md, GEMINI.md
#
# Preserva:
#   AGENTS.local.md           (extensoes locais do usuario)
#   Qualquer arquivo nao criado pelo install.sh

set -euo pipefail

DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERRO: diretorio alvo nao encontrado: $PROJECT_DIR"
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [[ ! -d "$PROJECT_DIR/.agents/skills" ]]; then
  echo "ERRO: governanca nao instalada em $PROJECT_DIR (pasta .agents/skills/ ausente)."
  exit 1
fi

removed=0

safe_rm() {
  local target="$1"
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] rm $target"
  else
    rm -rf "$target"
  fi
  removed=$((removed + 1))
}

safe_rmdir_if_empty() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  rmdir "$dir" 2>/dev/null || true
}

echo "Removendo governanca de: $PROJECT_DIR"
echo ""

# --- Skills (symlinks ou copias) ---
for skill_dir in "$PROJECT_DIR/.agents/skills"/*/; do
  [[ -d "$skill_dir" || -L "${skill_dir%/}" ]] || continue
  safe_rm "${skill_dir%/}"
done
safe_rmdir_if_empty "$PROJECT_DIR/.agents/skills"
safe_rmdir_if_empty "$PROJECT_DIR/.agents"

# --- Claude ---
if [[ -d "$PROJECT_DIR/.claude/skills" ]]; then
  for entry in "$PROJECT_DIR/.claude/skills"/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    safe_rm "$entry"
  done
fi
safe_rmdir_if_empty "$PROJECT_DIR/.claude/skills"

for agent_file in "$PROJECT_DIR/.claude/agents"/*.md; do
  [[ -f "$agent_file" ]] || continue
  safe_rm "$agent_file"
done
safe_rmdir_if_empty "$PROJECT_DIR/.claude/agents"

safe_rm "$PROJECT_DIR/.claude/rules/governance.md"
safe_rmdir_if_empty "$PROJECT_DIR/.claude/rules"

safe_rm "$PROJECT_DIR/.claude/scripts/validate-task-evidence.sh"
safe_rmdir_if_empty "$PROJECT_DIR/.claude/scripts"

safe_rm "$PROJECT_DIR/.claude/hooks/validate-governance.sh"
safe_rmdir_if_empty "$PROJECT_DIR/.claude/hooks"

# Remove settings.local.json only if it was auto-generated (contains only the governance hook)
if [[ -f "$PROJECT_DIR/.claude/settings.local.json" ]]; then
  if grep -q 'validate-governance' "$PROJECT_DIR/.claude/settings.local.json" 2>/dev/null; then
    # Check if file has other content beyond the governance hook
    _line_count="$(wc -l < "$PROJECT_DIR/.claude/settings.local.json" | tr -d ' ')"
    if [[ "$_line_count" -le 15 ]]; then
      safe_rm "$PROJECT_DIR/.claude/settings.local.json"
    else
      echo "AVISO: .claude/settings.local.json contem configuracoes alem do hook de governanca — mantido."
    fi
  fi
fi

safe_rmdir_if_empty "$PROJECT_DIR/.claude"

# --- Gemini ---
for cmd_file in "$PROJECT_DIR/.gemini/commands"/*.toml; do
  [[ -f "$cmd_file" ]] || continue
  safe_rm "$cmd_file"
done
safe_rmdir_if_empty "$PROJECT_DIR/.gemini/commands"
safe_rmdir_if_empty "$PROJECT_DIR/.gemini"

# --- Codex ---
safe_rm "$PROJECT_DIR/.codex/config.toml"
safe_rmdir_if_empty "$PROJECT_DIR/.codex"

# --- GitHub/Copilot ---
if [[ -d "$PROJECT_DIR/.github/skills" ]]; then
  for entry in "$PROJECT_DIR/.github/skills"/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    safe_rm "$entry"
  done
fi
safe_rmdir_if_empty "$PROJECT_DIR/.github/skills"

for agent_file in "$PROJECT_DIR/.github/agents"/*.agent.md; do
  [[ -f "$agent_file" ]] || continue
  safe_rm "$agent_file"
done
safe_rmdir_if_empty "$PROJECT_DIR/.github/agents"
safe_rm "$PROJECT_DIR/.github/copilot-instructions.md"
safe_rmdir_if_empty "$PROJECT_DIR/.github"

# --- Root files ---
safe_rm "$PROJECT_DIR/AGENTS.md"
safe_rm "$PROJECT_DIR/CLAUDE.md"
safe_rm "$PROJECT_DIR/GEMINI.md"

# Preserve AGENTS.local.md
if [[ -f "$PROJECT_DIR/AGENTS.local.md" ]]; then
  echo ""
  echo "AGENTS.local.md preservado (extensao local do usuario)."
fi

echo ""
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] $removed arquivo(s) seriam removidos. Nenhuma alteracao feita."
else
  echo "Governanca removida: $removed arquivo(s)."
fi
