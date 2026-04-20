#!/usr/bin/env bash
# Testes para check-budget-regression.sh.
# Uso: bash tests/test-budget-regression.sh

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/check-budget-regression.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PASSED=0
FAILED=0

pass() {
  echo "PASS  $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "FAIL  $1"
  FAILED=$((FAILED + 1))
}

# Helper: escreve baseline JSON minimal no TMP_DIR
write_baseline() {
  local file="$1"
  local go_tokens="${2:-5353}"
  local node_tokens="${3:-4722}"
  local python_tokens="${4:-4675}"
  local threshold="${5:-5}"
  cat > "$file" <<EOF
{
  "version": "1.0",
  "generated_at": "2026-04-20",
  "threshold_pct": $threshold,
  "baselines": {
    "go":     { "tokens_est": $go_tokens,     "files": ["AGENTS.md"] },
    "node":   { "tokens_est": $node_tokens,   "files": ["AGENTS.md"] },
    "python": { "tokens_est": $python_tokens, "files": ["AGENTS.md"] }
  }
}
EOF
}

# ============================================================
# 1. Script existe e e executavel
# ============================================================
if [[ -f "$SCRIPT" ]]; then
  pass "check-budget-regression: script existe"
else
  fail "check-budget-regression: script nao encontrado em $SCRIPT"
fi

# ============================================================
# 2. Uso incorreto (nenhum arquivo de baseline)
# ============================================================
if bash "$SCRIPT" --baseline "$TMP_DIR/nao-existe.json" > /dev/null 2>&1; then
  fail "check-budget-regression: baseline ausente deveria falhar"
else
  pass "check-budget-regression: baseline ausente retorna erro"
fi

# ============================================================
# 3. Passa com baselines reais commitados (caminho feliz)
# ============================================================
if bash "$SCRIPT" --committed-only > /dev/null 2>&1; then
  pass "check-budget-regression: passa com baseline commitado atual"
else
  fail "check-budget-regression: falhou com baseline commitado atual"
fi

# ============================================================
# 4. Simulacao de inflacao — script deve detectar regressao
#    Baseline artificialmente baixo para forcar falha.
# ============================================================
INFLATED_BASELINE="$TMP_DIR/inflated-baseline.json"
# go baseline = 100 tokens (muito abaixo do atual ~5353), threshold 5%
write_baseline "$INFLATED_BASELINE" 100 100 100 5

if bash "$SCRIPT" --baseline "$INFLATED_BASELINE" > /dev/null 2>&1; then
  fail "check-budget-regression: inflacao nao detectada (esperava falha)"
else
  pass "check-budget-regression: inflacao detectada corretamente"
fi

# ============================================================
# 5. Output contem delta absoluto e percentual na falha
# ============================================================
output="$(bash "$SCRIPT" --baseline "$INFLATED_BASELINE" 2>&1 || true)"
if echo "$output" | grep -qE 'delta=\+[0-9]+ \(\+[0-9]+\.[0-9]+%\)'; then
  pass "check-budget-regression: output contem delta absoluto e percentual"
else
  fail "check-budget-regression: output sem delta formatado. Output: $output"
fi

# ============================================================
# 6. Threshold configuravel via --threshold
#    Baseline com valores atuais reais, threshold 0 (qualquer delta falha)
#    Mas se tokens atuais == baseline, nao ha delta => deve passar.
# ============================================================
EXACT_BASELINE="$TMP_DIR/exact-baseline.json"
# Obter tokens atuais via context-metrics.py
current_go="$(python3 "$ROOT_DIR/scripts/context-metrics.py" --format json --committed-only 2>/dev/null \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["baselines"]["go"]["tokens_est"])')"
current_node="$(python3 "$ROOT_DIR/scripts/context-metrics.py" --format json --committed-only 2>/dev/null \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["baselines"]["node"]["tokens_est"])')"
current_python="$(python3 "$ROOT_DIR/scripts/context-metrics.py" --format json --committed-only 2>/dev/null \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["baselines"]["python"]["tokens_est"])')"

write_baseline "$EXACT_BASELINE" "$current_go" "$current_node" "$current_python" 0

if bash "$SCRIPT" --baseline "$EXACT_BASELINE" --threshold 0 --committed-only > /dev/null 2>&1; then
  pass "check-budget-regression: threshold 0 passa quando tokens iguais ao baseline"
else
  fail "check-budget-regression: threshold 0 falhou mesmo sem delta"
fi

# ============================================================
# 7. Threshold menor que delta real deve falhar (regressao real)
# ============================================================
TIGHT_BASELINE="$TMP_DIR/tight-baseline.json"
# baseline go = atual - 500 tokens, threshold 1% => delta deve exceder threshold
go_tight=$(( current_go - 500 ))
write_baseline "$TIGHT_BASELINE" "$go_tight" "$current_node" "$current_python" 1

if bash "$SCRIPT" --baseline "$TIGHT_BASELINE" --threshold 1 --committed-only > /dev/null 2>&1; then
  fail "check-budget-regression: threshold muito baixo deveria detectar regressao"
else
  pass "check-budget-regression: threshold 1% detecta regressao quando delta real > 1%"
fi

# ============================================================
# 8. Baseline sem campo threshold_pct usa default 5%
# ============================================================
NO_THRESHOLD_BASELINE="$TMP_DIR/no-threshold-baseline.json"
cat > "$NO_THRESHOLD_BASELINE" <<EOF
{
  "version": "1.0",
  "baselines": {
    "go":     { "tokens_est": $current_go,     "files": ["AGENTS.md"] },
    "node":   { "tokens_est": $current_node,   "files": ["AGENTS.md"] },
    "python": { "tokens_est": $current_python, "files": ["AGENTS.md"] }
  }
}
EOF

if bash "$SCRIPT" --baseline "$NO_THRESHOLD_BASELINE" --committed-only > /dev/null 2>&1; then
  pass "check-budget-regression: baseline sem threshold_pct usa default e passa"
else
  fail "check-budget-regression: baseline sem threshold_pct falhou inesperadamente"
fi

# ============================================================
# 9. .budget-baseline.json commitado existe no repositorio
# ============================================================
if [[ -f "$ROOT_DIR/.budget-baseline.json" ]]; then
  pass "check-budget-regression: .budget-baseline.json presente no repositorio"
else
  fail "check-budget-regression: .budget-baseline.json ausente"
fi

# ============================================================
# 10. .budget-baseline.json e JSON valido
# ============================================================
if python3 -c "import json; json.load(open('$ROOT_DIR/.budget-baseline.json'))" 2>/dev/null; then
  pass "check-budget-regression: .budget-baseline.json e JSON valido"
else
  fail "check-budget-regression: .budget-baseline.json e JSON invalido"
fi

# ============================================================
# Resumo
# ============================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
