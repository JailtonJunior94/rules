#!/usr/bin/env bash
# Funcao compartilhada para buscar manifests de projeto.
# Uso: source scripts/lib/find-manifests.sh
#      lib_find_manifests <diretorio-base> <pattern> [maxdepth]

lib_find_manifests() {
  local base_dir="$1"
  local pattern="$2"
  local maxdepth="${3:-4}"

  find "$base_dir" -maxdepth "$maxdepth" -type f -name "$pattern" \
    -not -path "*/node_modules/*" \
    -not -path "*/vendor/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -not -path "*/__pycache__/*" \
    | LC_ALL=C sort
}
