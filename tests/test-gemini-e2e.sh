#!/usr/bin/env bash
# Teste E2E dedicado para o Gemini CLI adapter.
# Valida integridade dos comandos Gemini, delegacao para skills canonicas e
# estrutura do hook de preload.

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

COMMANDS_DIR="$ROOT_DIR/.gemini/commands"
SKILLS_DIR="$ROOT_DIR/.agents/skills"
GEMINI_MD="$ROOT_DIR/GEMINI.md"
GEMINI_HOOK="$ROOT_DIR/.gemini/hooks/validate-preload.sh"

# ========== 1. GEMINI.md existe e referencia AGENTS.md ==========
echo "=== GEMINI.md ==="

if [[ -f "$GEMINI_MD" ]]; then
  pass "gemini-md: GEMINI.md existe"
else
  fail "gemini-md: GEMINI.md ausente"
fi

if grep -q 'AGENTS\.md' "$GEMINI_MD" 2>/dev/null; then
  pass "gemini-md: referencia AGENTS.md"
else
  fail "gemini-md: nao referencia AGENTS.md"
fi

if grep -q '\.agents/skills/' "$GEMINI_MD" 2>/dev/null; then
  pass "gemini-md: referencia .agents/skills/ como fonte canonica"
else
  fail "gemini-md: nao referencia .agents/skills/ como fonte canonica"
fi

# ========== 2. Cada .toml tem {{args}} placeholder ==========
echo "=== Placeholder {{args}} ==="

for toml_file in "$COMMANDS_DIR"/*.toml; do
  [[ -f "$toml_file" ]] || continue
  skill_name="$(basename "$toml_file" .toml)"
  if grep -q '{{args}}' "$toml_file"; then
    pass "gemini-args/$skill_name: {{args}} presente"
  else
    fail "gemini-args/$skill_name: {{args}} ausente em $toml_file"
  fi
done

# ========== 3. Cada .toml delega para skill canonica existente ==========
echo "=== Delegacao para skill canonica ==="

for toml_file in "$COMMANDS_DIR"/*.toml; do
  [[ -f "$toml_file" ]] || continue
  skill_name="$(basename "$toml_file" .toml)"
  skill_md="$SKILLS_DIR/$skill_name/SKILL.md"
  if [[ -f "$skill_md" ]]; then
    pass "gemini-skill/$skill_name: SKILL.md canonica existe"
  else
    fail "gemini-skill/$skill_name: SKILL.md canonica ausente em $skill_md"
  fi
done

# ========== 4. Cada .toml referencia o caminho correto da skill no prompt ==========
echo "=== Referencia ao caminho correto da skill no prompt ==="

for toml_file in "$COMMANDS_DIR"/*.toml; do
  [[ -f "$toml_file" ]] || continue
  skill_name="$(basename "$toml_file" .toml)"
  if grep -q "\.agents/skills/$skill_name" "$toml_file" 2>/dev/null; then
    pass "gemini-ref/$skill_name: prompt referencia .agents/skills/$skill_name"
  else
    fail "gemini-ref/$skill_name: prompt nao referencia .agents/skills/$skill_name"
  fi
done

# ========== 5. Cada .toml tem contrato de carga base (AGENTS.md) ==========
echo "=== Contrato de carga base no prompt ==="

for toml_file in "$COMMANDS_DIR"/*.toml; do
  [[ -f "$toml_file" ]] || continue
  skill_name="$(basename "$toml_file" .toml)"
  if grep -q 'AGENTS\.md' "$toml_file" 2>/dev/null; then
    pass "gemini-base/$skill_name: prompt menciona AGENTS.md"
  else
    fail "gemini-base/$skill_name: prompt nao menciona AGENTS.md"
  fi
done

# ========== 6. Hook validate-preload.sh existe e e funcional ==========
echo "=== Hook validate-preload ==="

if [[ -f "$GEMINI_HOOK" ]]; then
  pass "gemini-hook: validate-preload.sh existe"
else
  fail "gemini-hook: validate-preload.sh ausente"
fi

if [[ -f "$GEMINI_HOOK" ]]; then
  # Deve emitir LEMBRETE para arquivo de codigo
  hook_out="$(bash "$GEMINI_HOOK" "/tmp/test.go" 2>&1 || true)"
  if echo "$hook_out" | grep -q "LEMBRETE"; then
    pass "gemini-hook: emite LEMBRETE para arquivo .go"
  else
    fail "gemini-hook: nao emite LEMBRETE para arquivo .go"
  fi

  # Deve ser silencioso para arquivo nao-codigo
  hook_md="$(bash "$GEMINI_HOOK" "/tmp/test.md" 2>&1 || true)"
  if [[ -z "$hook_md" ]]; then
    pass "gemini-hook: silencioso para arquivo .md"
  else
    fail "gemini-hook: emitiu alerta indevido para .md"
  fi

  # Modo fail deve retornar exit 1 para codigo
  hook_fail_exit=0
  GEMINI_PRELOAD_MODE=fail bash "$GEMINI_HOOK" "/tmp/test.go" 2>/dev/null || hook_fail_exit=$?
  if [[ "$hook_fail_exit" -ne 0 ]]; then
    pass "gemini-hook-fail: exit 1 para .go em modo fail"
  else
    fail "gemini-hook-fail: exit 0 indevido para .go em modo fail"
  fi

  # Modo fail deve retornar exit 0 para nao-codigo
  hook_md_fail_exit=0
  GEMINI_PRELOAD_MODE=fail bash "$GEMINI_HOOK" "/tmp/test.md" 2>/dev/null || hook_md_fail_exit=$?
  if [[ "$hook_md_fail_exit" -eq 0 ]]; then
    pass "gemini-hook-fail: exit 0 para .md em modo fail"
  else
    fail "gemini-hook-fail: exit nao-zero indevido para .md em modo fail"
  fi

  # Modo unlock: GOVERNANCE_PRELOAD_CONFIRMED=1 deve deixar passar mesmo em modo fail
  hook_unlock_exit=0
  GEMINI_PRELOAD_MODE=fail GOVERNANCE_PRELOAD_CONFIRMED=1 bash "$GEMINI_HOOK" "/tmp/test.go" 2>/dev/null || hook_unlock_exit=$?
  if [[ "$hook_unlock_exit" -eq 0 ]]; then
    pass "gemini-hook-unlock: exit 0 com GOVERNANCE_PRELOAD_CONFIRMED=1"
  else
    fail "gemini-hook-unlock: bloqueou indevidamente com GOVERNANCE_PRELOAD_CONFIRMED=1"
  fi
fi

# ========== 7. Contagem de comandos Gemini >= 23 (core + especializados) ==========
echo "=== Contagem de comandos ==="

toml_count=0
for toml_file in "$COMMANDS_DIR"/*.toml; do
  [[ -f "$toml_file" ]] || continue
  toml_count=$((toml_count + 1))
done

if [[ "$toml_count" -ge 23 ]]; then
  pass "gemini-count: $toml_count comandos (>= 23 esperados)"
else
  fail "gemini-count: apenas $toml_count comandos (esperado >= 23)"
fi

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
