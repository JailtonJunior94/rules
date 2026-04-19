#!/usr/bin/env bash
# Controla profundidade de invocacao entre skills (execute-task -> review -> bugfix).
#
# Uso:
#   source scripts/lib/check-invocation-depth.sh  # verifica e incrementa
#   bash  scripts/lib/check-invocation-depth.sh   # idem, mas em subshell
#
# Variavel de ambiente:
#   AI_INVOCATION_DEPTH  — profundidade atual (0 quando nao definida)
#   AI_INVOCATION_MAX    — limite maximo (default: 2)
#
# Retorno:
#   0 — profundidade dentro do limite; AI_INVOCATION_DEPTH exportada com valor incrementado
#   1 — profundidade excede limite; mensagem de erro em stderr
#
# Exemplo em SKILL.md / hook:
#   source scripts/lib/check-invocation-depth.sh || exit 1
#
# Exemplo como subprocesso (quando sourcing nao e possivel):
#   depth_check="$(AI_INVOCATION_DEPTH="${AI_INVOCATION_DEPTH:-0}" bash scripts/lib/check-invocation-depth.sh)"
#   eval "$depth_check" || exit 1

set -euo pipefail

AI_INVOCATION_MAX="${AI_INVOCATION_MAX:-2}"
current="${AI_INVOCATION_DEPTH:-0}"

if [[ "$current" -ge "$AI_INVOCATION_MAX" ]]; then
  echo "ERRO: limite de profundidade de invocacao atingido (atual=${current}, max=${AI_INVOCATION_MAX})." >&2
  echo "Cadeia detectada: execute-task -> review -> bugfix -> (bloqueado)." >&2
  echo "Retornando estado 'failed: depth limit exceeded'." >&2
  exit 1
fi

next=$((current + 1))

# Quando sourced: exporta a variavel incrementada para o shell pai.
# Quando executado como subprocesso: imprime o comando de exportacao.
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  # Sourced
  export AI_INVOCATION_DEPTH="$next"
else
  # Subprocesso: emite o comando de exportacao para eval pelo chamador
  echo "export AI_INVOCATION_DEPTH=${next}"
fi
