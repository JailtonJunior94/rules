#!/usr/bin/env bash
# Testes especificos para a integracao com GitHub Copilot CLI.
# Foco: install copilot-only, geracao contextual, wrappers .github e upgrade.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"
UPGRADE_SCRIPT="$ROOT_DIR/upgrade.sh"
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
# Caso 1: instalacao copilot-only com Node
# ============================================================
COPILOT_TARGET="$TMP_DIR/copilot-project"
mkdir -p "$COPILOT_TARGET"
cat > "$COPILOT_TARGET/package.json" <<'EOF'
{
  "name": "copilot-project",
  "scripts": {
    "test": "vitest",
    "lint": "eslint ."
  }
}
EOF

bash "$INSTALL_SCRIPT" --tools copilot --langs node "$COPILOT_TARGET" > /dev/null 2>&1

if [[ -f "$COPILOT_TARGET/AGENTS.md" ]]; then
  pass "copilot-install: AGENTS.md gerado"
else
  fail "copilot-install: AGENTS.md ausente"
fi

if [[ -f "$COPILOT_TARGET/.github/copilot-instructions.md" ]]; then
  pass "copilot-install: copilot-instructions.md gerado"
else
  fail "copilot-install: copilot-instructions.md ausente"
fi

if [[ -d "$COPILOT_TARGET/.github/agents" ]]; then
  pass "copilot-install: .github/agents criado"
else
  fail "copilot-install: .github/agents ausente"
fi

if [[ -e "$COPILOT_TARGET/.github/skills/node-implementation/SKILL.md" ]]; then
  pass "copilot-install: skill Node exposta em .github/skills"
else
  fail "copilot-install: skill Node ausente em .github/skills"
fi

if [[ ! -d "$COPILOT_TARGET/.claude" && ! -d "$COPILOT_TARGET/.gemini" && ! -d "$COPILOT_TARGET/.codex" ]]; then
  pass "copilot-install: nenhuma ferramenta nao solicitada foi instalada"
else
  fail "copilot-install: ferramentas nao solicitadas foram instaladas"
fi

# ============================================================
# Caso 2: conteudo contextual especifico do Copilot
# ============================================================
COPILOT_INSTRUCTIONS="$COPILOT_TARGET/.github/copilot-instructions.md"

if grep -q 'GitHub Copilot CLI' "$COPILOT_INSTRUCTIONS" 2>/dev/null; then
  pass "copilot-content: titulo da ferramenta presente"
else
  fail "copilot-content: titulo da ferramenta ausente"
fi

if grep -q '## Orientacoes Especificas para Copilot' "$COPILOT_INSTRUCTIONS" 2>/dev/null; then
  pass "copilot-content: secao especifica do Copilot presente"
else
  fail "copilot-content: secao especifica do Copilot ausente"
fi

if grep -q 'nao suporta hooks de enforcement' "$COPILOT_INSTRUCTIONS" 2>/dev/null; then
  pass "copilot-content: limitacao de enforcement documentada"
else
  fail "copilot-content: limitacao de enforcement nao documentada"
fi

if grep -q 'Projeto com contexto Node/TypeScript detectado' "$COPILOT_INSTRUCTIONS" 2>/dev/null; then
  pass "copilot-content: stack contextual detectada"
else
  fail "copilot-content: stack contextual nao detectada"
fi

if grep -q '{{' "$COPILOT_INSTRUCTIONS" 2>/dev/null; then
  fail "copilot-content: placeholders remanescentes"
else
  pass "copilot-content: sem placeholders remanescentes"
fi

# ============================================================
# Caso 3: wrappers .github canonicos
# ============================================================
for agent in \
  bugfix.agent.md \
  project-analyzer.agent.md \
  prd-writer.agent.md \
  refactorer.agent.md \
  reviewer.agent.md \
  task-executor.agent.md \
  task-planner.agent.md \
  technical-specification-writer.agent.md
do
  if [[ -f "$COPILOT_TARGET/.github/agents/$agent" ]]; then
    pass "copilot-agents: $agent presente"
  else
    fail "copilot-agents: $agent ausente"
  fi
done

if grep -q 'Contrato de carga obrigatorio antes de editar codigo' "$COPILOT_TARGET/.github/agents/reviewer.agent.md" 2>/dev/null; then
  pass "copilot-agents: wrapper inclui contrato de carga"
else
  fail "copilot-agents: wrapper sem contrato de carga"
fi

if grep -q 'Validacao ao final' "$COPILOT_TARGET/.github/agents/task-executor.agent.md" 2>/dev/null; then
  pass "copilot-agents: wrapper inclui validacao final"
else
  fail "copilot-agents: wrapper sem validacao final"
fi

# ============================================================
# Caso 4: upgrade re-regenera instrucoes do Copilot
# ============================================================
mkdir -p "$TMP_DIR/copilot-copy-project"
LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools copilot --langs node "$TMP_DIR/copilot-copy-project" > /dev/null 2>&1
COPY_PROJECT="$TMP_DIR/copilot-copy-project"

echo "# stale" >> "$COPY_PROJECT/.github/copilot-instructions.md"
echo "# modificado" >> "$COPY_PROJECT/.agents/skills/agent-governance/SKILL.md"

bash "$UPGRADE_SCRIPT" "$COPY_PROJECT" > /dev/null 2>&1

if grep -q '# stale' "$COPY_PROJECT/.github/copilot-instructions.md" 2>/dev/null; then
  fail "copilot-upgrade: instrucoes antigas nao regeneradas"
else
  pass "copilot-upgrade: instrucoes regeneradas"
fi

if grep -q '## Orientacoes Especificas para Copilot' "$COPY_PROJECT/.github/copilot-instructions.md" 2>/dev/null; then
  pass "copilot-upgrade: secao especifica preservada apos upgrade"
else
  fail "copilot-upgrade: secao especifica ausente apos upgrade"
fi

# ============================================================
# Caso 5: modo nao-contextual continua funcional
# ============================================================
NON_CONTEXTUAL_TARGET="$TMP_DIR/copilot-non-contextual"
mkdir -p "$NON_CONTEXTUAL_TARGET"
echo "module example.com/copilot" > "$NON_CONTEXTUAL_TARGET/go.mod"

GENERATE_CONTEXTUAL_GOVERNANCE=0 bash "$INSTALL_SCRIPT" --tools copilot --langs go "$NON_CONTEXTUAL_TARGET" > /dev/null 2>&1

if [[ -f "$NON_CONTEXTUAL_TARGET/.github/copilot-instructions.md" ]]; then
  pass "copilot-non-contextual: instrucoes geradas"
else
  fail "copilot-non-contextual: instrucoes ausentes"
fi

if grep -q 'Use `AGENTS.md` como instrucao principal deste repositorio.' "$NON_CONTEXTUAL_TARGET/.github/copilot-instructions.md" 2>/dev/null; then
  pass "copilot-non-contextual: fallback estatico correto"
else
  fail "copilot-non-contextual: fallback estatico incorreto"
fi

echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
