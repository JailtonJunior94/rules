# Testes

- Rule ID: R-TEST-001
- Severidade: hard para correção e determinismo, guideline para estilo
- Escopo: Todos os arquivos `*_test.go`.

## Objetivo
Garantir confiabilidade da CLI, do runtime de workflow e dos adapters de provider.

## Requisitos

### Cobertura Prioritária
- Validadores de workflow devem ter testes unitários.
- Runtime de execução deve cobrir fluxo feliz, pause/continue, retry, edit, redo e falha.
- Providers devem ter testes de adapter com doubles de subprocesso.
- Persistência de estado e artefatos deve ter testes de integração com filesystem temporário.

### Estratégia
- Testes unitários devem usar doubles simples e determinísticos.
- Testes de integração devem validar filesystem, subprocess wrappers e compatibilidade cross-platform sempre que possível.
- Casos com matriz de entrada devem usar table-driven tests.

### Determinismo
- Testes não devem depender de rede real nem de CLIs instalados no ambiente.
- Tempo, editor, terminal e subprocesso devem ser abstraídos para teste.
- Estado compartilhado entre casos é proibido.

### Gates
- `go test ./...` deve ser o gate mínimo.
- Se existirem suites separadas para integração, elas devem ser claramente documentadas e não implícitas.

## Proibido
- Teste unitário chamando Claude CLI ou Copilot CLI real.
- Testes frágeis baseados em `sleep`.
- Cobrir apenas o caminho feliz do runtime.
