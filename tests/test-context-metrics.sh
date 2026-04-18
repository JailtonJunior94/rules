#!/usr/bin/env bash
# Gates de economia de contexto e perfil minimal do Codex.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
METRICS_SCRIPT="$ROOT_DIR/scripts/context-metrics.py"

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

metrics_json="$(python3 "$METRICS_SCRIPT" --format json)"

if [[ -n "$metrics_json" ]]; then
  pass "context-metrics: script retorna JSON"
else
  fail "context-metrics: script nao retornou JSON"
fi

check_baseline_budget() {
  local stack="$1"
  local max_tokens="$2"
  local tokens
  tokens="$(METRICS_JSON="$metrics_json" python3 - "$stack" <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["METRICS_JSON"])
print(payload["baselines"][sys.argv[1]]["tokens_est"])
PY
)"

  if [[ "$tokens" -le "$max_tokens" ]]; then
    pass "context-budget/$stack: ${tokens} <= ${max_tokens}"
  else
    fail "context-budget/$stack: ${tokens} > ${max_tokens}"
  fi
}

check_baseline_budget "go" 4500
check_baseline_budget "node" 3600
check_baseline_budget "python" 3600

if METRICS_JSON="$metrics_json" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["METRICS_JSON"])
for item in payload["wrappers"]:
    if item["words"] > 80:
        raise SystemExit(1)
PY
then
  pass "wrapper-budget: wrappers <= 80 palavras"
else
  fail "wrapper-budget: wrapper excede 80 palavras"
fi

if METRICS_JSON="$metrics_json" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["METRICS_JSON"])
for item in payload["skills"]:
    if item["words"] > 1200:
        raise SystemExit(1)
PY
then
  pass "skill-budget: cada SKILL.md <= 1200 palavras"
else
  fail "skill-budget: algum SKILL.md excede 1200 palavras"
fi

if METRICS_JSON="$metrics_json" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["METRICS_JSON"])
expected = ["agent-governance", "execute-task", "refactor", "review", "bugfix"]
if payload["codex"]["skills"] != expected:
    raise SystemExit(1)
PY
then
  pass "codex-minimal: config raiz usa baseline enxuto esperado"
else
  fail "codex-minimal: config raiz diverge do baseline enxuto"
fi

if grep -q '".agents/skills/analyze-project"' "$ROOT_DIR/.codex/config.toml" 2>/dev/null; then
  fail "codex-regression: analyze-project presente no perfil enxuto"
else
  pass "codex-regression: planning skill ausente do perfil enxuto"
fi

echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
