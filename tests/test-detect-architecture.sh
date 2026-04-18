#!/usr/bin/env bash
# Testes unitarios para detect-architecture.sh.
# Uso: bash tests/test-detect-architecture.sh

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
DETECT_ARCH="$ROOT_DIR/.agents/skills/agent-governance/scripts/detect-architecture.sh"
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

# Helper: cria fixture, roda detect-architecture.sh, valida JSON
run_detect() {
  local dir="$1"
  bash "$DETECT_ARCH" "$dir" 2>/dev/null
}

extract_type() {
  local json="$1"
  printf '%s' "$json" | sed 's/.*"architecture_type":"\([^"]*\)".*/\1/'
}

extract_pattern() {
  local json="$1"
  printf '%s' "$json" | sed 's/.*"architectural_pattern":"\([^"]*\)".*/\1/'
}

# ============================================================
# Deteccao de tipo de arquitetura
# ============================================================

# go.work -> monorepo
mk_fixture() {
  local name="$1"
  local dir="$TMP_DIR/$name"
  mkdir -p "$dir"
  printf '%s' "$dir"
}

dir="$(mk_fixture "monorepo-gowork")"
touch "$dir/go.work"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monorepo" ]]; then
  pass "type: go.work -> monorepo"
else
  fail "type: go.work -> monorepo (got: $(extract_type "$json"))"
fi

# pnpm-workspace.yaml -> monorepo
dir="$(mk_fixture "monorepo-pnpm")"
touch "$dir/pnpm-workspace.yaml"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monorepo" ]]; then
  pass "type: pnpm-workspace -> monorepo"
else
  fail "type: pnpm-workspace -> monorepo (got: $(extract_type "$json"))"
fi

# nx.json -> monorepo
dir="$(mk_fixture "monorepo-nx")"
touch "$dir/nx.json"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monorepo" ]]; then
  pass "type: nx.json -> monorepo"
else
  fail "type: nx.json -> monorepo (got: $(extract_type "$json"))"
fi

# turbo.json -> monorepo
dir="$(mk_fixture "monorepo-turbo")"
touch "$dir/turbo.json"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monorepo" ]]; then
  pass "type: turbo.json -> monorepo"
else
  fail "type: turbo.json -> monorepo (got: $(extract_type "$json"))"
fi

# services/ + packages/ -> monorepo
dir="$(mk_fixture "monorepo-dirs")"
mkdir -p "$dir/services/a" "$dir/packages/b"
touch "$dir/services/a/.gitkeep" "$dir/packages/b/.gitkeep"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monorepo" ]]; then
  pass "type: services+packages -> monorepo"
else
  fail "type: services+packages -> monorepo (got: $(extract_type "$json"))"
fi

# apps/ + packages/ -> monorepo
dir="$(mk_fixture "monorepo-apps")"
mkdir -p "$dir/apps/web" "$dir/packages/shared"
touch "$dir/apps/web/.gitkeep" "$dir/packages/shared/.gitkeep"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monorepo" ]]; then
  pass "type: apps+packages -> monorepo"
else
  fail "type: apps+packages -> monorepo (got: $(extract_type "$json"))"
fi

# modules/ -> monolito modular
dir="$(mk_fixture "modular-modules")"
mkdir -p "$dir/modules/auth"
touch "$dir/modules/auth/.gitkeep"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monolito modular" ]]; then
  pass "type: modules/ -> monolito modular"
else
  fail "type: modules/ -> monolito modular (got: $(extract_type "$json"))"
fi

# internal/ com 3+ subdirs -> monolito modular
dir="$(mk_fixture "modular-internal")"
mkdir -p "$dir/internal/auth" "$dir/internal/order" "$dir/internal/payment"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monolito modular" ]]; then
  pass "type: internal/3+ -> monolito modular"
else
  fail "type: internal/3+ -> monolito modular (got: $(extract_type "$json"))"
fi

# internal/ com 2 subdirs -> nao e modular
dir="$(mk_fixture "not-modular")"
mkdir -p "$dir/internal/auth" "$dir/internal/order"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" != "monolito modular" ]]; then
  pass "type: internal/2 -> nao modular"
else
  fail "type: internal/2 -> nao deveria ser modular"
fi

# Dockerfile + k8s/ -> microservico
dir="$(mk_fixture "micro-k8s")"
touch "$dir/Dockerfile"
mkdir -p "$dir/k8s"
touch "$dir/k8s/deploy.yaml"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "microservico" ]]; then
  pass "type: Dockerfile+k8s -> microservico"
else
  fail "type: Dockerfile+k8s -> microservico (got: $(extract_type "$json"))"
fi

# Dockerfile + deployments/ -> microservico
dir="$(mk_fixture "micro-deploy")"
touch "$dir/Dockerfile"
mkdir -p "$dir/deployments"
touch "$dir/deployments/.gitkeep"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "microservico" ]]; then
  pass "type: Dockerfile+deployments -> microservico"
else
  fail "type: Dockerfile+deployments -> microservico (got: $(extract_type "$json"))"
fi

# Dockerfile + helm/ -> microservico
dir="$(mk_fixture "micro-helm")"
touch "$dir/Dockerfile"
mkdir -p "$dir/helm"
touch "$dir/helm/Chart.yaml"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "microservico" ]]; then
  pass "type: Dockerfile+helm -> microservico"
else
  fail "type: Dockerfile+helm -> microservico (got: $(extract_type "$json"))"
fi

# Dockerfile sozinho -> monolito (sem sinais de deploy isolado)
dir="$(mk_fixture "dockerfile-only")"
touch "$dir/Dockerfile"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monolito" ]]; then
  pass "type: Dockerfile alone -> monolito"
else
  fail "type: Dockerfile alone -> monolito (got: $(extract_type "$json"))"
fi

# Diretorio vazio -> monolito (fallback)
dir="$(mk_fixture "empty")"
json="$(run_detect "$dir")"
if [[ "$(extract_type "$json")" == "monolito" ]]; then
  pass "type: empty -> monolito (fallback)"
else
  fail "type: empty -> monolito (got: $(extract_type "$json"))"
fi

# ============================================================
# Deteccao de padrao arquitetural
# ============================================================

# domain/ + infrastructure/ -> Clean/Hexagonal
dir="$(mk_fixture "pattern-clean")"
mkdir -p "$dir/domain" "$dir/infrastructure"
touch "$dir/domain/.gitkeep" "$dir/infrastructure/.gitkeep"
json="$(run_detect "$dir")"
pattern="$(extract_pattern "$json")"
if echo "$pattern" | grep -qi "clean\|hexagonal"; then
  pass "pattern: domain+infrastructure -> clean/hexagonal"
else
  fail "pattern: domain+infrastructure -> clean/hexagonal (got: $pattern)"
fi

# controllers/ + services/ + repositories/ -> camadas
dir="$(mk_fixture "pattern-layered")"
mkdir -p "$dir/controllers" "$dir/services" "$dir/repositories"
touch "$dir/controllers/.gitkeep" "$dir/services/.gitkeep" "$dir/repositories/.gitkeep"
json="$(run_detect "$dir")"
pattern="$(extract_pattern "$json")"
if echo "$pattern" | grep -qi "camadas"; then
  pass "pattern: controllers+services+repositories -> camadas"
else
  fail "pattern: controllers+services+repositories -> camadas (got: $pattern)"
fi

# features/ -> fatiamento vertical
dir="$(mk_fixture "pattern-feature")"
mkdir -p "$dir/features/auth"
touch "$dir/features/auth/.gitkeep"
json="$(run_detect "$dir")"
pattern="$(extract_pattern "$json")"
if echo "$pattern" | grep -qi "funcionalidade\|vertical"; then
  pass "pattern: features/ -> fatiamento vertical"
else
  fail "pattern: features/ -> fatiamento vertical (got: $pattern)"
fi

# internal/ only -> packages internos
dir="$(mk_fixture "pattern-internal")"
mkdir -p "$dir/internal/core"
touch "$dir/internal/core/.gitkeep"
json="$(run_detect "$dir")"
pattern="$(extract_pattern "$json")"
if echo "$pattern" | grep -qi "packages internos\|interno"; then
  pass "pattern: internal/ -> packages internos"
else
  fail "pattern: internal/ -> packages internos (got: $pattern)"
fi

# ============================================================
# JSON output valido
# ============================================================
dir="$(mk_fixture "json-valid")"
touch "$dir/go.work"
json="$(run_detect "$dir")"
if python3 -c "import json, sys; json.loads(sys.argv[1])" "$json" 2>/dev/null; then
  pass "output: JSON sintaticamente valido"
else
  fail "output: JSON invalido: $json"
fi

# ============================================================
# Fixtures do projeto
# ============================================================
json="$(run_detect "$ROOT_DIR/tests/fixtures/go-microservice")"
if [[ "$(extract_type "$json")" == "microservico" ]]; then
  pass "fixture: go-microservice -> microservico"
else
  fail "fixture: go-microservice -> $(extract_type "$json")"
fi

json="$(run_detect "$ROOT_DIR/tests/fixtures/go-modular")"
if [[ "$(extract_type "$json")" == "monolito modular" ]]; then
  pass "fixture: go-modular -> monolito modular"
else
  fail "fixture: go-modular -> $(extract_type "$json")"
fi

json="$(run_detect "$ROOT_DIR/tests/fixtures/node-monorepo")"
if [[ "$(extract_type "$json")" == "monorepo" ]]; then
  pass "fixture: node-monorepo -> monorepo"
else
  fail "fixture: node-monorepo -> $(extract_type "$json")"
fi

# ============================================================
# Resumo
# ============================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
