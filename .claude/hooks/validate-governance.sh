#!/usr/bin/env bash
# Hook de validacao pos-edicao: avisa quando arquivos de governanca sao modificados diretamente.
# Instalado em projetos consumidores via install.sh.
# Para habilitar manualmente, adicione ao .claude/settings.local.json:
#
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Edit|Write",
#       "hooks": [{"type": "command", "command": "bash .claude/hooks/validate-governance.sh"}]
#     }]
#   }
#
# Entrada: JSON do tool use via stdin.
# Saida: aviso em stderr quando um arquivo de governanca e editado.
#
# Modos (via variavel de ambiente GOVERNANCE_HOOK_MODE):
#   warn  — emite aviso em stderr, exit 0 (default)
#   fail  — emite aviso em stderr, exit 1 (bloqueia a edicao)

set -euo pipefail

GOVERNANCE_HOOK_MODE="${GOVERNANCE_HOOK_MODE:-warn}"

input="$(cat)"

# Extract file_path: try python3/jq for robust JSON parsing, fallback to grep/sed.
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

case "$file_path" in
  */.agents/skills/*/SKILL.md|*/.agents/skills/*/references/*.md|*/AGENTS.md)
    echo "AVISO: arquivo de governanca modificado: $file_path" >&2
    echo "Verifique se esta edicao e intencional e se nao quebra o contrato de upgrade." >&2
    if [[ "$GOVERNANCE_HOOK_MODE" == "fail" ]]; then
      exit 1
    fi
    ;;
esac

exit 0
