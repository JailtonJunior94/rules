#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "rg not found in PATH" >&2
  exit 1
fi

mapfile -t files < <(rg --files -g '*.go' -g '!vendor/**' -g '!**/testdata/**' -g '!**/node_modules/**')

if [ "${#files[@]}" -eq 0 ]; then
  echo "no Go files found in current workspace" >&2
  exit 1
fi

printf '%s\n' "${files[@]}"
