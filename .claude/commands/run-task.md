Você é um orquestrador de pipeline para executar tarefas aprovadas em 2 estágios sequenciais.

<critical>Este command NÃO implementa, valida ou aprova diretamente — ele orquestra estágios inline</critical>
<critical>Não marcar tarefa como done sem ambos os estágios completos</critical>
<critical>Ciclos de remediação por estágio seguem o limite padrão (ver 00-governance.md)</critical>

## Entradas
- `tasks/prd-[nome-da-feature]/tasks.md`
- Arquivo da tarefa alvo (`[num]_task.md`)
- `prd.md` e `techspec.md`

## Saída
- `tasks/prd-[nome-da-feature]/[num]_execution_report.md`

## Algoritmo de Seleção de Tarefa
1. Selecionar primeira tarefa com status `pending`.
2. Confirmar que todas as dependências estão `done`.
3. Se nenhuma tarefa elegível existir, relatar bloqueio explicitamente.
4. Estados permitidos: `pending`, `in_progress`, `needs_input`, `blocked`, `failed`, `done`.

## Estágios do Pipeline

### Estágio 1: Implementação
1. Ler contexto da tarefa: objetivo, critérios de aceite, arquivos alvo.
2. Ler `prd.md` e `techspec.md` para orientação técnica.
3. Seguir ordem de subtarefas definida no arquivo da tarefa.
4. Implementar testes junto com código de produção.
5. Executar `make test` após a conclusão de cada subtarefa.
6. Registrar comandos executados e arquivos alterados.
7. Se input obrigatório estiver ausente, parar pipeline com `needs_input`.
8. Se limite de remediação excedido (ver padrão de governança), parar pipeline com `failed`.

### Estágio 2: Validação e Aprovação
Ciclos de remediação para o estágio inteiro seguem o padrão de governança (test/lint + reviewer combinados).
1. Executar `make test` e `make lint` para o projeto completo.
2. Verificar ausência de regressões contra suite de testes existente.
3. Confirmar que todos os critérios de aceite da tarefa foram atendidos com evidência.
4. Registrar resultados de test/lint com status pass/fail.
5. Se validações falharem, tentar remediação (conta para o limite padrão de governança).
6. Se limite de remediação excedido, parar pipeline com `failed`.
7. Executar skill `reviewer` no diff produzido.
   - Antes de invocar, ler `prd.md` e `techspec.md` e incluir seus caminhos como contexto para o reviewer.
   - Veredito requerido: `APPROVED` ou `APPROVED_WITH_REMARKS`.
8. Se veredito for `REJECTED` ou `BLOCKED`, parar pipeline com `blocked`.

## Fechamento
1. Atualizar status da tarefa em `tasks.md` para `done` somente após ambos os estágios terem sucesso.
2. Gerar relatório de execução usando `.claude/templates/task-execution-report-template.md`.
3. Salvar como `tasks/prd-[nome-da-feature]/[num]_execution_report.md`.
4. Executar `.claude/scripts/validate-task-evidence.sh` no relatório.
5. Se script de validação falhar, estado final `blocked`.
6. Estado final `done` somente se validação passar.
