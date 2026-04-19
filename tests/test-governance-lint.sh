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

# Testar com input valido (campos semanticos com >= 5 palavras cada)
echo '[{"id":"BUG-001","severity":"major","file":"test.go","line":1,"reproduction":"chamar funcao X sem parametro Y","expected":"retornar erro descritivo ao chamador","actual":"panic nil pointer dereference em producao"}]' > /tmp/gov-lint-valid.json
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

# ========== 7. validate-bugfix-evidence.sh existe e funciona ==========
echo "=== Bugfix evidence validator ==="

bugfix_validator="$ROOT_DIR/.claude/scripts/validate-bugfix-evidence.sh"

if [[ -f "$bugfix_validator" ]]; then
  pass "validate-bugfix-evidence: arquivo existe"
else
  fail "validate-bugfix-evidence: arquivo ausente"
fi

if [[ -f "$bugfix_validator" ]]; then
  # Relatorio valido deve passar
  cat > /tmp/gov-bugfix-valid.md <<'EOF'
# Relatorio de Bugfix

- Total de bugs no escopo: 1
- Corrigidos: 1

## Bugs
- ID: BUG-001
- Severidade: major
- Estado: fixed
- Causa raiz: nil pointer no handler de autenticacao
- Arquivos alterados: internal/auth/handler.go
- Teste de regressao: TestAuthHandler_NilToken
- Validacao: go test ./internal/auth/... pass

## Comandos Executados
- go test ./internal/auth/... -> PASS

## Riscos Residuais
- Nenhum

- Estado final: done
EOF

  if bash "$bugfix_validator" /tmp/gov-bugfix-valid.md > /dev/null 2>&1; then
    pass "validate-bugfix-evidence: aceita relatorio valido"
  else
    fail "validate-bugfix-evidence: rejeitou relatorio valido"
  fi
  rm -f /tmp/gov-bugfix-valid.md

  # Relatorio invalido (sem estado terminal) deve falhar
  cat > /tmp/gov-bugfix-invalid.md <<'EOF'
# Relatorio Incompleto
Sem secoes obrigatorias.
EOF

  if bash "$bugfix_validator" /tmp/gov-bugfix-invalid.md > /dev/null 2>&1; then
    fail "validate-bugfix-evidence: aceitou relatorio invalido"
  else
    pass "validate-bugfix-evidence: rejeitou relatorio invalido"
  fi
  rm -f /tmp/gov-bugfix-invalid.md
fi

# ========== 8. validate-refactor-evidence.sh existe e funciona ==========
echo "=== Refactor evidence validator ==="

refactor_validator="$ROOT_DIR/.claude/scripts/validate-refactor-evidence.sh"

if [[ -f "$refactor_validator" ]]; then
  pass "validate-refactor-evidence: arquivo existe"
else
  fail "validate-refactor-evidence: arquivo ausente"
fi

if [[ -f "$refactor_validator" ]]; then
  # Relatorio valido (advisory mode) deve passar
  cat > /tmp/gov-refactor-valid.md <<'EOF'
# Relatorio de Refatoracao

## Escopo
- Alvo: internal/order/domain.go
- Modo: advisory
- Estado: done

## Invariantes Preservadas
- Contrato publico OrderRepository mantido

## Mudancas Propostas ou Aplicadas
- Extrair calculo de preco para metodo isolado

## Comandos Executados
- go test ./internal/order/... -> PASS

## Resultados de Validacao
- Testes: pass
- Lint: pass
- Veredito do Revisor: n/a

## Suposicoes
- Nenhuma

## Riscos Residuais
- Nenhum
EOF

  if bash "$refactor_validator" /tmp/gov-refactor-valid.md > /dev/null 2>&1; then
    pass "validate-refactor-evidence: aceita relatorio valido (advisory)"
  else
    fail "validate-refactor-evidence: rejeitou relatorio valido"
  fi
  rm -f /tmp/gov-refactor-valid.md

  # Relatorio de execution sem veredito do revisor deve falhar
  cat > /tmp/gov-refactor-no-verdict.md <<'EOF'
## Escopo
- Modo: execution
- Estado: done

## Invariantes Preservadas
- Invariante A

## Mudancas Propostas ou Aplicadas
- Mudanca X

## Comandos Executados
- cmd -> result

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Riscos Residuais
- Nenhum
EOF

  if bash "$refactor_validator" /tmp/gov-refactor-no-verdict.md > /dev/null 2>&1; then
    fail "validate-refactor-evidence: aceitou execution sem veredito do revisor"
  else
    pass "validate-refactor-evidence: rejeitou execution sem veredito do revisor"
  fi
  rm -f /tmp/gov-refactor-no-verdict.md
fi

# ========== 9. Parse-hook-input.sh existe ==========
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
