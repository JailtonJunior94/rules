---
name: jira-tasks
version: 1.0.0
description: Cria, atualiza e consulta tickets Jira a partir de tasks.md ou de solicitacoes diretas. Use quando precisar sincronizar tarefas de implementacao com o Jira. Nao use para planejamento de produto — use create-prd e create-tasks primeiro.
---

# Jira Tasks

## Procedimentos

**Etapa 1: Identificar operacao**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Determinar se a operacao e: criar tickets, atualizar status, consultar, ou sincronizar tasks.md com Jira.
2. Verificar se as credenciais Jira estao disponíveis via variavel de ambiente (`JIRA_URL`, `JIRA_TOKEN`, `JIRA_PROJECT`).
3. Se credenciais ausentes, instruir configuracao sem expor tokens em logs.

**Etapa 2: Mapear tasks.md para tickets**
1. Para cada tarefa em tasks.md, derivar: titulo, descricao, tipo (Story/Task/Bug), prioridade.
2. Incluir IDs de requisito (RF-nn) na descricao para rastreabilidade.
3. Definir Epic Link quando aplicavel.
4. Nao duplicar tickets ja existentes — verificar por titulo ou ID antes de criar.

**Etapa 3: Executar operacoes via API**
1. Usar a API REST do Jira (`/rest/api/3/issue`) para criar/atualizar.
2. Registrar os IDs dos tickets criados para atualizacao de tasks.md.
3. Em atualizacoes de status, usar transicoes validas do workflow do projeto.

**Etapa 4: Sincronizar de volta**
1. Atualizar tasks.md com os IDs Jira correspondentes quando solicitado.
2. Relatar tickets criados, atualizados e eventuais erros.

## Tratamento de Erros

* Se a API retornar 401/403, instruir renovacao do token sem logar o token atual.
* Se um campo obrigatorio do Jira nao estiver mapeado, perguntar antes de usar valores padrao.
* Nao criar tickets em projetos fora do `JIRA_PROJECT` configurado sem confirmacao explícita.
