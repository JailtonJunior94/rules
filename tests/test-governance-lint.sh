#!/usr/bin/env bash
# Lint de governance files: valida integridade de frontmatter, placeholders e schema.
# Uso: bash tests/test-governance-lint.sh

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

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

# ========== 1. Templates sem placeholders renderizados ==========
echo "=== Templates ==="

# O template deve ter placeholders {{ }}
if grep -q '{{' "$ROOT_DIR/.agents/skills/analyze-project/assets/agents-template.md"; then
  pass "agents-template: contem placeholders esperados"
else
  fail "agents-template: placeholders ausentes"
fi

if grep -q '{{' "$ROOT_DIR/.agents/skills/analyze-project/assets/ai-tool-template.md"; then
  pass "ai-tool-template: contem placeholders esperados"
else
  fail "ai-tool-template: placeholders ausentes"
fi

# ========== 2. Arquivos gerados nao devem ter placeholders ==========
echo "=== Arquivos gerados (local) ==="

for f in AGENTS.md CLAUDE.md GEMINI.md; do
  if [[ -f "$ROOT_DIR/$f" ]]; then
    if grep -q '{{' "$ROOT_DIR/$f"; then
      fail "$f: placeholders {{ }} remanescentes"
    else
      pass "$f: sem placeholders remanescentes"
    fi
  fi
done

# ========== 3. Frontmatter de skills ==========
echo "=== Frontmatter de skills ==="

for skill_file in "$ROOT_DIR/.agents/skills"/*/SKILL.md; do
  skill_name="$(basename "$(dirname "$skill_file")")"

  # Deve ter frontmatter com name, version, description
  if head -1 "$skill_file" | grep -q '^---$'; then
    pass "frontmatter-exists: $skill_name"
  else
    fail "frontmatter-exists: $skill_name (sem frontmatter)"
    continue
  fi

  for field in name version description; do
    if awk '/^---$/{n++; next} n==1{print}' "$skill_file" | grep -q "^$field:"; then
      pass "frontmatter-$field: $skill_name"
    else
      fail "frontmatter-$field: $skill_name (campo $field ausente)"
    fi
  done
done

# ========== 4. Schema version no generate-governance.sh ==========
echo "=== Schema version ==="

schema_version="$(grep -o 'GOVERNANCE_SCHEMA_VERSION="[^"]*"' "$ROOT_DIR/.agents/skills/analyze-project/scripts/generate-governance.sh" 2>/dev/null | head -1 | sed 's/.*="//;s/"//' || true)"
if [[ -n "$schema_version" ]]; then
  pass "schema-version: definida ($schema_version)"
else
  fail "schema-version: GOVERNANCE_SCHEMA_VERSION nao encontrada em generate-governance.sh"
fi

# Deve corresponder ao VERSION file
version_file="$(cat "$ROOT_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
if [[ "$schema_version" == "$version_file" ]]; then
  pass "schema-version-match: schema ($schema_version) == VERSION ($version_file)"
else
  fail "schema-version-match: schema ($schema_version) != VERSION ($version_file)"
fi

# ========== 5. Bug schema JSON valido ==========
echo "=== Bug schema ==="

bug_schema="$ROOT_DIR/.agents/skills/agent-governance/references/bug-schema.json"
if python3 -c "import json; json.load(open('$bug_schema'))" 2>/dev/null; then
  pass "bug-schema: JSON valido"
else
  fail "bug-schema: JSON invalido"
fi

# ========== 6. Validate-bug-schema.sh existe e e executavel ==========
validate_bug="$ROOT_DIR/scripts/lib/validate-bug-schema.sh"
if [[ -f "$validate_bug" ]]; then
  pass "validate-bug-schema: arquivo existe"
else
  fail "validate-bug-schema: arquivo ausente"
fi

# Testar com input valido
echo '[{"id":"BUG-001","severity":"major","file":"test.go","line":1,"reproduction":"x","expected":"y","actual":"z"}]' > /tmp/gov-lint-valid.json
if bash "$validate_bug" /tmp/gov-lint-valid.json > /dev/null 2>&1; then
  pass "validate-bug-schema: aceita input valido"
else
  fail "validate-bug-schema: rejeita input valido"
fi
rm -f /tmp/gov-lint-valid.json

# Testar com input invalido
echo '[{"id":"bad"}]' > /tmp/gov-lint-invalid.json
if bash "$validate_bug" /tmp/gov-lint-invalid.json > /dev/null 2>&1; then
  fail "validate-bug-schema: aceita input invalido"
else
  pass "validate-bug-schema: rejeita input invalido"
fi
rm -f /tmp/gov-lint-invalid.json

# ========== 7. Parse-hook-input.sh existe ==========
echo "=== Hooks lib ==="

parse_hook="$ROOT_DIR/scripts/lib/parse-hook-input.sh"
if [[ -f "$parse_hook" ]]; then
  pass "parse-hook-input: arquivo existe"
else
  fail "parse-hook-input: arquivo ausente"
fi

# Testar que extrai file_path
result="$(echo '{"tool_input":{"file_path":"/tmp/test.go"}}' | bash -c "source '$parse_hook' && parse_file_path" 2>/dev/null || true)"
if [[ "$result" == "/tmp/test.go" ]]; then
  pass "parse-hook-input: extrai file_path corretamente"
else
  fail "parse-hook-input: resultado inesperado '$result'"
fi

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
