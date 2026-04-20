#!/usr/bin/env bash
# Detecta regressao de token budget comparando metricas atuais contra um baseline commitado.
#
# Uso:
#   bash scripts/check-budget-regression.sh [--baseline <arquivo>] [--threshold <pct>] [--committed-only]
#
# Opcoes:
#   --baseline <arquivo>  Arquivo JSON de baseline (default: .budget-baseline.json)
#   --threshold <pct>     Percentual maximo de crescimento aceito (default: 5)
#   --committed-only      Passar --committed-only ao context-metrics.py (padrao CI)
#
# Retorna:
#   0 — todos os stacks dentro do threshold
#   1 — pelo menos um stack excedeu o threshold
#   2 — erro de uso ou dependencia ausente
#
# Processo de atualizacao do baseline:
#   1. Editar referencias ou skills conforme necessario.
#   2. Rodar: python3 scripts/context-metrics.py --format json --committed-only > .tmp-metrics.json
#   3. Atualizar .budget-baseline.json com os novos valores de tokens_est.
#   4. Commitar .budget-baseline.json junto com as mudancas de skill/referencia.
#   5. O threshold padrao (5%) tolera pequenas variacoes; aumentos maiores exigem
#      atualizacao explicita do baseline para documentar a decisao de custo.
#
# Exemplo de invocacao manual:
#   bash scripts/check-budget-regression.sh
#   bash scripts/check-budget-regression.sh --threshold 10
#   bash scripts/check-budget-regression.sh --baseline custom-baseline.json

set -euo pipefail

BASELINE_FILE=".budget-baseline.json"
THRESHOLD_PCT=""
COMMITTED_ONLY_FLAG=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline)
      if [[ $# -lt 2 ]]; then
        echo "ERRO: --baseline requer um argumento" >&2
        exit 2
      fi
      BASELINE_FILE="$2"
      shift 2
      ;;
    --threshold)
      if [[ $# -lt 2 ]]; then
        echo "ERRO: --threshold requer um argumento numerico" >&2
        exit 2
      fi
      THRESHOLD_PCT="$2"
      shift 2
      ;;
    --committed-only)
      COMMITTED_ONLY_FLAG="--committed-only"
      shift
      ;;
    -*)
      echo "Opcao desconhecida: $1" >&2
      echo "Uso: $0 [--baseline <arquivo>] [--threshold <pct>] [--committed-only]" >&2
      exit 2
      ;;
    *)
      echo "Argumento inesperado: $1" >&2
      exit 2
      ;;
  esac
done

# Resolver baseline relativo ao ROOT_DIR quando nao for caminho absoluto
if [[ "$BASELINE_FILE" != /* ]]; then
  BASELINE_FILE="$ROOT_DIR/$BASELINE_FILE"
fi

if [[ ! -f "$BASELINE_FILE" ]]; then
  echo "ERRO: arquivo de baseline nao encontrado: $BASELINE_FILE" >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERRO: python3 nao encontrado" >&2
  exit 2
fi

METRICS_SCRIPT="$ROOT_DIR/scripts/context-metrics.py"
if [[ ! -f "$METRICS_SCRIPT" ]]; then
  echo "ERRO: script de metricas nao encontrado: $METRICS_SCRIPT" >&2
  exit 2
fi

echo "=== Budget Regression Check ==="
echo "Baseline: $BASELINE_FILE"

TMP_CURRENT="$(mktemp)"
trap 'rm -f "$TMP_CURRENT"' EXIT

# Obter metricas atuais em JSON
# shellcheck disable=SC2086
if ! python3 "$METRICS_SCRIPT" --format json $COMMITTED_ONLY_FLAG > "$TMP_CURRENT" 2>/dev/null; then
  echo "ERRO: context-metrics.py falhou" >&2
  exit 2
fi

if [[ ! -s "$TMP_CURRENT" ]]; then
  echo "ERRO: context-metrics.py nao retornou saida" >&2
  exit 2
fi

# Executar comparacao via Python (evita dependencias de jq)
exit_code=0
python3 - "$TMP_CURRENT" "$BASELINE_FILE" "$THRESHOLD_PCT" <<'PYEOF' || exit_code=$?
import json
import sys

current_file  = sys.argv[1]
baseline_file = sys.argv[2]
threshold_override = sys.argv[3]  # empty string means "use baseline value"

with open(current_file, encoding="utf-8") as f:
    current = json.load(f)
with open(baseline_file, encoding="utf-8") as f:
    baseline = json.load(f)

default_threshold = float(threshold_override) if threshold_override else float(baseline.get("threshold_pct", 5))

violations = []
rows = []

for stack, bdata in baseline.get("baselines", {}).items():
    bval = bdata["tokens_est"]
    cdata = current.get("baselines", {}).get(stack, {})
    cval = cdata.get("tokens_est", 0)

    if bval == 0:
        rows.append(f"  SKIP  {stack}: baseline=0 (divisao por zero)")
        continue

    delta_abs = cval - bval
    delta_pct = (delta_abs / bval) * 100
    threshold = default_threshold

    status = "OK  "
    if delta_pct > threshold:
        status = "FAIL"
        violations.append({
            "stack": stack,
            "baseline": bval,
            "current": cval,
            "delta_abs": delta_abs,
            "delta_pct": delta_pct,
            "threshold": threshold,
        })

    rows.append(
        f"  {status}  {stack}: baseline={bval} atual={cval} "
        f"delta={delta_abs:+d} ({delta_pct:+.1f}%) threshold={threshold:.0f}%"
    )

print("\n".join(rows))

if violations:
    print("\nREGRESSAO DETECTADA:")
    for v in violations:
        print(
            f"  {v['stack']}: {v['current']} tokens "
            f"(+{v['delta_abs']} / +{v['delta_pct']:.1f}%) "
            f"excede threshold de {v['threshold']:.0f}%"
        )
    print(
        "\nRecomendacao: revisar referencias adicionadas ou atualizar "
        ".budget-baseline.json se o aumento for intencional."
    )
    sys.exit(1)
else:
    print("\nOK: todos os stacks dentro do threshold")
    sys.exit(0)
PYEOF

exit "$exit_code"
