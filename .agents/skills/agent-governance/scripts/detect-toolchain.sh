#!/usr/bin/env bash
# Detecta comandos de fmt, test e lint disponiveis no projeto.
# Uso: bash detect-toolchain.sh [diretorio]
# Saida: JSON com chaves fmt, test, lint (string ou null).
set -euo pipefail

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo '{"error":"diretorio nao encontrado"}' >&2
  exit 1
fi

cd "$PROJECT_DIR"

fmt=""
test_cmd=""
lint=""

# --- Go ---
if [[ -f "go.mod" ]]; then
  fmt="gofmt -w ."
  test_cmd="go test ./..."
  if command -v golangci-lint >/dev/null 2>&1; then
    lint="golangci-lint run"
  elif [[ -f ".golangci.yml" ]] || [[ -f ".golangci.yaml" ]]; then
    lint="golangci-lint run"
  fi

# --- Node/TypeScript ---
elif [[ -f "package.json" ]]; then
  # Detectar package manager
  pm="npm"
  if [[ -f "pnpm-lock.yaml" ]]; then
    pm="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    pm="yarn"
  elif [[ -f "bun.lockb" ]]; then
    pm="bun"
  fi

  # Detectar scripts disponiveis
  if command -v jq >/dev/null 2>&1; then
    scripts="$(jq -r '.scripts // {} | keys[]' package.json 2>/dev/null || true)"
  else
    scripts=""
  fi

  if echo "$scripts" | grep -qx "fmt"; then
    fmt="$pm run fmt"
  elif echo "$scripts" | grep -qx "format"; then
    fmt="$pm run format"
  elif command -v prettier >/dev/null 2>&1 || [[ -f ".prettierrc" ]] || [[ -f ".prettierrc.json" ]]; then
    fmt="npx prettier --write ."
  fi

  if echo "$scripts" | grep -qx "test"; then
    test_cmd="$pm run test"
  elif echo "$scripts" | grep -qx "test:unit"; then
    test_cmd="$pm run test:unit"
  fi

  if echo "$scripts" | grep -qx "lint"; then
    lint="$pm run lint"
  elif [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || [[ -f "eslint.config.js" ]] || [[ -f "eslint.config.mjs" ]]; then
    lint="npx eslint ."
  fi

# --- Python ---
elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "Pipfile" ]]; then
  if command -v ruff >/dev/null 2>&1 || [[ -f "ruff.toml" ]] || [[ -f ".ruff.toml" ]]; then
    fmt="ruff format ."
    lint="ruff check ."
  elif command -v black >/dev/null 2>&1; then
    fmt="black ."
    if command -v flake8 >/dev/null 2>&1; then
      lint="flake8 ."
    fi
  fi

  if command -v pytest >/dev/null 2>&1 || [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
    test_cmd="pytest"
  fi

# --- Rust ---
elif [[ -f "Cargo.toml" ]]; then
  fmt="cargo fmt"
  test_cmd="cargo test"
  lint="cargo clippy"

# --- Java (Maven) ---
elif [[ -f "pom.xml" ]]; then
  fmt=""
  test_cmd="mvn test"
  lint="mvn verify"

# --- Java (Gradle) ---
elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
  fmt=""
  test_cmd="gradle test"
  lint="gradle check"

# --- C# / .NET ---
elif ls ./*.csproj >/dev/null 2>&1 || ls ./*.sln >/dev/null 2>&1; then
  fmt="dotnet format"
  test_cmd="dotnet test"
  lint="dotnet format --verify-no-changes"
fi

# --- Fallback: Makefile ---
if [[ -f "Makefile" ]]; then
  if [[ -z "$fmt" ]] && grep -q '^fmt:' Makefile 2>/dev/null; then
    fmt="make fmt"
  fi
  if [[ -z "$test_cmd" ]] && grep -q '^test:' Makefile 2>/dev/null; then
    test_cmd="make test"
  fi
  if [[ -z "$lint" ]] && grep -q '^lint:' Makefile 2>/dev/null; then
    lint="make lint"
  fi
fi

# --- Fallback: Taskfile ---
if [[ -f "Taskfile.yml" ]] || [[ -f "Taskfile.yaml" ]]; then
  if [[ -z "$fmt" ]] && command -v task >/dev/null 2>&1; then
    fmt="task fmt"
  fi
  if [[ -z "$test_cmd" ]] && command -v task >/dev/null 2>&1; then
    test_cmd="task test"
  fi
  if [[ -z "$lint" ]] && command -v task >/dev/null 2>&1; then
    lint="task lint"
  fi
fi

# Emitir JSON
json_val() {
  if [[ -n "$1" ]]; then
    printf '"%s"' "$1"
  else
    printf 'null'
  fi
}

printf '{"fmt":%s,"test":%s,"lint":%s}\n' "$(json_val "$fmt")" "$(json_val "$test_cmd")" "$(json_val "$lint")"
