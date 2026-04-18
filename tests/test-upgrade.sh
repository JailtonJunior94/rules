#!/usr/bin/env bash
# Testes para upgrade.sh.
# Uso: bash tests/test-upgrade.sh

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
UPGRADE_SCRIPT="$ROOT_DIR/upgrade.sh"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"
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

# ============================================================
# Setup: instalar governanca em projeto temporario (modo copy)
# ============================================================
PROJECT="$TMP_DIR/upgrade-project"
mkdir -p "$PROJECT"
echo "module upgrade-test" > "$PROJECT/go.mod"

LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools claude,gemini --langs all "$PROJECT" > /dev/null 2>&1

if [[ ! -f "$PROJECT/AGENTS.md" ]]; then
  echo "ERRO: setup falhou — AGENTS.md nao gerado"
  exit 1
fi

# ============================================================
# Caso 1: skills atualizadas — check retorna 0
# ============================================================
if bash "$UPGRADE_SCRIPT" --check "$PROJECT" > /dev/null 2>&1; then
  pass "up-to-date: --check retorna 0"
else
  fail "up-to-date: --check retorna erro inesperado"
fi

# ============================================================
# Caso 2: conteudo divergente detectado
# ============================================================
echo "# modificado" >> "$PROJECT/.agents/skills/agent-governance/SKILL.md"

output="$(bash "$UPGRADE_SCRIPT" --check "$PROJECT" 2>&1 || true)"
if echo "$output" | grep -qi "DIVERGENTE\|DESATUALIZADA"; then
  pass "divergent: --check detecta divergencia"
else
  fail "divergent: --check nao detecta divergencia"
fi

# ============================================================
# Caso 3: upgrade corrige divergencia
# ============================================================
bash "$UPGRADE_SCRIPT" "$PROJECT" > /dev/null 2>&1

# Apos upgrade, checar deve passar
if bash "$UPGRADE_SCRIPT" --check "$PROJECT" > /dev/null 2>&1; then
  pass "upgrade-fix: divergencia corrigida"
else
  fail "upgrade-fix: divergencia persiste apos upgrade"
fi

# ============================================================
# Caso 4: skill ausente detectada
# ============================================================
rm -rf "$PROJECT/.agents/skills/review"

output="$(bash "$UPGRADE_SCRIPT" --check "$PROJECT" 2>&1 || true)"
if echo "$output" | grep -qi "AUSENTE.*review"; then
  pass "missing-skill: skill ausente detectada"
else
  fail "missing-skill: skill ausente nao detectada"
fi

# ============================================================
# Caso 5: symlink detectado (pula copia)
# ============================================================
SYMLINK_PROJECT="$TMP_DIR/symlink-project"
mkdir -p "$SYMLINK_PROJECT"
echo "module symlink-test" > "$SYMLINK_PROJECT/go.mod"

# Instalar com symlinks (default)
bash "$INSTALL_SCRIPT" --tools claude --langs all "$SYMLINK_PROJECT" > /dev/null 2>&1

# Forcar divergencia artificial no source nao e possivel sem alterar o repo,
# mas podemos verificar que --check nao falha em projeto com symlinks
if bash "$UPGRADE_SCRIPT" --check "$SYMLINK_PROJECT" > /dev/null 2>&1; then
  pass "symlink: --check passa em projeto com symlinks"
else
  fail "symlink: --check falha em projeto com symlinks"
fi

# ============================================================
# Caso 6: diretorio inexistente
# ============================================================
if bash "$UPGRADE_SCRIPT" "$TMP_DIR/nonexistent" > /dev/null 2>&1; then
  fail "nonexistent-dir: aceito sem erro"
else
  pass "nonexistent-dir: rejeitado com erro"
fi

# ============================================================
# Caso 7: diretorio sem governanca instalada
# ============================================================
EMPTY_PROJECT="$TMP_DIR/empty-project"
mkdir -p "$EMPTY_PROJECT"

if bash "$UPGRADE_SCRIPT" "$EMPTY_PROJECT" > /dev/null 2>&1; then
  fail "no-governance: aceito sem erro"
else
  pass "no-governance: rejeitado com erro"
fi

# ============================================================
# Caso 8: diretorio alvo igual ao repo fonte
# ============================================================
if bash "$UPGRADE_SCRIPT" "$ROOT_DIR" > /dev/null 2>&1; then
  fail "self-upgrade: aceito sem erro"
else
  pass "self-upgrade: rejeitado com erro"
fi

# ============================================================
# Caso 9: adaptadores atualizados durante upgrade
# ============================================================
ADAPTER_PROJECT="$TMP_DIR/adapter-project"
mkdir -p "$ADAPTER_PROJECT"
echo "module adapter-test" > "$ADAPTER_PROJECT/go.mod"

LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools claude,gemini --langs all "$ADAPTER_PROJECT" > /dev/null 2>&1

# Modificar um adapter e uma skill para forcar upgrade
echo "# modificado" >> "$ADAPTER_PROJECT/.agents/skills/agent-governance/SKILL.md"
echo "# old" >> "$ADAPTER_PROJECT/.claude/agents/reviewer.md"

output="$(bash "$UPGRADE_SCRIPT" "$ADAPTER_PROJECT" 2>&1)"
if echo "$output" | grep -qi "Adaptadores atualizados"; then
  pass "adapter-upgrade: adaptadores atualizados durante upgrade"
else
  fail "adapter-upgrade: adaptadores nao atualizados"
fi

# Verificar que o adapter foi restaurado
if diff -q "$ROOT_DIR/.claude/agents/reviewer.md" "$ADAPTER_PROJECT/.claude/agents/reviewer.md" > /dev/null 2>&1; then
  pass "adapter-upgrade: reviewer.md restaurado ao conteudo fonte"
else
  fail "adapter-upgrade: reviewer.md nao restaurado"
fi

# ============================================================
# Resumo
# ============================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
