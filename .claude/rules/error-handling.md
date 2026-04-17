# Tratamento de Erros

- Rule ID: R-ERR-001
- Severidade: hard
- Escopo: Todo código Go com criação, wrapping, propagação e apresentação de erros.

## Objetivo
Padronizar erros para uma CLI confiável, com mensagens claras ao usuário e detalhes técnicos preservados para diagnóstico.

## Requisitos

### Modelagem
- Erros de domínio devem ser sentinelas ou tipos bem definidos em seus módulos.
- Erros de infraestrutura podem ser wrapped com contexto adicional.
- Mensagens internas devem ser curtas, em lowercase e estáveis.

### Wrapping
- Usar `fmt.Errorf(... %w ...)`.
- Preservar cadeia para `errors.Is` e `errors.As`.
- Adapters devem adicionar contexto técnico útil: provider, comando, step, workflow, path.

### Apresentação na CLI
- A camada de terminal deve traduzir erro técnico em mensagem acionável.
- Mensagens ao usuário devem dizer o que falhou, onde falhou e qual ação é possível.
- Erros de provider devem informar binário esperado, timeout, exit code ou step afetado quando relevante.

### Retry e Remediação
- Retry automático deve ser restrito a casos previstos, como JSON inválido corrigível ou falha transitória de provider.
- O número máximo padrão de retries automáticos por step deve ser 2.
- Se remediação automática falhar, o runtime deve pausar para HITL ou encerrar de forma explícita.

### Comparação
- Usar `errors.Is` e `errors.As`.
- Não comparar erro com `==`, exceto `nil`.

## Proibido
- `panic` para erro recuperável.
- Engolir erro de IO, subprocesso, persistência ou validação.
- Exibir stack trace bruto por padrão ao usuário final.
- Mensagens vagas como `something went wrong`.
