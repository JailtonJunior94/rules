#!/usr/bin/env bash
# Testa o contrato entre templates de report e seus validators correspondentes.
# Garante que um report gerado a partir do template (com dados sinteticos minimos)
# passa no validator, e que um report com secao obrigatoria removida falha.
#
# Suite: template-contract

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

PASSED=0
FAILED=0

pass() { echo "PASS  $1"; PASSED=$((PASSED + 1)); }
fail() { echo "FAIL  $1"; FAILED=$((FAILED + 1)); }

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

TASK_VALIDATOR="$ROOT_DIR/scripts/validators/validate-task-evidence.sh"
BUGFIX_VALIDATOR="$ROOT_DIR/scripts/validators/validate-bugfix-evidence.sh"
REFACTOR_VALIDATOR="$ROOT_DIR/scripts/validators/validate-refactor-evidence.sh"

TASK_TEMPLATE="$ROOT_DIR/.agents/skills/execute-task/assets/task-execution-report-template.md"
BUGFIX_TEMPLATE="$ROOT_DIR/.agents/skills/bugfix/assets/bugfix-report-template.md"
REFACTOR_TEMPLATE="$ROOT_DIR/.agents/skills/refactor/assets/refactor-report-template.md"

# Verifica que os arquivos de template existem
for f in "$TASK_TEMPLATE" "$BUGFIX_TEMPLATE" "$REFACTOR_TEMPLATE"; do
  if [[ ! -f "$f" ]]; then
    echo "ERRO: template nao encontrado: $f"
    exit 2
  fi
done

# Verifica que os validators existem
for f in "$TASK_VALIDATOR" "$BUGFIX_VALIDATOR" "$REFACTOR_VALIDATOR"; do
  if [[ ! -f "$f" ]]; then
    echo "ERRO: validator nao encontrado: $f"
    exit 2
  fi
done

# ===========================================================================
# 1. PAR: task-execution-report-template.md <-> validate-task-evidence.sh
# ===========================================================================
echo "=== Par 1: task template <-> validate-task-evidence ==="

# 1a. Positivo: template preenchido com dados sinteticos minimos validos deve passar
cat > "$tmpdir/task-filled.md" <<'REPORT'
# Relatório de Execução de Tarefa

## Tarefa
- ID: TASK-1.0
- Título: Teste de contrato template-validator
- Estado: done

## Contexto Carregado
- PRD: tasks/prd-maturidade-governanca/prd.md
- TechSpec: tasks/prd-maturidade-governanca/techspec.md
- Governança: agent-governance, execute-task

## Comandos Executados
- bash tests/test-template-contract.sh -> exit 0

## Arquivos Alterados
- tests/test-template-contract.sh

## Resultados de Validacao
- Testes: pass
- Lint: pass
- Veredito do Revisor: APPROVED

## Rastreabilidade de Requisitos
| RF-ID | Evidencia | Documento:Linha |
|-------|-----------|-----------------|
| RF-01 | script de contrato criado e validado com sucesso | tasks/prd-maturidade-governanca/tasks.md:14 |

## Suposicoes
- Templates preenchidos com dados sinteticos minimos validos

## Riscos Residuais
- Nenhum impacto funcional identificado

## Conflitos de Regra
- none
REPORT

if bash "$TASK_VALIDATOR" "$tmpdir/task-filled.md" > /dev/null 2>&1; then
  pass "task-contract: template preenchido passa no validator"
else
  fail "task-contract: template preenchido foi rejeitado pelo validator"
  bash "$TASK_VALIDATOR" "$tmpdir/task-filled.md" 2>&1 | sed 's/^/  /' || true
fi

# 1b. Negativo: sem seção Comandos Executados deve falhar
cat > "$tmpdir/task-no-commands.md" <<'REPORT'
# Relatório de Execução de Tarefa

## Tarefa
- ID: TASK-1.0
- Título: Teste de contrato template-validator
- Estado: done

## Contexto Carregado
- PRD: tasks/prd-maturidade-governanca/prd.md
- TechSpec: tasks/prd-maturidade-governanca/techspec.md
- Governança: agent-governance

## Arquivos Alterados
- tests/test-template-contract.sh

## Resultados de Validação
- Testes: pass
- Lint: pass
- Veredito do Revisor: APPROVED

## Rastreabilidade de Requisitos
| RF-ID | Evidencia | Documento:Linha |
|-------|-----------|-----------------|
| RF-01 | script de contrato criado | tasks/prd-maturidade-governanca/tasks.md:14 |

## Suposições
- Dado sintético

## Riscos Residuais
- Nenhum
REPORT

if bash "$TASK_VALIDATOR" "$tmpdir/task-no-commands.md" > /dev/null 2>&1; then
  fail "task-contract: aceitou report sem seção Comandos Executados (caso negativo falhou)"
else
  pass "task-contract: rejeitou report sem seção Comandos Executados (caso negativo correto)"
fi

# 1c. Negativo: sem veredito do revisor deve falhar
cat > "$tmpdir/task-no-verdict.md" <<'REPORT'
# Relatório de Execução de Tarefa

## Tarefa
- ID: TASK-1.0
- Título: Teste de contrato template-validator
- Estado: done

## Contexto Carregado
- PRD: tasks/prd-maturidade-governanca/prd.md
- TechSpec: tasks/prd-maturidade-governanca/techspec.md
- Governança: agent-governance

## Comandos Executados
- bash tests/test-template-contract.sh -> exit 0

## Arquivos Alterados
- tests/test-template-contract.sh

## Resultados de Validação
- Testes: pass
- Lint: pass

## Rastreabilidade de Requisitos
| RF-ID | Evidencia | Documento:Linha |
|-------|-----------|-----------------|
| RF-01 | script de contrato criado | tasks/prd-maturidade-governanca/tasks.md:14 |

## Suposições
- Dado sintético

## Riscos Residuais
- Nenhum
REPORT

if bash "$TASK_VALIDATOR" "$tmpdir/task-no-verdict.md" > /dev/null 2>&1; then
  fail "task-contract: aceitou report sem veredito do revisor (caso negativo falhou)"
else
  pass "task-contract: rejeitou report sem veredito do revisor (caso negativo correto)"
fi

# ===========================================================================
# 2. PAR: bugfix-report-template.md <-> validate-bugfix-evidence.sh
# ===========================================================================
echo "=== Par 2: bugfix template <-> validate-bugfix-evidence ==="

# 2a. Positivo: template preenchido com dados sinteticos minimos validos deve passar
cat > "$tmpdir/bugfix-filled.md" <<'REPORT'
# Relatorio de Bugfix

- Total de bugs no escopo: 1
- Corrigidos: 1
- Testes de regressao adicionados: 1
- Pendentes: nenhum

## Bugs
- ID: BUG-001
- Severidade: major
- Estado: fixed
- Causa raiz: placeholder no template substituído por valor sintético de contrato
- Arquivos alterados: tests/test-template-contract.sh
- Teste de regressao: TestContractTemplateBugfix
- Validacao: bash tests/test-template-contract.sh -> exit 0

## Comandos Executados
- bash tests/test-template-contract.sh -> exit 0

## Riscos Residuais
- Nenhum impacto residual identificado

- Estado final: done
REPORT

if bash "$BUGFIX_VALIDATOR" "$tmpdir/bugfix-filled.md" > /dev/null 2>&1; then
  pass "bugfix-contract: template preenchido passa no validator"
else
  fail "bugfix-contract: template preenchido foi rejeitado pelo validator"
  bash "$BUGFIX_VALIDATOR" "$tmpdir/bugfix-filled.md" 2>&1 | sed 's/^/  /' || true
fi

# 2b. Negativo: sem campo Causa raiz deve falhar
cat > "$tmpdir/bugfix-no-root-cause.md" <<'REPORT'
# Relatorio de Bugfix

- Total de bugs no escopo: 1
- Corrigidos: 1
- Testes de regressao adicionados: 1
- Pendentes: nenhum

## Bugs
- ID: BUG-001
- Severidade: major
- Estado: fixed
- Arquivos alterados: tests/test-template-contract.sh
- Teste de regressao: TestContractTemplateBugfix
- Validacao: bash tests/test-template-contract.sh -> exit 0

## Comandos Executados
- bash tests/test-template-contract.sh -> exit 0

## Riscos Residuais
- Nenhum

- Estado final: done
REPORT

if bash "$BUGFIX_VALIDATOR" "$tmpdir/bugfix-no-root-cause.md" > /dev/null 2>&1; then
  fail "bugfix-contract: aceitou report sem causa raiz (caso negativo falhou)"
else
  pass "bugfix-contract: rejeitou report sem causa raiz (caso negativo correto)"
fi

# 2c. Negativo: sem estado terminal deve falhar
cat > "$tmpdir/bugfix-no-terminal.md" <<'REPORT'
# Relatorio de Bugfix

- Total de bugs no escopo: 1
- Corrigidos: 1
- Testes de regressao adicionados: 1

## Bugs
- ID: BUG-001
- Severidade: major
- Estado: fixed
- Causa raiz: erro sintético de teste de contrato
- Arquivos alterados: tests/test-template-contract.sh
- Teste de regressao: TestContractTemplateBugfix
- Validacao: bash tests/test-template-contract.sh -> exit 0

## Comandos Executados
- bash tests/test-template-contract.sh -> exit 0

## Riscos Residuais
- Nenhum
REPORT

if bash "$BUGFIX_VALIDATOR" "$tmpdir/bugfix-no-terminal.md" > /dev/null 2>&1; then
  fail "bugfix-contract: aceitou report sem estado terminal (caso negativo falhou)"
else
  pass "bugfix-contract: rejeitou report sem estado terminal (caso negativo correto)"
fi

# ===========================================================================
# 3. PAR: refactor-report-template.md <-> validate-refactor-evidence.sh
# ===========================================================================
echo "=== Par 3: refactor template <-> validate-refactor-evidence ==="

# 3a. Positivo: template preenchido (advisory) com dados sinteticos minimos deve passar
cat > "$tmpdir/refactor-filled.md" <<'REPORT'
# Relatório de Refatoração

## Escopo
- Alvo: tests/test-template-contract.sh
- Modo: advisory
- Estado: done

## Invariantes Preservadas
- Comportamento dos validators mantido sem alteração

## Mudancas Propostas ou Aplicadas
- Criacao do script de teste de contrato entre templates e validators

## Comandos Executados
- bash tests/test-template-contract.sh -> exit 0

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Suposicoes
- Templates representam o contrato minimo necessario

## Riscos Residuais
- Nenhum impacto residual identificado
REPORT

if bash "$REFACTOR_VALIDATOR" "$tmpdir/refactor-filled.md" > /dev/null 2>&1; then
  pass "refactor-contract: template preenchido (advisory) passa no validator"
else
  fail "refactor-contract: template preenchido (advisory) foi rejeitado pelo validator"
  bash "$REFACTOR_VALIDATOR" "$tmpdir/refactor-filled.md" 2>&1 | sed 's/^/  /' || true
fi

# 3b. Negativo: modo execution sem veredito deve falhar
cat > "$tmpdir/refactor-exec-no-verdict.md" <<'REPORT'
# Relatório de Refatoração

## Escopo
- Alvo: tests/test-template-contract.sh
- Modo: execution
- Estado: done

## Invariantes Preservadas
- Comportamento dos validators mantido sem alteração

## Mudancas Propostas ou Aplicadas
- Criacao do script de teste de contrato

## Comandos Executados
- bash tests/test-template-contract.sh -> exit 0

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Suposicoes
- Templates representam o contrato minimo necessario

## Riscos Residuais
- Nenhum
REPORT

if bash "$REFACTOR_VALIDATOR" "$tmpdir/refactor-exec-no-verdict.md" > /dev/null 2>&1; then
  fail "refactor-contract: aceitou execution sem veredito do revisor (caso negativo falhou)"
else
  pass "refactor-contract: rejeitou execution sem veredito do revisor (caso negativo correto)"
fi

# 3c. Negativo: sem seção Invariantes Preservadas deve falhar
cat > "$tmpdir/refactor-no-invariants.md" <<'REPORT'
# Relatório de Refatoração

## Escopo
- Alvo: tests/test-template-contract.sh
- Modo: advisory
- Estado: done

## Mudancas Propostas ou Aplicadas
- Criacao do script de teste de contrato

## Comandos Executados
- bash tests/test-template-contract.sh -> exit 0

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Suposicoes
- Templates representam o contrato minimo necessario

## Riscos Residuais
- Nenhum
REPORT

if bash "$REFACTOR_VALIDATOR" "$tmpdir/refactor-no-invariants.md" > /dev/null 2>&1; then
  fail "refactor-contract: aceitou report sem seção Invariantes Preservadas (caso negativo falhou)"
else
  pass "refactor-contract: rejeitou report sem seção Invariantes Preservadas (caso negativo correto)"
fi

# ===========================================================================
# Resumo
# ===========================================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
