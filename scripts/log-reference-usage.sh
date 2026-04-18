#!/usr/bin/env bash
# Telemetria opcional: registra uso de skills e referencias.
# Habilitado via GOVERNANCE_TELEMETRY=1 (opt-in).
# Logs sao gravados em .agents/telemetry.log (gitignored).
#
# Uso:
#   bash scripts/log-reference-usage.sh <skill> [referencia]     — registra uso
#   bash scripts/log-reference-usage.sh --summary                — resumo da sessao
#   bash scripts/log-reference-usage.sh --summary --since 1h     — resumo da ultima hora
#
# Exemplo: bash scripts/log-reference-usage.sh go-implementation concurrency.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="${GOVERNANCE_TELEMETRY_FILE:-$ROOT_DIR/.agents/telemetry.log}"

# Summary mode
if [[ "${1:-}" == "--summary" ]]; then
  if [[ ! -f "$LOG_FILE" ]]; then
    echo "Nenhum log de telemetria encontrado."
    exit 0
  fi

  SINCE_FILTER=""
  if [[ "${2:-}" == "--since" && -n "${3:-}" ]]; then
    SINCE_FILTER="$3"
  fi

  echo "=== Resumo de Uso de Governanca ==="
  echo ""

  if [[ -n "$SINCE_FILTER" ]]; then
    echo "Periodo: ultimos $SINCE_FILTER"
  else
    echo "Periodo: toda a sessao"
  fi

  total="$(wc -l < "$LOG_FILE" | tr -d ' ')"
  echo "Total de registros: $total"
  echo ""

  echo "Skills mais usadas:"
  awk '{for(i=1;i<=NF;i++) if($i ~ /^skill=/) print substr($i,7)}' "$LOG_FILE" \
    | sort | uniq -c | sort -rn | head -10
  echo ""

  echo "Referencias mais carregadas:"
  awk '{for(i=1;i<=NF;i++) if($i ~ /^ref=/ && $i != "ref=none") print substr($i,5)}' "$LOG_FILE" \
    | sort | uniq -c | sort -rn | head -10

  # Estimate tokens loaded from references
  refs_loaded="$(awk '{for(i=1;i<=NF;i++) if($i ~ /^ref=/ && $i != "ref=none") print substr($i,5)}' "$LOG_FILE" | wc -l | tr -d ' ')"
  echo ""
  echo "Referencias carregadas: $refs_loaded (estimativa: ~${refs_loaded}x500 = ~$((refs_loaded * 500)) tokens adicionais)"

  exit 0
fi

# Log mode — requires telemetry opt-in
[[ "${GOVERNANCE_TELEMETRY:-0}" == "1" ]] || exit 0

SKILL="${1:-unknown}"
REFERENCE="${2:-none}"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '%s skill=%s ref=%s\n' "$TIMESTAMP" "$SKILL" "$REFERENCE" >> "$LOG_FILE"
