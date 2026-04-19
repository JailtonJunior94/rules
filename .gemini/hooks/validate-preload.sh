#!/usr/bin/env bash
# Hook de pre-edicao para Gemini CLI: lembra do contrato de carga base antes
# de editar arquivos de codigo.
#
# Uso: configurar no GEMINI.md ou via --hook do Gemini CLI:
#   gemini --hook "bash .gemini/hooks/validate-preload.sh {file}"
#
# Recebe o caminho do arquivo como $1 (Gemini CLI passa o arquivo a ser editado).
#
# Modos (via variavel de ambiente GEMINI_PRELOAD_MODE):
#   fail  — emite lembrete em stderr, exit 1 (bloqueia a edicao) [DEFAULT]
#   warn  — emite lembrete em stderr, exit 0 (nao bloqueia, opt-out explícito)
#
# Unlock (override do bloqueio sem mudar o modo):
#   GOVERNANCE_PRELOAD_CONFIRMED=1  — bypass do bloqueio para sessoes que ja
#                                     confirmaram o contrato. Util em ferramentas
#                                     single-round (Codex, Copilot, Gemini CLI).

set -euo pipefail

GEMINI_PRELOAD_MODE="${GEMINI_PRELOAD_MODE:-fail}"
GOVERNANCE_PRELOAD_CONFIRMED="${GOVERNANCE_PRELOAD_CONFIRMED:-0}"

file_path="${1:-}"

[[ -n "$file_path" ]] || exit 0

# Verificar apenas arquivos de codigo (nao arquivos de governanca ou docs)
case "$file_path" in
  *.go|*.py|*.ts|*.js|*.tsx|*.jsx|*.rs|*.java|*.kt|*.rb|*.sh)
    echo "LEMBRETE: antes de editar codigo, confirme que AGENTS.md e .agents/skills/agent-governance/SKILL.md foram lidos nesta sessao." >&2

    # Unlock: sessao ja confirmou o contrato
    if [[ "$GOVERNANCE_PRELOAD_CONFIRMED" == "1" ]]; then
      exit 0
    fi

    if [[ "$GEMINI_PRELOAD_MODE" == "fail" ]]; then
      echo "GEMINI_PRELOAD_MODE=fail: bloqueando edicao ate que contrato de carga seja confirmado." >&2
      echo "Para prosseguir: export GOVERNANCE_PRELOAD_CONFIRMED=1" >&2
      exit 1
    fi
    ;;
esac

exit 0
