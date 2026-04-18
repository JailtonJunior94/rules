#!/usr/bin/env bash
# Testa validacao de frontmatter de SKILL.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATOR="$ROOT_DIR/scripts/validate-skill-frontmatter.sh"

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

# --- Test 1: Skills reais passam ---
if bash "$VALIDATOR" "$ROOT_DIR/.agents/skills" >/dev/null 2>&1; then
  report PASS "skills reais passam validacao"
else
  report FAIL "skills reais passam validacao"
fi

# --- Test 2: Frontmatter ausente falha ---
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bad-skill"
cat > "$tmpdir/bad-skill/SKILL.md" <<'EOF'
# Skill sem frontmatter

Conteudo qualquer.
EOF

if bash "$VALIDATOR" "$tmpdir" >/dev/null 2>&1; then
  report FAIL "frontmatter ausente detectado"
else
  report PASS "frontmatter ausente detectado"
fi

# --- Test 3: Campo obrigatorio ausente falha ---
mkdir -p "$tmpdir/missing-field"
cat > "$tmpdir/missing-field/SKILL.md" <<'EOF'
---
name: missing-field
version: 1.0.0
---

# Sem description
EOF

if bash "$VALIDATOR" "$tmpdir/missing-field/.." >/dev/null 2>&1; then
  report FAIL "campo description ausente detectado"
else
  report PASS "campo description ausente detectado"
fi

# --- Test 4: Versao invalida falha ---
rm -rf "$tmpdir/bad-skill" "$tmpdir/missing-field"
mkdir -p "$tmpdir/bad-version"
cat > "$tmpdir/bad-version/SKILL.md" <<'EOF'
---
name: bad-version
version: abc
description: test
---

# Test
EOF

if bash "$VALIDATOR" "$tmpdir" >/dev/null 2>&1; then
  report FAIL "versao invalida detectada"
else
  report PASS "versao invalida detectada"
fi

# --- Test 5: Name diverge do diretorio falha ---
rm -rf "$tmpdir/bad-version"
mkdir -p "$tmpdir/wrong-name"
cat > "$tmpdir/wrong-name/SKILL.md" <<'EOF'
---
name: different-name
version: 1.0.0
description: test
---

# Test
EOF

if bash "$VALIDATOR" "$tmpdir" >/dev/null 2>&1; then
  report FAIL "name divergente detectado"
else
  report PASS "name divergente detectado"
fi

# --- Test 6: Diretorio inexistente falha ---
if bash "$VALIDATOR" "/tmp/nao-existe-xyz" >/dev/null 2>&1; then
  report FAIL "diretorio inexistente detectado"
else
  report PASS "diretorio inexistente detectado"
fi

echo ""
echo "Resultados: $PASS passou, $FAIL falhou"
[[ "$FAIL" -eq 0 ]]
