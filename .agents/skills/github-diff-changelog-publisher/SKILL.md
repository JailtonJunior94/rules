---
name: github-diff-changelog-publisher
version: 1.0.0
description: Gera e publica CHANGELOG.md a partir de git log entre dois refs (tags, branches, commits). Use quando precisar de notas de release estruturadas antes de publicar uma release no GitHub. Nao use para publicar a release em si — use github-release-publication-flow para isso.
---

# GitHub Diff Changelog Publisher

## Procedimentos

**Etapa 1: Identificar o intervalo de diff**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Determinar o ref de inicio (tag anterior ou commit base) e o ref de fim (HEAD ou nova tag).
2. Executar `git log <base>..<head> --oneline --no-merges` para listar commits.
3. Filtrar commits por prefixo Conventional Commits (`feat`, `fix`, `perf`, `breaking`).

**Etapa 2: Categorizar e formatar**
1. Agrupar commits por categoria: `### Added` (feat), `### Fixed` (fix), `### Changed` (perf, refactor), `### Breaking Changes`.
2. Remover commits de chore, ci, docs de baixo impacto que nao afetam usuarios.
3. Incluir referencias a PRs e issues quando disponíveis (`(#123)`).
4. Formatar em Markdown seguindo Keep a Changelog.

**Etapa 3: Atualizar CHANGELOG.md**
1. Inserir a nova versao no topo do arquivo, mantendo versoes anteriores.
2. Formato de header: `## [x.y.z] - YYYY-MM-DD`.
3. Confirmar com o usuario antes de sobrescrever.

**Etapa 4: Registrar resultado**
1. Mostrar o bloco de changelog gerado.
2. Sugerir proximo passo: criar tag Git ou usar `github-release-publication-flow`.

## Tratamento de Erros

* Se nao houver commits no intervalo, reportar e encerrar sem modificar CHANGELOG.md.
* Se o historico de commits nao seguir Conventional Commits, categorizar como `### Changed` e alertar.
* Nao inferir numeros de versao automaticamente sem confirmacao do usuario.
