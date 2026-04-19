---
name: github-pr-comment-triage
version: 1.0.0
description: Organiza, prioriza e responde comentarios de revisao em Pull Requests do GitHub. Use quando um PR tiver multiplos comentarios de revisores e precisar de triagem estruturada. Nao use para implementar as correcoes solicitadas — use execute-task ou bugfix para isso.
---

# GitHub PR Comment Triage

## Procedimentos

**Etapa 1: Coletar comentarios**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Usar `gh pr view <numero> --comments` ou `gh api repos/<owner>/<repo>/pulls/<num>/comments` para listar comentarios.
2. Separar comentarios por: revisor, arquivo, linha e tipo (sugestao, bloqueante, duvida, elogio).

**Etapa 2: Classificar por prioridade**
1. Bloqueantes (`must fix`): alteram corretude, seguranca ou quebram contrato — resolver antes do merge.
2. Importantes (`should fix`): qualidade, testabilidade, boas praticas — resolver quando possivel.
3. Sugestoes (`nit`, `optional`): estilo, preferencia — responder e decidir.
4. Duvidas: responder com explicacao ou ajustar o codigo se a duvida revelar falta de clareza.

**Etapa 3: Gerar plano de resposta**
1. Para cada comentario bloqueante: propor acao concreta (arquivo + mudanca necessaria).
2. Para sugestoes: redigir resposta clara aceitando ou recusando com justificativa.
3. Agrupar mudancas por arquivo para eficiencia de implementacao.

**Etapa 4: Registrar resultado**
1. Listar comentarios triados com status: `resolved`, `pending`, `dismissed`.
2. Sugerir proximo passo: implementar via `execute-task` ou `bugfix`.

## Tratamento de Erros

* Se o PR nao estiver acessivel, verificar permissoes do token `gh` sem logar o token.
* Nao marcar como `dismissed` comentarios bloqueantes sem resposta ou implementacao.
* Se um comentario for ambiguo, perguntar ao revisor antes de assumir a intencao.
