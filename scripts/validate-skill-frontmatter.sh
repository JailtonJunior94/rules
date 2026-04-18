#!/usr/bin/env bash
# Valida frontmatter YAML de todos os SKILL.md.
# Campos obrigatorios: name, version, description.
# Uso: bash scripts/validate-skill-frontmatter.sh [diretorio-skills]

set -euo pipefail

SKILLS_DIR="${1:-.agents/skills}"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "ERRO: diretorio de skills nao encontrado: $SKILLS_DIR"
  exit 1
fi

errors=0
checked=0

for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -f "$skill_file" ]] || continue
  skill_name="$(basename "$(dirname "$skill_file")")"
  checked=$((checked + 1))

  # Extract frontmatter block (between first and second ---)
  frontmatter="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$skill_file")"

  if [[ -z "$frontmatter" ]]; then
    echo "ERRO: $skill_name — frontmatter ausente"
    errors=$((errors + 1))
    continue
  fi

  # Check required fields
  for field in name version description; do
    value="$(echo "$frontmatter" | awk -v f="$field" '$0 ~ "^"f":" {sub(/^[^:]+:[[:space:]]*/, ""); print; exit}')"
    if [[ -z "$value" ]]; then
      echo "ERRO: $skill_name — campo obrigatorio ausente: $field"
      errors=$((errors + 1))
    fi
  done

  # Validate version format (semver: MAJOR.MINOR.PATCH)
  version="$(echo "$frontmatter" | awk '/^version:/{print $2; exit}')"
  if [[ -n "$version" ]] && ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
    echo "ERRO: $skill_name — version nao segue semver: $version"
    errors=$((errors + 1))
  fi

  # Validate name matches directory name
  name="$(echo "$frontmatter" | awk '/^name:/{print $2; exit}')"
  if [[ -n "$name" && "$name" != "$skill_name" ]]; then
    echo "ERRO: $skill_name — name no frontmatter ($name) difere do diretorio ($skill_name)"
    errors=$((errors + 1))
  fi
done

if [[ "$checked" -eq 0 ]]; then
  echo "ERRO: nenhuma skill encontrada em $SKILLS_DIR"
  exit 1
fi

if [[ "$errors" -gt 0 ]]; then
  echo ""
  echo "Validacao falhou: $errors erro(s) em $checked skill(s)"
  exit 1
fi

echo "Validacao aprovada: $checked skill(s) com frontmatter valido"
