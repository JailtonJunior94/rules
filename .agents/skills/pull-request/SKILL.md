---
name: pull-request
version: 1.0.0
description: Cria e gerencia pull requests no GitHub com titulo, descricao estruturada e checklist de teste. Use quando precisar abrir, atualizar ou revisar um PR com base em diff ou branch. Nao use para revisao de codigo — use a skill review para isso.
---

# Pull Request

## Procedimentos

**Etapa 1: Coletar contexto do PR**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Identificar branch de origem e branch alvo (default: `main`).
2. Executar `git log <base>..<head> --oneline` para listar commits incluidos.
3. Executar `git diff <base>...<head> --stat` para resumo de arquivos alterados.
4. Ler `prd.md` e `techspec.md` quando disponíveis para contexto de produto.

**Etapa 2: Compor titulo e descricao**
1. Titulo: conciso, ≤70 caracteres, em ingles ou portugues conforme padrao do repositorio.
2. Descricao: seguir template com secoes `## Summary`, `## Changes`, `## Test plan`.
3. Incluir referencias a issues/tarefas quando aplicavel (`Closes #123`, `Refs RF-01`).
4. Nao incluir informacoes sensiveis (segredos, tokens, dados de producao).

**Etapa 3: Criar o PR**
1. Usar `gh pr create` com `--title`, `--body` e `--base` explícitos.
2. Adicionar labels e revisores quando fornecidos.
3. Verificar se CI passou antes de solicitar revisao formal.

**Etapa 4: Pos-criacao**
1. Confirmar URL do PR criado.
2. Registrar numero do PR para rastreabilidade.

## Tratamento de Erros

* Se branch nao existir no remoto, executar `git push -u origin <branch>` antes de criar o PR.
* Se `gh` nao estiver autenticado, instruir `gh auth login` sem executar.
* Se houver conflitos de merge, listar os arquivos conflitantes e orientar resolucao sem forcar.
