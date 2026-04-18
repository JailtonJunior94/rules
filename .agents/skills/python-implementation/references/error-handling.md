# Tratamento de Erros Python

## Objetivo
Padronizar excecoes com hierarquia clara, separando erros de dominio de erros de infraestrutura.

## Diretrizes

### Modelagem
- Criar hierarquia de excecoes a partir de uma base do projeto (ex: `AppError(Exception)`).
- Separar excecoes de dominio (ex: `OrderAlreadyShipped`) de excecoes de infraestrutura (ex: `DatabaseConnectionError`).
- Usar `raise ... from err` para preservar cadeia de excecao (PEP 3134).
- Mensagens internas devem ser curtas, em lowercase e estaveis.

### Captura
- Capturar excecoes especificas — nunca `except Exception` generico sem re-raise.
- Usar context managers (`with`) para garantir cleanup de recursos (arquivos, conexoes, locks).
- Capturar na fronteira mais externa relevante (handler, command, entrypoint).
- Nao usar excecoes para controle de fluxo nao excepcional.

### Apresentacao
- A camada de transporte (view/handler) traduz excecao interna em resposta HTTP adequada.
- Nao expor traceback, mensagens internas ou detalhes de infraestrutura ao cliente.
- Retornar estrutura consistente: `{"error": {"code": "...", "message": "..."}}`.

### Validacao
- Falhar cedo com mensagem clara indicando campo e restricao violada.
- Preferir pydantic, attrs ou marshmallow sobre validacao manual.
- Validar na fronteira de entrada, nao dentro da logica de negocio.

### Logging de Erros
- Logar excecao com `logger.exception()` ou `logger.error(..., exc_info=True)` para preservar traceback.
- Nao logar e re-raise na mesma camada — logar uma vez na fronteira mais externa.

## Proibido
- `except: pass` ou `except Exception: pass` silencioso.
- Usar `assert` para validacao de input em producao (desativado com `-O`).
- Comparar excecao por mensagem string quando existir tipo tipado.
- Expor traceback em resposta HTTP de producao.
