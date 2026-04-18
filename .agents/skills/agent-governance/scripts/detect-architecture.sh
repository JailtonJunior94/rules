#!/usr/bin/env bash
# Detecta tipo de arquitetura e padrao arquitetural de um projeto.
# Uso direto: bash detect-architecture.sh [PROJECT_DIR]
# Uso como modulo: source detect-architecture.sh (requer file_exists e has_any_files definidos)
# Saida (direto): JSON com architecture_type e architectural_pattern.

# Quando sourced, apenas define as funcoes de deteccao.
# Espera que o caller tenha definido: file_exists(), has_any_files(), PROJECT_DIR.
# Quando executado diretamente, define helpers locais.

detect_architecture_type() {
  # Monorepo: sinais fortes de multiplos projetos independentes
  if file_exists "go.work" || file_exists "pnpm-workspace.yaml" || file_exists "nx.json" || file_exists "turbo.json" || file_exists "lerna.json"; then
    printf 'monorepo'
    return
  fi
  if has_any_files "services" && has_any_files "packages"; then
    printf 'monorepo'
    return
  fi
  if has_any_files "apps" && has_any_files "packages"; then
    printf 'monorepo'
    return
  fi

  # Monolito modular: subdivisao interna por dominio/modulo com mais de um subdiretorio
  if has_any_files "modules" || has_any_files "domains"; then
    printf 'monolito modular'
    return
  fi
  if [[ -d "$PROJECT_DIR/internal" ]]; then
    local internal_subdirs
    internal_subdirs="$(find "$PROJECT_DIR/internal" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$internal_subdirs" -ge 3 ]]; then
      printf 'monolito modular'
      return
    fi
  fi

  # Microservico: Dockerfile + sinais de deploy isolado
  if file_exists "Dockerfile"; then
    if has_any_files "deployments" || has_any_files "k8s" || has_any_files "helm" || file_exists "skaffold.yaml" || file_exists "kustomization.yaml"; then
      printf 'microservico'
      return
    fi
  fi

  # Fallback: monolito
  echo "AVISO: arquitetura nao detectada com alta confianca, assumindo monolito." >&2
  printf 'monolito'
}

detect_architectural_pattern() {
  if has_any_files "domain" || has_any_files "application" || has_any_files "infrastructure" || has_any_files "ports" || has_any_files "adapters"; then
    printf 'Predominio de Clean Architecture / Hexagonal com fronteiras explicitas entre dominio, aplicacao e infraestrutura.'
    return
  fi

  if has_any_files "controllers" || has_any_files "services" || has_any_files "repositories" || has_any_files "models"; then
    printf 'Predominio de arquitetura em camadas, com separacao entre transporte, servicos, persistencia e modelos.'
    return
  fi

  if has_any_files "features" || has_any_files "feature"; then
    printf 'Predominio de organizacao por funcionalidade / fatiamento vertical, agrupando fluxo e dependencias por capacidade de negocio.'
    return
  fi

  if has_any_files "internal"; then
    printf 'Predominio de packages internos coesos, com estrutura orientada por dominio ou componente.'
    return
  fi

  printf 'Padrao arquitetural nao inferido com alta confianca; assumir composicao simples e dependencias explicitas.'
}

# Quando executado diretamente, definir helpers e emitir JSON
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail

  PROJECT_DIR="${1:-.}"
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

  file_exists() {
    [[ -e "$PROJECT_DIR/$1" ]]
  }

  has_any_files() {
    local dir="$1"
    [[ -d "$PROJECT_DIR/$dir" ]] || return 1
    find "$PROJECT_DIR/$dir" -mindepth 1 -maxdepth 1 | read -r _
  }

  ARCH_TYPE="$(detect_architecture_type)"
  ARCH_PATTERN="$(detect_architectural_pattern)"

  ARCH_PATTERN_ESCAPED="$(printf '%s' "$ARCH_PATTERN" | sed 's/"/\\"/g')"

  printf '{"architecture_type":"%s","architectural_pattern":"%s"}\n' "$ARCH_TYPE" "$ARCH_PATTERN_ESCAPED"
fi
