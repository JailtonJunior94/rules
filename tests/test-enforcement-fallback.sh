#!/usr/bin/env bash
# test-enforcement-fallback.sh
# Valida procedimentos compensatorios para ambientes sem hooks (Codex/Copilot/Gemini).
#
# Cenarios cobertos:
#   1. Ambiente sem hooks: validators nao dependem de GOVERNANCE_HOOK_MODE nem .claude/hooks/
#   2. enforcement-fallback.md documenta validators criticos e procedimentos por ferramenta
#   3. Validators invocaveis standalone com exit codes corretos (2=sem args, 2=arquivo ausente, 1=invalido)
#   4. check-skill-prerequisites.sh funciona sem hooks
#   5. check-invocation-depth.sh tem default seguro quando AI_INVOCATION_DEPTH nao esta definida

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

FALLBACK_MD="$ROOT_DIR/.agents/skills/agent-governance/references/enforcement-fallback.md"
VALIDATE_TASK="$ROOT_DIR/scripts/validators/validate-task-evidence.sh"
VALIDATE_BUGFIX="$ROOT_DIR/scripts/validators/validate-bugfix-evidence.sh"
VALIDATE_REFACTOR="$ROOT_DIR/scripts/validators/validate-refactor-evidence.sh"
CHECK_DEPTH="$ROOT_DIR/scripts/lib/check-invocation-depth.sh"
CHECK_PREREQS="$ROOT_DIR/scripts/check-skill-prerequisites.sh"

# ========== 1. Ambiente sem hooks ==========
echo "=== 1. Ambiente sem hooks ==="

(
  unset GOVERNANCE_HOOK_MODE 2>/dev/null || true
  if [[ -z "${GOVERNANCE_HOOK_MODE:-}" ]]; then
    pass "no-hooks/env-unset: GOVERNANCE_HOOK_MODE ausente simula ambiente sem hooks"
  else
    fail "no-hooks/env-unset: GOVERNANCE_HOOK_MODE inesperadamente definida"
  fi
)

# Verificar que os validators nao mencionam dependencia de hooks em seu output de erro
for validator_path in "$VALIDATE_TASK" "$VALIDATE_BUGFIX" "$VALIDATE_REFACTOR"; do
  validator_name="$(basename "$validator_path")"
  output="$(bash "$validator_path" 2>&1 || true)"
  if echo "$output" | grep -qi "hook"; then
    fail "no-hooks/no-hook-dep: $validator_name menciona 'hook' no output — possivel dependencia"
  else
    pass "no-hooks/no-hook-dep: $validator_name nao depende de hooks no output de erro"
  fi
done

# ========== 2. enforcement-fallback.md documenta skills criticas ==========
echo "=== 2. Documentacao enforcement-fallback.md ==="

if [[ ! -f "$FALLBACK_MD" ]]; then
  fail "fallback-doc/exists: enforcement-fallback.md nao encontrado em $FALLBACK_MD"
else
  pass "fallback-doc/exists: enforcement-fallback.md presente"

  # Validators criticos documentados
  for validator in "validate-task-evidence.sh" "validate-bugfix-evidence.sh" "validate-refactor-evidence.sh"; do
    if grep -q "$validator" "$FALLBACK_MD"; then
      pass "fallback-doc/validator: $validator documentado"
    else
      fail "fallback-doc/validator: $validator NAO documentado em enforcement-fallback.md"
    fi
  done

  # Procedimentos por ferramenta sem hooks
  for tool in "Codex" "Copilot" "Gemini"; do
    if grep -qi "$tool" "$FALLBACK_MD"; then
      pass "fallback-doc/tool: procedimento para $tool presente"
    else
      fail "fallback-doc/tool: procedimento para $tool AUSENTE em enforcement-fallback.md"
    fi
  done

  # Gate CI compensatorio documentado
  if grep -qi "CI" "$FALLBACK_MD"; then
    pass "fallback-doc/ci-gate: gate CI compensatorio documentado"
  else
    fail "fallback-doc/ci-gate: gate CI compensatorio nao documentado"
  fi
fi

# ========== 3. Validators standalone — exit codes corretos ==========
echo "=== 3. Exit codes dos validators standalone ==="

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# 3a. Sem argumentos -> exit 2
for validator_path in "$VALIDATE_TASK" "$VALIDATE_BUGFIX" "$VALIDATE_REFACTOR"; do
  validator_name="$(basename "$validator_path")"
  actual_exit=0
  bash "$validator_path" >/dev/null 2>&1 || actual_exit=$?
  if [[ "$actual_exit" -eq 2 ]]; then
    pass "validator-standalone/no-args: $validator_name retorna exit 2 sem argumentos"
  else
    fail "validator-standalone/no-args: $validator_name retornou exit $actual_exit (esperado 2)"
  fi
done

# 3b. Arquivo inexistente -> exit 2
nonexistent="/tmp/arquivo-inexistente-$$-test.md"
for validator_path in "$VALIDATE_TASK" "$VALIDATE_BUGFIX" "$VALIDATE_REFACTOR"; do
  validator_name="$(basename "$validator_path")"
  actual_exit=0
  bash "$validator_path" "$nonexistent" >/dev/null 2>&1 || actual_exit=$?
  if [[ "$actual_exit" -eq 2 ]]; then
    pass "validator-standalone/missing-file: $validator_name retorna exit 2 para arquivo inexistente"
  else
    fail "validator-standalone/missing-file: $validator_name retornou exit $actual_exit (esperado 2)"
  fi
done

# 3c. Arquivo vazio (relatorio invalido) -> exit 1
empty_report="$tmpdir/empty_report.md"
touch "$empty_report"
for validator_path in "$VALIDATE_TASK" "$VALIDATE_BUGFIX" "$VALIDATE_REFACTOR"; do
  validator_name="$(basename "$validator_path")"
  actual_exit=0
  bash "$validator_path" "$empty_report" >/dev/null 2>&1 || actual_exit=$?
  if [[ "$actual_exit" -eq 1 ]]; then
    pass "validator-standalone/empty-report: $validator_name retorna exit 1 para relatorio invalido"
  else
    fail "validator-standalone/empty-report: $validator_name retornou exit $actual_exit (esperado 1)"
  fi
done

# ========== 4. check-skill-prerequisites.sh funciona sem hooks ==========
echo "=== 4. check-skill-prerequisites.sh sem hooks ==="

if [[ ! -f "$CHECK_PREREQS" ]]; then
  fail "prereqs/exists: check-skill-prerequisites.sh nao encontrado"
else
  pass "prereqs/exists: check-skill-prerequisites.sh presente"

  # Skill conhecida sem pre-requisitos adicionais (review) -> exit 0
  (
    unset GOVERNANCE_HOOK_MODE 2>/dev/null || true
    cd "$ROOT_DIR"
    actual_exit=0
    bash "$CHECK_PREREQS" review . >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq 0 ]]; then
      pass "prereqs/review-ok: skill 'review' satisfaz pre-requisitos sem hooks"
    else
      fail "prereqs/review-ok: skill 'review' falhou pre-requisitos (exit $actual_exit)"
    fi
  )

  # Skill desconhecida sem SKILL.md -> exit 1
  (
    unset GOVERNANCE_HOOK_MODE 2>/dev/null || true
    cd "$ROOT_DIR"
    actual_exit=0
    bash "$CHECK_PREREQS" skill-inexistente-$$-test . >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq 1 ]]; then
      pass "prereqs/unknown-skill: skill desconhecida retorna exit 1"
    else
      fail "prereqs/unknown-skill: skill desconhecida retornou exit $actual_exit (esperado 1)"
    fi
  )

  # Uso incorreto (sem argumentos) -> exit 2
  (
    cd "$ROOT_DIR"
    actual_exit=0
    bash "$CHECK_PREREQS" >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq 2 ]]; then
      pass "prereqs/no-args: sem argumentos retorna exit 2"
    else
      fail "prereqs/no-args: sem argumentos retornou exit $actual_exit (esperado 2)"
    fi
  )
fi

# ========== 5. check-invocation-depth.sh — default seguro sem env var ==========
echo "=== 5. check-invocation-depth.sh default seguro ==="

if [[ ! -f "$CHECK_DEPTH" ]]; then
  fail "depth/exists: check-invocation-depth.sh nao encontrado"
else
  pass "depth/exists: check-invocation-depth.sh presente"

  # Sem AI_INVOCATION_DEPTH definida -> exit 0 (default 0 < max 2)
  (
    unset AI_INVOCATION_DEPTH 2>/dev/null || true
    actual_exit=0
    bash "$CHECK_DEPTH" >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq 0 ]]; then
      pass "depth/default-unset: sem AI_INVOCATION_DEPTH retorna exit 0 (safe default)"
    else
      fail "depth/default-unset: sem AI_INVOCATION_DEPTH retornou exit $actual_exit (esperado 0)"
    fi
  )

  # AI_INVOCATION_DEPTH=0 -> exit 0
  (
    export AI_INVOCATION_DEPTH=0
    actual_exit=0
    bash "$CHECK_DEPTH" >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq 0 ]]; then
      pass "depth/zero: AI_INVOCATION_DEPTH=0 retorna exit 0"
    else
      fail "depth/zero: AI_INVOCATION_DEPTH=0 retornou exit $actual_exit (esperado 0)"
    fi
  )

  # AI_INVOCATION_DEPTH=1 -> exit 0 (dentro do limite de 2)
  (
    export AI_INVOCATION_DEPTH=1
    actual_exit=0
    bash "$CHECK_DEPTH" >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq 0 ]]; then
      pass "depth/one: AI_INVOCATION_DEPTH=1 retorna exit 0 (dentro do limite)"
    else
      fail "depth/one: AI_INVOCATION_DEPTH=1 retornou exit $actual_exit (esperado 0)"
    fi
  )

  # AI_INVOCATION_DEPTH=2 -> exit 1 (limite atingido)
  (
    export AI_INVOCATION_DEPTH=2
    actual_exit=0
    bash "$CHECK_DEPTH" >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq 1 ]]; then
      pass "depth/at-limit: AI_INVOCATION_DEPTH=2 retorna exit 1 (limite atingido)"
    else
      fail "depth/at-limit: AI_INVOCATION_DEPTH=2 retornou exit $actual_exit (esperado 1)"
    fi
  )

  # AI_INVOCATION_DEPTH=3 -> exit 1 (acima do limite)
  (
    export AI_INVOCATION_DEPTH=3
    actual_exit=0
    bash "$CHECK_DEPTH" >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq 1 ]]; then
      pass "depth/above-limit: AI_INVOCATION_DEPTH=3 retorna exit 1 (acima do limite)"
    else
      fail "depth/above-limit: AI_INVOCATION_DEPTH=3 retornou exit $actual_exit (esperado 1)"
    fi
  )
fi

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
