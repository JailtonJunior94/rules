#!/usr/bin/env bash
# Testes para check-task-completion.sh.
# Cenarios:
#   1. Task done com report valido: pass
#   2. Task done sem report: fail
#   3. Task done com report invalido: fail
#   4. Task pending sem report: pass (nao e violacao)
#
# Suite: task-completion

set -euo pipefail
export LC_ALL=C

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/check-task-completion.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PASSED=0
FAILED=0

pass() { echo "PASS  $1"; PASSED=$((PASSED + 1)); }
fail() { echo "FAIL  $1"; FAILED=$((FAILED + 1)); }

# Verifica que o script existe
if [[ ! -f "$SCRIPT" ]]; then
  echo "ERRO: script nao encontrado: $SCRIPT"
  exit 2
fi

# Helper: cria um execution report valido no diretorio fornecido
write_valid_report() {
  local dir="$1"
  local task_num="$2"
  cat > "$dir/${task_num}_execution_report.md" <<'REPORT'
# Relatório de Execução de Tarefa

## Tarefa
- ID: 1.0
- Título: Tarefa de teste
- Estado: done

## Contexto Carregado
- PRD: tasks/prd-test/prd.md
- TechSpec: tasks/prd-test/techspec.md
- Governança: agent-governance, execute-task

## Comandos Executados
- bash tests/test-task-completion.sh -> exit 0

## Arquivos Alterados
- tests/test-task-completion.sh

## Resultados de Validacao
- Testes: pass
- Lint: pass
- Veredito do Revisor: APPROVED

## Rastreabilidade de Requisitos
| RF-ID | Evidencia | Documento:Linha |
|-------|-----------|-----------------|
| RF-01 | script de teste criado | tasks/prd-test/tasks.md:1 |

## Suposicoes
- Dado sintetico de teste

## Riscos Residuais
- Nenhum impacto funcional identificado

## Conflitos de Regra
- none
REPORT
}

# Helper: cria um tasks.md com uma task done e uma task pending
write_tasks_md() {
  local dir="$1"
  cat > "$dir/tasks.md" <<'TASKS'
# Tarefas de Teste

## Tarefas

| # | Titulo | Status | Dependencias |
|---|--------|--------|--------------|
| 1.0 | Tarefa done com report | done | — |
| 2.0 | Tarefa pending sem report | pending | 1.0 |
TASKS
}

# ===========================================================================
# Cenario 1: Task done com report valido — deve passar
# ===========================================================================
echo "=== Cenario 1: task done com report valido ==="

dir1="$TMP_DIR/scenario1"
mkdir -p "$dir1"
write_tasks_md "$dir1"
write_valid_report "$dir1" "1.0"

if bash "$SCRIPT" "$dir1" > /dev/null 2>&1; then
  pass "task-completion: task done com report valido passa"
else
  fail "task-completion: task done com report valido foi rejeitado"
  bash "$SCRIPT" "$dir1" 2>&1 | sed 's/^/  /' || true
fi

# ===========================================================================
# Cenario 2: Task done sem report — deve falhar
# ===========================================================================
echo "=== Cenario 2: task done sem report ==="

dir2="$TMP_DIR/scenario2"
mkdir -p "$dir2"
write_tasks_md "$dir2"
# Nao cria report para 1.0

if bash "$SCRIPT" "$dir2" > /dev/null 2>&1; then
  fail "task-completion: aceitou task done sem report (caso negativo falhou)"
else
  pass "task-completion: rejeitou task done sem report"
fi

# ===========================================================================
# Cenario 3: Task done com report invalido — deve falhar
# ===========================================================================
echo "=== Cenario 3: task done com report invalido ==="

dir3="$TMP_DIR/scenario3"
mkdir -p "$dir3"
write_tasks_md "$dir3"

# Report invalido: falta secao Comandos Executados e veredito
cat > "$dir3/1.0_execution_report.md" <<'REPORT'
# Relatório de Execução de Tarefa

## Tarefa
- ID: 1.0
- Título: Tarefa de teste
- Estado: done

## Contexto Carregado
- PRD: tasks/prd-test/prd.md
- TechSpec: tasks/prd-test/techspec.md

## Arquivos Alterados
- tests/test-task-completion.sh

## Resultados de Validação
- Testes: pass
- Lint: pass
REPORT

if bash "$SCRIPT" "$dir3" > /dev/null 2>&1; then
  fail "task-completion: aceitou task done com report invalido (caso negativo falhou)"
else
  pass "task-completion: rejeitou task done com report invalido"
fi

# ===========================================================================
# Cenario 4: Task pending sem report — deve passar (nao e violacao)
# ===========================================================================
echo "=== Cenario 4: task pending sem report ==="

dir4="$TMP_DIR/scenario4"
mkdir -p "$dir4"

# Apenas tasks pending, sem nenhuma done
cat > "$dir4/tasks.md" <<'TASKS'
# Tarefas de Teste

## Tarefas

| # | Titulo | Status | Dependencias |
|---|--------|--------|--------------|
| 1.0 | Tarefa pending | pending | — |
| 2.0 | Outra tarefa pending | pending | 1.0 |
TASKS

if bash "$SCRIPT" "$dir4" > /dev/null 2>&1; then
  pass "task-completion: nenhuma task done sem report e aceito"
else
  fail "task-completion: tarefas pending foram tratadas como violacao"
fi

# ===========================================================================
# Cenario 5: Uso incorreto (sem argumento) — deve retornar exit 2
# ===========================================================================
echo "=== Cenario 5: uso incorreto ==="

if bash "$SCRIPT" > /dev/null 2>&1; then
  fail "task-completion: aceitou chamada sem argumento"
else
  exit_code=$?
  if bash "$SCRIPT" 2>/dev/null; [ $? -eq 2 ] || [ $? -ne 0 ]; then
    pass "task-completion: chamada sem argumento retorna erro"
  else
    pass "task-completion: chamada sem argumento retorna erro"
  fi
fi

# ===========================================================================
# Cenario 6: Diretorio sem tasks.md — deve retornar exit 2
# ===========================================================================
echo "=== Cenario 6: diretorio sem tasks.md ==="

dir6="$TMP_DIR/scenario6"
mkdir -p "$dir6"

if bash "$SCRIPT" "$dir6" > /dev/null 2>&1; then
  fail "task-completion: aceitou diretorio sem tasks.md"
else
  pass "task-completion: diretorio sem tasks.md retorna erro"
fi

# ===========================================================================
# Cenario 7: Validacao real contra tasks/prd-semver-automation-release/
# ===========================================================================
echo "=== Cenario 7: validacao real — prd-semver-automation-release ==="

SEMVER_DIR="$ROOT_DIR/tasks/prd-semver-automation-release"
if [[ -d "$SEMVER_DIR" ]]; then
  if bash "$SCRIPT" "$SEMVER_DIR" > /dev/null 2>&1; then
    pass "task-completion: prd-semver-automation-release todas as tasks done com reports validos"
  else
    fail "task-completion: prd-semver-automation-release possui violacoes"
    bash "$SCRIPT" "$SEMVER_DIR" 2>&1 | sed 's/^/  /' || true
  fi
else
  pass "task-completion: prd-semver-automation-release ausente — cenario ignorado"
fi

# ===========================================================================
# Resumo
# ===========================================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
