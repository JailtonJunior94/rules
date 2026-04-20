#!/usr/bin/env bash
# Verifica que toda task marcada como done em tasks.md possui um execution report valido.
#
# Uso:
#   bash scripts/check-task-completion.sh <tasks-dir>
#
# Retorna:
#   0  — todas as tasks done possuem reports validos
#   1  — alguma violacao encontrada (report ausente ou invalido)
#   2  — uso incorreto ou arquivo nao encontrado

set -euo pipefail
export LC_ALL=C

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <tasks-dir>"
  exit 2
fi

tasks_dir="${1%/}"

if [[ ! -d "$tasks_dir" ]]; then
  echo "ERRO: diretorio nao encontrado: $tasks_dir"
  exit 2
fi

tasks_file="$tasks_dir/tasks.md"
if [[ ! -f "$tasks_file" ]]; then
  echo "ERRO: tasks.md nao encontrado em $tasks_dir"
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATOR="$SCRIPT_DIR/validators/validate-task-evidence.sh"

if [[ ! -f "$VALIDATOR" ]]; then
  echo "ERRO: validator nao encontrado: $VALIDATOR"
  exit 2
fi

violations=0
checked=0

# Extrair tasks done: linhas de tabela Markdown com numero de task e status done.
# Formato esperado: | 1.0 | Titulo | done | ...
while IFS= read -r line; do
  # Linha de tabela com numero de task (ex: 1.0, 2.0, 10.1) e coluna done
  if echo "$line" | grep -Eq '^\|[[:space:]]*[0-9]+\.[0-9]+[[:space:]]*\|.*\|[[:space:]]*done[[:space:]]*\|'; then
    task_num="$(echo "$line" | sed 's/^|[[:space:]]*//' | cut -d'|' -f1 | tr -d ' ')"
    report_file="$tasks_dir/${task_num}_execution_report.md"

    checked=$((checked + 1))

    if [[ ! -f "$report_file" ]]; then
      echo "VIOLACAO: task $task_num marcada como done mas report ausente: $report_file"
      violations=$((violations + 1))
    elif bash "$VALIDATOR" "$report_file" > /dev/null 2>&1; then
      echo "OK: task $task_num — report valido ($report_file)"
    else
      echo "VIOLACAO: task $task_num — report invalido ($report_file)"
      bash "$VALIDATOR" "$report_file" 2>&1 | sed 's/^/  /' || true
      violations=$((violations + 1))
    fi
  fi
done < "$tasks_file"

echo ""
echo "Tasks done verificadas: $checked"

if [[ "$violations" -gt 0 ]]; then
  echo "FALHA: $violations violacao(oes) encontrada(s) em $tasks_dir"
  exit 1
fi

echo "OK: todas as tasks done possuem reports validos em $tasks_dir"
