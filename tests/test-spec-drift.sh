#!/usr/bin/env bash
# Testes para scripts/check-spec-drift.sh e scripts/check-rf-coverage.sh.
# Valida deteccao semantica de drift e cobertura de requisitos.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

DRIFT_SCRIPT="$ROOT_DIR/scripts/check-spec-drift.sh"
COVERAGE_SCRIPT="$ROOT_DIR/scripts/check-rf-coverage.sh"

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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# ---------------------------------------------------------------------------
# Fixtures helpers
# ---------------------------------------------------------------------------
make_prd() {
  local path="$1"; shift
  cat > "$path"
}

make_tasks() {
  local path="$1"; shift
  cat > "$path"
}

# ---------------------------------------------------------------------------
# 1. Scripts existem e sao executaveis
# ---------------------------------------------------------------------------
echo "=== Existencia dos scripts ==="

if [[ -f "$DRIFT_SCRIPT" ]]; then
  pass "spec-drift: check-spec-drift.sh existe"
else
  fail "spec-drift: check-spec-drift.sh ausente"
fi

if [[ -f "$COVERAGE_SCRIPT" ]]; then
  pass "rf-coverage: check-rf-coverage.sh existe"
else
  fail "rf-coverage: check-rf-coverage.sh ausente"
fi

# ---------------------------------------------------------------------------
# 2. check-spec-drift.sh: sem drift quando todos os RFs estao cobertos
# ---------------------------------------------------------------------------
echo "=== Sem drift: todos os RFs cobertos ==="

dir1="$tmpdir/case-no-drift"
mkdir -p "$dir1"

make_prd "$dir1/prd.md" <<'EOF'
# PRD Feature X

## Requisitos Funcionais

- RF-01: O sistema deve autenticar usuarios.
- RF-02: O sistema deve autorizar operacoes.
- RF-03: O sistema deve auditar acessos.
EOF

make_tasks "$dir1/tasks.md" <<'EOF'
# Tasks

## Tarefa 1 (RF-01, RF-02)
Implementar autenticacao e autorizacao.

## Tarefa 2 (RF-03)
Implementar auditoria de acessos.
EOF

if bash "$DRIFT_SCRIPT" "$dir1/tasks.md" 2>/dev/null; then
  pass "spec-drift/no-drift: retornou 0 quando todos os RFs cobertos"
else
  fail "spec-drift/no-drift: falhou inesperadamente"
fi

# ---------------------------------------------------------------------------
# 3. check-spec-drift.sh: detecta drift quando RF ausente em tasks
# ---------------------------------------------------------------------------
echo "=== Drift detectado: RF ausente ==="

dir2="$tmpdir/case-drift"
mkdir -p "$dir2"

make_prd "$dir2/prd.md" <<'EOF'
# PRD Feature Y

## Requisitos Funcionais

- RF-01: Criar usuario.
- RF-02: Atualizar usuario.
- RF-04: Deletar usuario.
EOF

make_tasks "$dir2/tasks.md" <<'EOF'
# Tasks

## Tarefa 1 (RF-01)
Implementar criacao de usuario.

## Tarefa 2 (RF-02)
Implementar atualizacao de usuario.
EOF
# RF-04 esta no PRD mas nao em tasks.md -> deve detectar drift

drift_exit=0
bash "$DRIFT_SCRIPT" "$dir2/tasks.md" 2>/dev/null || drift_exit=$?

if [[ "$drift_exit" -ne 0 ]]; then
  pass "spec-drift/drift: retornou != 0 quando RF ausente em tasks"
else
  fail "spec-drift/drift: retornou 0 indevido quando RF-04 ausente"
fi

# Verificar que a mensagem menciona o RF ausente
drift_output="$(bash "$DRIFT_SCRIPT" "$dir2/tasks.md" 2>&1 || true)"
if echo "$drift_output" | grep -q "RF-04\|RF04"; then
  pass "spec-drift/drift-message: mensagem de drift menciona RF-04"
else
  fail "spec-drift/drift-message: mensagem nao menciona RF-04"
fi

# ---------------------------------------------------------------------------
# 4. check-spec-drift.sh: sem spec nao e erro
# ---------------------------------------------------------------------------
echo "=== Sem spec files ==="

dir3="$tmpdir/case-no-spec"
mkdir -p "$dir3"
echo "# Tasks sem spec" > "$dir3/tasks.md"

if bash "$DRIFT_SCRIPT" "$dir3/tasks.md" 2>/dev/null; then
  pass "spec-drift/no-spec: retornou 0 quando prd.md ausente"
else
  fail "spec-drift/no-spec: falhou quando prd.md ausente (deveria ser OK)"
fi

# ---------------------------------------------------------------------------
# 5. check-spec-drift.sh: error em tasks.md ausente
# ---------------------------------------------------------------------------
echo "=== Tasks ausentes ==="

missing_exit=0
bash "$DRIFT_SCRIPT" "$tmpdir/nonexistent/tasks.md" 2>/dev/null || missing_exit=$?

if [[ "$missing_exit" -eq 2 ]]; then
  pass "spec-drift/missing-tasks: exit 2 quando tasks.md nao existe"
else
  fail "spec-drift/missing-tasks: exit esperado 2, obtido $missing_exit"
fi

# ---------------------------------------------------------------------------
# 6. check-rf-coverage.sh: cobertura completa
# ---------------------------------------------------------------------------
echo "=== RF Coverage: completa ==="

dir4="$tmpdir/case-full-coverage"
mkdir -p "$dir4"

make_prd "$dir4/prd.md" <<'EOF'
## Requisitos
- RF-01: Requisito A.
- RF-02: Requisito B.
EOF

make_tasks "$dir4/tasks.md" <<'EOF'
Implementar RF-01 e RF-02.
EOF

if bash "$COVERAGE_SCRIPT" "$dir4/prd.md" "$dir4/tasks.md" 2>/dev/null; then
  pass "rf-coverage/full: retornou 0 com cobertura completa"
else
  fail "rf-coverage/full: falhou com cobertura completa"
fi

# ---------------------------------------------------------------------------
# 7. check-rf-coverage.sh: cobertura incompleta
# ---------------------------------------------------------------------------
echo "=== RF Coverage: incompleta ==="

dir5="$tmpdir/case-partial-coverage"
mkdir -p "$dir5"

make_prd "$dir5/prd.md" <<'EOF'
## Requisitos
- RF-01: Requisito A.
- RF-02: Requisito B.
- REQ-03: Requisito C.
EOF

make_tasks "$dir5/tasks.md" <<'EOF'
Implementar RF-01 apenas.
EOF

cov_exit=0
bash "$COVERAGE_SCRIPT" "$dir5/prd.md" "$dir5/tasks.md" 2>/dev/null || cov_exit=$?

if [[ "$cov_exit" -ne 0 ]]; then
  pass "rf-coverage/partial: retornou != 0 com cobertura incompleta"
else
  fail "rf-coverage/partial: retornou 0 indevido com RF-02/REQ-03 ausentes"
fi

# ---------------------------------------------------------------------------
# 8. check-spec-drift.sh: hash-based drift (spec-hash presente)
# ---------------------------------------------------------------------------
echo "=== Hash-based drift ==="

dir6="$tmpdir/case-hash"
mkdir -p "$dir6"

make_prd "$dir6/prd.md" <<'EOF'
# PRD Hash Test
- RF-01: Requisito unico.
EOF

# Calcular hash real do prd.md
if command -v sha256sum >/dev/null 2>&1; then
  real_hash="$(sha256sum "$dir6/prd.md" | cut -d' ' -f1 | head -c 8)"
elif command -v shasum >/dev/null 2>&1; then
  real_hash="$(shasum -a 256 "$dir6/prd.md" | cut -d' ' -f1 | head -c 8)"
else
  real_hash=""
fi

if [[ -n "$real_hash" ]]; then
  # tasks.md com hash correto — sem drift
  make_tasks "$dir6/tasks.md" <<EOF
<!-- spec-hash-prd: ${real_hash} -->
Implementar RF-01.
EOF

  if bash "$DRIFT_SCRIPT" "$dir6/tasks.md" 2>/dev/null; then
    pass "spec-drift/hash-match: sem drift com hash correto"
  else
    fail "spec-drift/hash-match: falhou com hash correto"
  fi

  # tasks.md com hash errado — deve detectar drift
  make_tasks "$dir6/tasks-wrong.md" <<'EOF'
<!-- spec-hash-prd: deadbeef -->
Implementar RF-01.
EOF

  hash_drift_exit=0
  bash "$DRIFT_SCRIPT" "$dir6/tasks-wrong.md" 2>/dev/null || hash_drift_exit=$?

  if [[ "$hash_drift_exit" -ne 0 ]]; then
    pass "spec-drift/hash-mismatch: detectou drift com hash errado"
  else
    fail "spec-drift/hash-mismatch: nao detectou drift com hash errado"
  fi
else
  pass "spec-drift/hash: sha nao disponivel, teste de hash ignorado"
  pass "spec-drift/hash-mismatch: (skipped)"
fi

# ---------------------------------------------------------------------------
# 9. compute-spec-hash.sh: helper cross-platform
# ---------------------------------------------------------------------------
echo "=== compute-spec-hash.sh ==="

HASH_HELPER="$ROOT_DIR/scripts/lib/compute-spec-hash.sh"

if [[ -f "$HASH_HELPER" ]]; then
  pass "compute-spec-hash: script existe"
else
  fail "compute-spec-hash: script ausente em scripts/lib/compute-spec-hash.sh"
fi

if [[ -x "$HASH_HELPER" ]]; then
  pass "compute-spec-hash: script e executavel"
else
  fail "compute-spec-hash: script nao e executavel"
fi

# Arquivo ausente deve retornar exit != 0
hash_missing_exit=0
bash "$HASH_HELPER" "$tmpdir/nonexistent.md" 2>/dev/null || hash_missing_exit=$?
if [[ "$hash_missing_exit" -ne 0 ]]; then
  pass "compute-spec-hash/missing-file: exit != 0 para arquivo inexistente"
else
  fail "compute-spec-hash/missing-file: deveria falhar para arquivo inexistente"
fi

# Sem argumento deve retornar exit != 0
hash_noarg_exit=0
bash "$HASH_HELPER" 2>/dev/null || hash_noarg_exit=$?
if [[ "$hash_noarg_exit" -ne 0 ]]; then
  pass "compute-spec-hash/no-arg: exit != 0 sem argumento"
else
  fail "compute-spec-hash/no-arg: deveria falhar sem argumento"
fi

# Hash de arquivo real deve ter 8 chars hexadecimais
hash_input="$tmpdir/hash-input.md"
echo "# Conteudo de teste para hash" > "$hash_input"
hash_result="$(bash "$HASH_HELPER" "$hash_input" 2>/dev/null || true)"
if [[ "${#hash_result}" -eq 8 ]] && echo "$hash_result" | grep -Eq '^[a-f0-9]{8}$'; then
  pass "compute-spec-hash/output: retorna 8 chars hexadecimais"
else
  fail "compute-spec-hash/output: esperado 8 chars hex, obtido '${hash_result}'"
fi

# Hash deve ser determinístico (mesmo arquivo = mesmo hash)
hash_result2="$(bash "$HASH_HELPER" "$hash_input" 2>/dev/null || true)"
if [[ "$hash_result" == "$hash_result2" ]]; then
  pass "compute-spec-hash/deterministic: mesmo arquivo produz mesmo hash"
else
  fail "compute-spec-hash/deterministic: hash nao e determinístico"
fi

# Hash deve mudar quando o conteudo muda
echo "# Conteudo diferente" > "$hash_input"
hash_result3="$(bash "$HASH_HELPER" "$hash_input" 2>/dev/null || true)"
if [[ "$hash_result" != "$hash_result3" ]]; then
  pass "compute-spec-hash/sensitivity: hash muda com conteudo diferente"
else
  fail "compute-spec-hash/sensitivity: hash nao mudou apos alteracao de conteudo"
fi

# ---------------------------------------------------------------------------
# 10. check-invocation-depth.sh existe
# ---------------------------------------------------------------------------
echo "=== Invocation depth script ==="

DEPTH_SCRIPT="$ROOT_DIR/scripts/lib/check-invocation-depth.sh"

if [[ -f "$DEPTH_SCRIPT" ]]; then
  pass "depth-control: check-invocation-depth.sh existe"
else
  fail "depth-control: check-invocation-depth.sh ausente"
fi

# Profundidade 0 deve passar
if AI_INVOCATION_DEPTH=0 bash "$DEPTH_SCRIPT" > /dev/null 2>&1; then
  pass "depth-control/zero: exit 0 quando profundidade=0"
else
  fail "depth-control/zero: falhou com profundidade=0"
fi

# Profundidade no limite (2) deve passar (limite e exclusivo: 0,1 passam; 2 bloqueia)
depth_at_limit_exit=0
AI_INVOCATION_DEPTH=2 bash "$DEPTH_SCRIPT" > /dev/null 2>&1 || depth_at_limit_exit=$?
if [[ "$depth_at_limit_exit" -ne 0 ]]; then
  pass "depth-control/at-limit: exit != 0 quando profundidade=2 (igual ao max)"
else
  fail "depth-control/at-limit: deveria bloquear com profundidade=2"
fi

# Profundidade acima do limite deve bloquear
depth_exit=0
AI_INVOCATION_DEPTH=3 bash "$DEPTH_SCRIPT" > /dev/null 2>&1 || depth_exit=$?
if [[ "$depth_exit" -ne 0 ]]; then
  pass "depth-control/exceeded: exit != 0 quando profundidade=3"
else
  fail "depth-control/exceeded: deveria bloquear com profundidade=3"
fi

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
