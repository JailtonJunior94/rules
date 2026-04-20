#!/usr/bin/env bash
# Patterns de heading para validators de evidencia — defaults em PT-BR.
# Suporta override via GOVERNANCE_LANG=<lang> (ex: GOVERNANCE_LANG=en).
# Carrega automaticamente i18n/<lang>/validator-patterns.sh se existir.

PATTERN_CONTEXTO_CARREGADO="${PATTERN_CONTEXTO_CARREGADO:-contexto carregado}"
PATTERN_COMANDOS_EXECUTADOS="${PATTERN_COMANDOS_EXECUTADOS:-comandos executados}"
PATTERN_ARQUIVOS_ALTERADOS="${PATTERN_ARQUIVOS_ALTERADOS:-arquivos alterados}"
PATTERN_RESULTADOS_VALIDACAO="${PATTERN_RESULTADOS_VALIDACAO:-resultados de validac}"
PATTERN_SUPOSICOES="${PATTERN_SUPOSICOES:-suposic}"
PATTERN_RISCOS_RESIDUAIS="${PATTERN_RISCOS_RESIDUAIS:-riscos residuais}"
PATTERN_BUGS="${PATTERN_BUGS:-bugs}"
PATTERN_ESCOPO="${PATTERN_ESCOPO:-escopo}"
PATTERN_INVARIANTES="${PATTERN_INVARIANTES:-invariantes}"
PATTERN_MUDANCAS="${PATTERN_MUDANCAS:-mudanc}"

if [[ -n "${GOVERNANCE_LANG:-}" ]]; then
  _vp_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  _vp_i18n="${_vp_self_dir}/../../i18n/${GOVERNANCE_LANG}/validator-patterns.sh"
  if [[ -f "$_vp_i18n" ]]; then
    # shellcheck source=/dev/null
    source "$_vp_i18n"
  fi
  unset _vp_self_dir _vp_i18n
fi
