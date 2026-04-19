---
name: github-release-publication-flow
version: 1.0.0
description: Publica uma release no GitHub com tag, notas de release e assets. Use apos gerar o changelog com github-diff-changelog-publisher e ter o codigo pronto para release. Nao use para gerar changelog ou criar PRs — use as skills dedicadas para isso.
---

# GitHub Release Publication Flow

## Procedimentos

**Etapa 1: Verificar pre-requisitos**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Confirmar que CHANGELOG.md tem entrada para a versao a ser publicada.
2. Verificar que o branch alvo esta atualizado e CI passou.
3. Identificar o numero de versao (SemVer: `vX.Y.Z`).

**Etapa 2: Criar tag Git**
1. Confirmar com o usuario o numero de versao e o commit base.
2. Executar `git tag -a vX.Y.Z -m "Release vX.Y.Z"` no commit correto.
3. Executar `git push origin vX.Y.Z` para publicar a tag.

**Etapa 3: Criar release no GitHub**
1. Extrair notas de release do CHANGELOG.md para a versao.
2. Executar `gh release create vX.Y.Z --title "vX.Y.Z" --notes "<notas>"`.
3. Adicionar flag `--prerelease` quando aplicavel.
4. Fazer upload de assets (binarios, arquivos) com `--attach` quando necessario.

**Etapa 4: Confirmar publicacao**
1. Retornar URL da release publicada.
2. Verificar que a tag aparece na lista de releases do repositorio.

## Tratamento de Erros

* Nao fazer `git push --force` em tags ja publicadas — criar tag corretiva com sufixo.
* Se CI falhar no commit de release, nao publicar ate que CI passe.
* Se a versao ja existir como release, reportar conflito e pedir confirmacao antes de sobrescrever.
