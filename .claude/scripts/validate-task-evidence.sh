#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <relatorio-execucao-tarefa.md>"
  exit 2
fi

report_file="$1"

if [[ ! -f "$report_file" ]]; then
  echo "ERRO: arquivo de relatório não encontrado: $report_file"
  exit 2
fi

missing=0

require_pattern() {
  local pattern="$1"
  local label="$2"

  if ! grep -Eiq "$pattern" "$report_file"; then
    echo "FALTANDO: $label"
    missing=1
  fi
}

require_heading() {
  local pattern="$1"
  local label="$2"

  if ! grep -Eiq "^#+[[:space:]]+$pattern" "$report_file"; then
    echo "FALTANDO: $label"
    missing=1
  fi
}

# Contexto carregado (PRD e TechSpec) — exigir como heading Markdown
require_heading "contexto carregado" "seção Contexto Carregado"
require_pattern "PRD[[:space:]]*:" "referência ao PRD consultado"
require_pattern "TechSpec[[:space:]]*:" "referência à TechSpec consultada"

# Seções obrigatórias — exigir como heading Markdown
require_heading "comandos executados" "seção Comandos Executados"
require_heading "arquivos alterados" "seção Arquivos Alterados"
require_heading "resultados de validac" "seção Resultados de Validação"
require_heading "suposic" "seção Suposições"
require_heading "riscos residuais" "seção Riscos Residuais"

# Exigir um estado terminal canônico
if ! grep -Eiq "estado[[:space:]]*:[[:space:]]*(blocked|failed|done)" "$report_file"; then
  echo "FALTANDO: estado terminal de execução (blocked|failed|done)"
  missing=1
fi

# Evidência de testes e lint
require_pattern "testes[[:space:]]*:[[:space:]]*(pass|fail|blocked)" "evidência de testes com resultado"
require_pattern "lint[[:space:]]*:[[:space:]]*(pass|fail|blocked)" "evidência de lint com resultado"

# Rastreabilidade PRD → teste: se o relatório referencia um PRD, verificar que pelo menos
# um ID de requisito (ex: RF-01, RF01, REQ-1, REQ1) aparece no corpo do relatório.
if grep -Eiq "PRD[[:space:]]*:" "$report_file"; then
  if ! grep -Eiq "(RF-?[0-9]+|REQ-?[0-9]+)" "$report_file"; then
    echo "FALTANDO: nenhum ID de requisito (RF-nn ou REQ-nn) referenciado no relatório"
    missing=1
  fi
fi

# Veredito do revisor
if ! grep -Eiq "veredito do revisor[[:space:]]*:[[:space:]]*(APPROVED|APPROVED_WITH_REMARKS|REJECTED|BLOCKED)" "$report_file"; then
  echo "FALTANDO: veredito do revisor com valor canônico"
  missing=1
fi

if [[ $missing -ne 0 ]]; then
  echo ""
  echo "Validação do pacote de evidências falhou: $report_file"
  exit 1
fi

echo "Validação do pacote de evidências aprovada: $report_file"
