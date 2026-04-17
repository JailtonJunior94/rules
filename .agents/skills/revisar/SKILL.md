---
name: revisar
description: Revisa um diff de código quanto a correção, segurança, regressões e testes faltantes usando regras específicas do repositório. Use quando uma branch ou diff local precisar de revisão no estilo dono do código antes de merge ou fechamento de tarefa. Não use para implementação, planejamento de produto ou limpeza apenas de estilo.
---

# Revisar

## Procedimentos

**Etapa 1: Carregar o contexto de revisão**
1. Read the diff or changed files first.
2. Read `prd.md`, `techspec.md`, task files, or issue context when they are available and relevant to the change.
3. Read `.agents/skills/governanca-agentes/SKILL.md` and load references on demand when they materially affect the review:
   - `.agents/skills/governanca-agentes/references/ddd.md`
   - `.agents/skills/governanca-agentes/references/error-handling.md`
   - `.agents/skills/governanca-agentes/references/security.md`
   - `.agents/skills/governanca-agentes/references/tests.md`

**Etapa 2: Revisar como dono do código**
1. Prioritize correctness, security, behavior regressions, missing tests, and evidence gaps.
2. Verify the change against intended behavior, not just local code style.
3. Check whether validations are sufficient for the risk level.
4. Treat style-only remarks as secondary unless they hide a real defect.

**Etapa 3: Produzir achados primeiro**
1. Lead with concrete findings ordered by severity.
2. Include file references and a short explanation of impact.
3. If no findings exist, say so explicitly and note any residual risks or testing gaps.

**Etapa 4: Retornar um veredito canônico**
1. Usar apenas um destes vereditos:
   - `APPROVED`
   - `APPROVED_WITH_REMARKS`
   - `REJECTED`
   - `BLOCKED`
2. Usar `BLOCKED` quando faltar contexto necessário ou evidência de validação.
3. Usar `REJECTED` quando o código tiver defeitos materiais ou regressões.

## Tratamento de Erros

* Se nenhum diff ou conjunto de arquivos alterados estiver disponível, retornar `BLOCKED` e solicitar o alvo de revisão faltante.
* Se a revisão depender de comportamento externo ou documentação que possa ter mudado, verificar em fontes primárias antes de apontar um defeito.
* Se o repositório tiver alterações sujas não relacionadas, restringir a revisão ao diff pretendido e explicitar a incerteza quando esse isolamento não for possível.
