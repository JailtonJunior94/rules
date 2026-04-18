#!/usr/bin/env bash
# Testa detect-toolchain.sh com fixtures sinteticas.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DETECT_SCRIPT="$ROOT_DIR/.agents/skills/agent-governance/scripts/detect-toolchain.sh"

PASS=0
FAIL=0

report() {
  local status="$1" name="$2"
  if [[ "$status" == "PASS" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS  $name"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL  $name"
  fi
}

json_has_key() {
  local json="$1" key="$2"
  printf '%s' "$json" | grep -q "\"$key\""
}

json_field_value() {
  local json="$1" lang="$2" field="$3"
  # Extract field value for a given language key — simple grep-based extraction
  printf '%s' "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
lang_data = data.get('$lang', {})
print(lang_data.get('$field') or '')
" 2>/dev/null
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# --- Test 1: Go project ---
mkdir -p "$tmpdir/go-proj"
cat > "$tmpdir/go-proj/go.mod" <<'EOF'
module example.com/myapp

go 1.22
EOF

output="$(bash "$DETECT_SCRIPT" "$tmpdir/go-proj" 2>/dev/null)"
if json_has_key "$output" "go"; then
  report PASS "Go project detected"
else
  report FAIL "Go project detected (output: $output)"
fi

go_test="$(json_field_value "$output" "go" "test")"
if [[ "$go_test" == "go test ./..." ]]; then
  report PASS "Go test command correct"
else
  report FAIL "Go test command correct (got: $go_test)"
fi

# --- Test 2: Node project with npm ---
mkdir -p "$tmpdir/node-proj"
cat > "$tmpdir/node-proj/package.json" <<'EOF'
{
  "name": "my-app",
  "scripts": {
    "test": "jest",
    "lint": "eslint .",
    "format": "prettier --write ."
  }
}
EOF

output="$(bash "$DETECT_SCRIPT" "$tmpdir/node-proj" 2>/dev/null)"
if json_has_key "$output" "node"; then
  report PASS "Node project detected"
else
  report FAIL "Node project detected (output: $output)"
fi

node_test="$(json_field_value "$output" "node" "test")"
if [[ "$node_test" == "npm run test" ]]; then
  report PASS "Node test command correct"
else
  report FAIL "Node test command correct (got: $node_test)"
fi

node_lint="$(json_field_value "$output" "node" "lint")"
if [[ "$node_lint" == "npm run lint" ]]; then
  report PASS "Node lint command correct"
else
  report FAIL "Node lint command correct (got: $node_lint)"
fi

node_fmt="$(json_field_value "$output" "node" "fmt")"
if [[ "$node_fmt" == "npm run format" ]]; then
  report PASS "Node fmt command correct"
else
  report FAIL "Node fmt command correct (got: $node_fmt)"
fi

# --- Test 3: Node project with pnpm ---
mkdir -p "$tmpdir/node-pnpm"
cat > "$tmpdir/node-pnpm/package.json" <<'EOF'
{
  "name": "pnpm-app",
  "scripts": {
    "test": "vitest",
    "lint": "eslint ."
  }
}
EOF
touch "$tmpdir/node-pnpm/pnpm-lock.yaml"

output="$(bash "$DETECT_SCRIPT" "$tmpdir/node-pnpm" 2>/dev/null)"
node_test="$(json_field_value "$output" "node" "test")"
if [[ "$node_test" == "pnpm run test" ]]; then
  report PASS "pnpm package manager detected"
else
  report FAIL "pnpm package manager detected (got: $node_test)"
fi

# --- Test 4: Node project with yarn ---
mkdir -p "$tmpdir/node-yarn"
cat > "$tmpdir/node-yarn/package.json" <<'EOF'
{
  "name": "yarn-app",
  "scripts": {
    "test": "jest"
  }
}
EOF
touch "$tmpdir/node-yarn/yarn.lock"

output="$(bash "$DETECT_SCRIPT" "$tmpdir/node-yarn" 2>/dev/null)"
node_test="$(json_field_value "$output" "node" "test")"
if [[ "$node_test" == "yarn run test" ]]; then
  report PASS "yarn package manager detected"
else
  report FAIL "yarn package manager detected (got: $node_test)"
fi

# --- Test 5: Python project with ruff ---
mkdir -p "$tmpdir/py-proj"
cat > "$tmpdir/py-proj/pyproject.toml" <<'EOF'
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"

[tool.ruff]
line-length = 120

[tool.pytest.ini_options]
testpaths = ["tests"]
EOF

output="$(bash "$DETECT_SCRIPT" "$tmpdir/py-proj" 2>/dev/null)"
if json_has_key "$output" "python"; then
  report PASS "Python project detected"
else
  report FAIL "Python project detected (output: $output)"
fi

py_fmt="$(json_field_value "$output" "python" "fmt")"
if [[ "$py_fmt" == "ruff format ." ]]; then
  report PASS "Python ruff fmt detected"
else
  report FAIL "Python ruff fmt detected (got: $py_fmt)"
fi

py_lint="$(json_field_value "$output" "python" "lint")"
if [[ "$py_lint" == "ruff check ." ]]; then
  report PASS "Python ruff lint detected"
else
  report FAIL "Python ruff lint detected (got: $py_lint)"
fi

py_test="$(json_field_value "$output" "python" "test")"
if [[ "$py_test" == "pytest" ]]; then
  report PASS "Python pytest detected"
else
  report FAIL "Python pytest detected (got: $py_test)"
fi

# --- Test 6: Monorepo with focus paths ---
mkdir -p "$tmpdir/monorepo/apps/web" "$tmpdir/monorepo/apps/api"
cat > "$tmpdir/monorepo/apps/web/package.json" <<'EOF'
{
  "name": "web",
  "scripts": {
    "test": "vitest"
  }
}
EOF
cat > "$tmpdir/monorepo/apps/api/package.json" <<'EOF'
{
  "name": "api",
  "scripts": {
    "test": "jest"
  }
}
EOF
touch "$tmpdir/monorepo/pnpm-workspace.yaml"
cat > "$tmpdir/monorepo/package.json" <<'EOF'
{
  "name": "monorepo-root",
  "private": true
}
EOF

output="$(DETECT_TOOLCHAIN_FOCUS_PATHS="apps/web/src/index.ts" bash "$DETECT_SCRIPT" "$tmpdir/monorepo" 2>/dev/null)"
node_test="$(json_field_value "$output" "node" "test")"
if echo "$node_test" | grep -q "web"; then
  report PASS "Focus path prioritizes web workspace"
else
  report FAIL "Focus path prioritizes web workspace (got: $node_test)"
fi

# --- Test 7: Empty project uses Makefile fallback ---
mkdir -p "$tmpdir/make-proj"
cat > "$tmpdir/make-proj/Makefile" <<'EOF'
fmt:
	echo "format"
test:
	echo "test"
lint:
	echo "lint"
EOF

output="$(bash "$DETECT_SCRIPT" "$tmpdir/make-proj" 2>/dev/null)"
if json_has_key "$output" "unknown"; then
  report PASS "Makefile fallback detected"
else
  report FAIL "Makefile fallback detected (output: $output)"
fi

make_test="$(json_field_value "$output" "unknown" "test")"
if [[ "$make_test" == "make test" ]]; then
  report PASS "Makefile test command correct"
else
  report FAIL "Makefile test command correct (got: $make_test)"
fi

# --- Test 8: Polyglot project (Go + Python) ---
mkdir -p "$tmpdir/polyglot"
cat > "$tmpdir/polyglot/go.mod" <<'EOF'
module example.com/multi

go 1.22
EOF
cat > "$tmpdir/polyglot/pyproject.toml" <<'EOF'
[project]
name = "multi"

[tool.pytest.ini_options]
testpaths = ["tests"]
EOF

output="$(bash "$DETECT_SCRIPT" "$tmpdir/polyglot" 2>/dev/null)"
if json_has_key "$output" "go" && json_has_key "$output" "python"; then
  report PASS "Polyglot (Go + Python) detected"
else
  report FAIL "Polyglot (Go + Python) detected (output: $output)"
fi

# --- Test 9: --strict mode warns about missing binaries ---
strict_output="$(bash "$DETECT_SCRIPT" --strict "$tmpdir/go-proj" 2>&1 || true)"
# golangci-lint is likely not installed in test env
if echo "$strict_output" | grep -q "golangci-lint" 2>/dev/null || echo "$strict_output" | grep -q '"go"'; then
  report PASS "--strict mode runs without error"
else
  report FAIL "--strict mode runs without error (output: $strict_output)"
fi

# --- Test 10: Valid JSON output ---
output="$(bash "$DETECT_SCRIPT" "$tmpdir/go-proj" 2>/dev/null)"
if python3 -c "import json; json.loads('''$output''')" 2>/dev/null; then
  report PASS "Output is valid JSON"
else
  report FAIL "Output is valid JSON (output: $output)"
fi

# --- Test 11: Python optional-dependencies fallback ---
mkdir -p "$tmpdir/py-deps"
cat > "$tmpdir/py-deps/pyproject.toml" <<'EOF'
[project]
name = "deptest"

[project.optional-dependencies]
dev = [
  "ruff>=0.4",
  "pytest>=8.0",
]
EOF

output="$(bash "$DETECT_SCRIPT" "$tmpdir/py-deps" 2>/dev/null)"
py_fmt="$(json_field_value "$output" "python" "fmt")"
if [[ "$py_fmt" == "ruff format ." ]]; then
  report PASS "Python ruff detected via optional-dependencies"
else
  report FAIL "Python ruff detected via optional-dependencies (got: $py_fmt)"
fi

# --- Test 12: Node with bun ---
mkdir -p "$tmpdir/node-bun"
cat > "$tmpdir/node-bun/package.json" <<'EOF'
{
  "name": "bun-app",
  "scripts": {
    "test": "bun test"
  }
}
EOF
touch "$tmpdir/node-bun/bun.lockb"

output="$(bash "$DETECT_SCRIPT" "$tmpdir/node-bun" 2>/dev/null)"
node_test="$(json_field_value "$output" "node" "test")"
if [[ "$node_test" == "bun run test" ]]; then
  report PASS "bun package manager detected"
else
  report FAIL "bun package manager detected (got: $node_test)"
fi

echo ""
echo "Resultados: $PASS passou, $FAIL falhou"
[[ "$FAIL" -eq 0 ]]
