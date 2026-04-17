# Governança de Regras

- Rule ID: R-GOV-001
- Severidade: hard
- Escopo: `.agents/skills/`, `.claude/rules/` e `.claude/skills/`.

## Objetivo
Definir precedência, resolução de conflitos e critérios de evidência para uso com agentes de IA.

## Fonte de Verdade
- Processos detalhados: `.agents/skills/`
- Regras cross-cutting: `.claude/rules/`
- Referências de governança: `.agents/skills/governanca-agentes/references/`
- Referências Go: `.agents/skills/implementacao-go/references/`

## Precedência
1. Esta governance (cross-cutting)
2. `.agents/skills/governanca-agentes/references/security.md`
3. References de arquitetura e implementação carregadas pela skill ativa
4. `.agents/skills/governanca-agentes/references/` (ddd, error-handling, tests)
5. Uber Go Style Guide PT-BR como baseline transversal (quando aplicável)

Se duas regras do mesmo nível conflitarem:
- prevalece `hard` sobre `guideline`
- se a severidade empatar, prevalece a regra mais restritiva para correção, segurança e determinismo
- convenção explícita local prevalece sobre o guia da Uber quando documentada nas references

## Política de Evidência
- Toda alteração deve ser justificável pelo PRD, por regra explícita ou por necessidade técnica demonstrável.
- Relatórios devem incluir arquivos alterados, validações executadas, riscos residuais e suposições assumidas.
- Não aprovar solução com lacuna crítica conhecida.

## Segurança Operacional
- Não executar ações de git destrutivas ou publicações remotas sem pedido explícito.
- Se faltar input obrigatório e não houver inferência segura, a execução deve pausar ou falhar de forma explícita.

## Proibido
- Aprovação sem evidência.
- Loops infinitos de remediação.
