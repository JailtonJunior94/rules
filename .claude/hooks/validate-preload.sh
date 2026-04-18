#!/usr/bin/env bash
# Hook PreToolUse opcional: verifica se o contrato de carga base foi cumprido
# antes de permitir edicoes em codigo.
#
# Para habilitar, adicione ao .claude/settings.local.json:
#
#   "PreToolUse": [{
#     "matcher": "Edit|Write",
#     "hooks": [{"type": "command", "command": "bash .claude/hooks/validate-preload.sh"}]
#   }]
#
# Este hook e informativo por padrao. Use GOVERNANCE_PRELOAD_MODE=fail para bloquear.
# Entrada: JSON do tool use via stdin.

set -euo pipefail

GOVERNANCE_PRELOAD_MODE="${GOVERNANCE_PRELOAD_MODE:-warn}"

input="$(cat)"

# Extract file_path from tool input
file_path=""
if command -v python3 >/dev/null 2>&1; then
  file_path="$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', data).get('file_path', ''))
except Exception:
    pass
" 2>/dev/null || true)"
elif command -v jq >/dev/null 2>&1; then
  file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null || true)"
fi

if [[ -z "$file_path" ]]; then
  file_path="$(printf '%s' "$input" | grep -o '"file_path":"[^"]*"' 2>/dev/null | head -1 | sed 's/"file_path":"//;s/"//' || true)"
fi

[[ -n "$file_path" ]] || exit 0

# Only check code files, not governance files themselves
case "$file_path" in
  *.go|*.py|*.ts|*.js|*.tsx|*.jsx)
    # This hook emits a reminder — the actual enforcement depends on the agent following it
    echo "LEMBRETE: antes de editar codigo, confirme que AGENTS.md e agent-governance/SKILL.md foram lidos nesta sessao." >&2
    if [[ "$GOVERNANCE_PRELOAD_MODE" == "fail" ]]; then
      echo "GOVERNANCE_PRELOAD_MODE=fail: bloqueando edicao ate que contrato de carga seja confirmado." >&2
      exit 1
    fi
    ;;
esac

exit 0
