#!/usr/bin/env bash
# Retorna os primeiros 8 caracteres do SHA-256 de um arquivo.
# Compativel com Linux (sha256sum) e macOS (shasum -a 256).
#
# Uso:
#   bash scripts/lib/compute-spec-hash.sh <arquivo>
#
# Exemplo:
#   bash scripts/lib/compute-spec-hash.sh tasks/prd-minha-feature/prd.md

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <arquivo>" >&2
  exit 2
fi

file="$1"

if [[ ! -f "$file" ]]; then
  echo "ERRO: arquivo nao encontrado: $file" >&2
  exit 2
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$file" | cut -d' ' -f1 | head -c 8
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$file" | cut -d' ' -f1 | head -c 8
else
  echo "ERRO: nenhum utilitario de SHA-256 disponivel (sha256sum ou shasum)" >&2
  exit 1
fi
