#!/usr/bin/env bash
# Funcoes compartilhadas entre install.sh e upgrade.sh.
# Uso: source scripts/lib/install-common.sh
# Requer: DRY_RUN (0|1), LINK_MODE (symlink|copy)

DRY_RUN="${DRY_RUN:-0}"
LINK_MODE="${LINK_MODE:-symlink}"

dry_log() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] $*"
  fi
}

safe_mkdir() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ ! -d "$1" ]]; then
      dry_log "mkdir -p $1"
    fi
    return
  fi
  mkdir -p "$1"
}

safe_cp() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "cp $1 -> $2"
    return
  fi
  cp "$@"
}

safe_cp_r() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "cp -R $1 -> $2"
    return
  fi
  cp -R "$@"
}

safe_ln() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "ln -sfn $1 -> $2"
    return
  fi
  ln -sfn "$1" "$2"
}

compute_relpath() {
  # Compute relative path from $2 to $1 without python3.
  # Uses pwd -P to resolve symlinks (matches os.path.realpath behavior).
  # Falls back to perl, then pure bash.
  local target base
  if [[ -d "$1" ]]; then
    target="$(cd "$1" && pwd -P)"
  elif [[ -d "$(dirname "$1")" ]]; then
    target="$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")"
  else
    target="$1"
  fi
  base="$(cd "$2" && pwd -P)"

  if command -v perl >/dev/null 2>&1; then
    perl -e 'use File::Spec; print File::Spec->abs2rel($ARGV[0], $ARGV[1])' "$target" "$base"
    return
  fi

  # Pure-bash fallback: component-safe prefix matching
  local common="$base/"
  local result=""
  while true; do
    case "$target/" in
      "$common"*) break ;;
    esac
    common="${common%/}"
    common="${common%/*}/"
    result="../$result"
  done
  printf '%s' "${result}${target#${common}}"
}

link_or_copy_skill() {
  local source_abs="$1"
  local link_target="$2"
  local destination="$3"

  safe_mkdir "$(dirname "$destination")"

  if [[ "$LINK_MODE" == "copy" ]]; then
    if [[ "$DRY_RUN" -eq 0 ]]; then
      rm -rf "$destination"
    fi
    safe_cp_r "$source_abs" "$destination"
    return
  fi

  safe_ln "$link_target" "$destination"
}

# Parse --langs argument into INSTALL_GO, INSTALL_NODE, INSTALL_PYTHON
parse_langs() {
  local input="$1"
  if [[ "$input" == "all" ]]; then
    INSTALL_GO=1; INSTALL_NODE=1; INSTALL_PYTHON=1
    return
  fi
  IFS=',' read -ra items <<< "$input"
  for item in "${items[@]}"; do
    case "$item" in
      go)     INSTALL_GO=1 ;;
      node)   INSTALL_NODE=1 ;;
      python) INSTALL_PYTHON=1 ;;
      *) echo "AVISO: linguagem '$item' ignorada (invalida)." ;;
    esac
  done
}

# Parse --tools argument into INSTALL_CLAUDE, INSTALL_GEMINI, INSTALL_CODEX, INSTALL_COPILOT
parse_tools() {
  local input="$1"
  if [[ "$input" == "all" ]]; then
    INSTALL_CLAUDE=1; INSTALL_GEMINI=1; INSTALL_CODEX=1; INSTALL_COPILOT=1
    return
  fi
  IFS=',' read -ra items <<< "$input"
  for item in "${items[@]}"; do
    case "$item" in
      claude)  INSTALL_CLAUDE=1 ;;
      gemini)  INSTALL_GEMINI=1 ;;
      codex)   INSTALL_CODEX=1 ;;
      copilot) INSTALL_COPILOT=1 ;;
      *) echo "AVISO: ferramenta '$item' ignorada (invalida)." ;;
    esac
  done
}

# Sync adaptadores de um diretorio fonte para um diretorio alvo (com diff-check)
sync_adapter_dir() {
  local source_dir="$1"
  local target_dir="$2"
  local pattern="${3:-*.md}"
  local updated=0

  [[ -d "$source_dir" ]] || return 0
  [[ -d "$target_dir" ]] || return 0

  for src_file in "$source_dir"/$pattern; do
    [[ -f "$src_file" ]] || continue
    local name target_file
    name="$(basename "$src_file")"
    target_file="$target_dir/$name"
    if [[ ! -f "$target_file" ]] || ! diff -q "$src_file" "$target_file" > /dev/null 2>&1; then
      cp "$src_file" "$target_file"
      updated=$((updated + 1))
    fi
  done

  echo "$updated"
}
